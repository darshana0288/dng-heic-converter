const sharp = require('sharp');
const path = require('path');
const fs = require('fs');
const { promisify } = require('util');

const execFile = require('child_process').execFile;
const execFilePromise = promisify(execFile);

async function extractEmbeddedPreview(dngBuffer) {
  try {
    const tempFile = path.join(__dirname, `temp_${Date.now()}.dng`);
    fs.writeFileSync(tempFile, dngBuffer);

    // Try to get preview offset and length from EXIF
    try {
      const { stdout } = await execFilePromise('exiftool', [
        '-PreviewImageStart',
        '-PreviewImageLength',
        tempFile
      ]);

      const output = stdout.toString();
      console.log('Exiftool preview tags output:', output.substring(0, 200));

      const lines = output.split('\n');
      let previewStart = null;
      let previewLength = null;

      for (const line of lines) {
        const match = line.match(/Preview Image (Start|Length)\s*:\s*(\d+)/i);
        if (match) {
          if (match[1].toLowerCase() === 'start') {
            previewStart = parseInt(match[2]);
          } else if (match[1].toLowerCase() === 'length') {
            previewLength = parseInt(match[2]);
          }
        }
      }

      console.log(`Extracted: previewStart=${previewStart}, previewLength=${previewLength}`);

      if (previewStart !== null && previewLength !== null && previewLength > 1000) {
        console.log(`Found preview at offset ${previewStart}, length ${previewLength}`);
        const previewBuffer = dngBuffer.slice(previewStart, previewStart + previewLength);

        try {
          await sharp(previewBuffer).metadata();
          console.log('✓ Preview image is valid');
          fs.unlinkSync(tempFile);
          return { buffer: previewBuffer, tag: 'PreviewImage' };
        } catch (err) {
          console.log('✗ Preview data at offset is not valid image:', err.message);
        }
      } else {
        console.log('Preview offsets not found or invalid size');
      }
    } catch (err) {
      console.log('Error extracting preview offset:', err.message);
    }

    // Fallback: try standard EXIF tags
    console.log('Trying alternative EXIF tags...');
    const tags = ['PreviewImage', 'JpgFromRaw', 'ThumbnailImage', 'OtherImage'];

    for (const tag of tags) {
      try {
        const { stdout } = await execFilePromise('exiftool', [
          '-b',
          `-${tag}`,
          tempFile
        ]);

        if (stdout && stdout.length > 1000) {
          console.log(`Found data in tag: ${tag} (${stdout.length} bytes)`);

          const buffer = Buffer.from(stdout);
          try {
            const meta = await sharp(buffer).metadata();
            console.log(`✓ ${tag} is valid image (${meta.width}x${meta.height})`);
            fs.unlinkSync(tempFile);
            return { buffer, tag };
          } catch (sharpErr) {
            console.log(`✗ ${tag} is not valid image format`);
          }
        } else {
          console.log(`Tag ${tag} not found or too small`);
        }
      } catch (err) {
        console.log(`Error trying tag ${tag}: ${err.message}`);
      }
    }

    // Show available tags for debugging
    try {
      const { stdout } = await execFilePromise('exiftool', [tempFile]);
      console.log('\n=== EXIF TAGS IN DNG FILE ===');
      console.log(stdout.substring(0, 1500));
      console.log('=== END EXIF TAGS ===\n');
    } catch (err) {
      // ignore
    }

    fs.unlinkSync(tempFile);
    return null;
  } catch (error) {
    console.error('Error extracting embedded preview:', error);
    return null;
  }
}

async function tryRawConversion(dngPath) {
  // Try dcraw first
  try {
    const { stdout } = await execFilePromise('dcraw', [
      '-c',
      '-w',
      '-q', '3',
      dngPath
    ]);
    return { buffer: Buffer.from(stdout), method: 'dcraw' };
  } catch (err) {
    // dcraw not available, try darktable-cli
  }

  // Try darktable-cli
  try {
    const outputFile = dngPath.replace(/\.dng$/i, '_dt.jpg');
    await execFilePromise('darktable-cli', [
      dngPath,
      outputFile,
      '--core',
      '--lighttable'
    ]);
    const buffer = fs.readFileSync(outputFile);
    try {
      fs.unlinkSync(outputFile);
    } catch (e) {
      // ignore
    }
    return { buffer, method: 'darktable' };
  } catch (err) {
    return null;
  }
}

async function convertDNG(buffer, options) {
  const { quality, maxDimension, copyright, outputPath } = options;

  let imageBuffer;
  let decodeMethod = 'embedded_preview';
  let previewTag = null;

  const previewResult = await extractEmbeddedPreview(buffer);

  if (previewResult && previewResult.buffer && previewResult.buffer.length > 0) {
    imageBuffer = previewResult.buffer;
    previewTag = previewResult.tag;
  } else {
    const tempFile = path.join(__dirname, `temp_${Date.now()}.dng`);
    fs.writeFileSync(tempFile, buffer);

    const rawResult = await tryRawConversion(tempFile);

    try {
      fs.unlinkSync(tempFile);
    } catch (e) {
      // ignore
    }

    if (rawResult) {
      imageBuffer = rawResult.buffer;
      decodeMethod = `${rawResult.method}_conversion`;
    } else {
      throw new Error(
        'DNG file has no usable embedded preview and no RAW decoder is installed. Install darktable from https://www.darktable.org/ to process this DNG file.'
      );
    }
  }

  let pipeline = sharp(imageBuffer);
  const metadata = await pipeline.metadata();

  if (maxDimension) {
    pipeline = pipeline.resize(maxDimension, maxDimension, {
      fit: 'inside',
      withoutEnlargement: true
    });
  }

  pipeline = pipeline.toColorspace('srgb').jpeg({ quality, progressive: true });

  await pipeline.toFile(outputPath);

  return {
    decodeMethod,
    previewTag,
    originalResolution: `${metadata.width}x${metadata.height}`,
    quality,
    colorProfile: 'sRGB'
  };
}

async function convertHEIC(buffer, options) {
  const { quality, maxDimension, copyright, outputPath } = options;

  const tempHeic = path.join(__dirname, `temp_${Date.now()}.heic`);
  const tempJpeg = path.join(__dirname, `temp_${Date.now()}.jpg`);

  try {
    fs.writeFileSync(tempHeic, buffer);

    let decoderUsed = null;

    // Try ImageMagick first (most reliable)
    try {
      await execFilePromise('magick', [
        tempHeic,
        tempJpeg
      ]);
      decoderUsed = 'imagemagick';
      console.log('✓ HEIC converted with ImageMagick');
    } catch (err) {
      console.log('ImageMagick not available, trying ffmpeg...');

      // Fallback to ffmpeg
      try {
        await execFilePromise('ffmpeg', [
          '-i', tempHeic,
          '-q:v', '2',
          tempJpeg
        ]);
        decoderUsed = 'ffmpeg';
        console.log('✓ HEIC converted with ffmpeg');
      } catch (ffErr) {
        throw new Error(
          'HEIC conversion requires ImageMagick or ffmpeg. Install ImageMagick from https://imagemagick.org/ (recommended) or ffmpeg from https://ffmpeg.org/'
        );
      }
    }

    const jpegBuffer = fs.readFileSync(tempJpeg);
    let pipeline = sharp(jpegBuffer);
    const metadata = await pipeline.metadata();

    if (maxDimension) {
      pipeline = pipeline.resize(maxDimension, maxDimension, {
        fit: 'inside',
        withoutEnlargement: true
      });
    }

    pipeline = pipeline.toColorspace('srgb').jpeg({ quality, progressive: true });
    await pipeline.toFile(outputPath);

    return {
      decodeMethod: decoderUsed,
      originalResolution: `${metadata.width}x${metadata.height}`,
      quality,
      colorProfile: 'sRGB'
    };
  } finally {
    try { fs.unlinkSync(tempHeic); } catch (e) {}
    try { fs.unlinkSync(tempJpeg); } catch (e) {}
  }
}

module.exports = {
  convertDNG,
  convertHEIC
};
