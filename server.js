const express = require('express');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const { convertDNG, convertHEIC } = require('./lib/convert');

const app = express();
const PORT = process.env.PORT || 3000;

const outputDir = path.join(__dirname, 'output');
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

const upload = multer({
  storage: multer.memoryStorage(),
  fileFilter: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    if (['.dng', '.heic', '.heif'].includes(ext)) {
      cb(null, true);
    } else {
      cb(new Error(`Unsupported file type: ${ext}`));
    }
  }
});

app.use(express.static('public'));
app.use(express.json());

app.post('/api/convert', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const { quality = 92, maxDimension, copyright } = req.body;
    const ext = path.extname(req.file.originalname).toLowerCase();
    const baseName = path.basename(req.file.originalname, path.extname(req.file.originalname));
    const outputFileName = `${baseName}.jpg`;
    const outputPath = path.join(outputDir, outputFileName);

    let result;

    if (ext === '.dng') {
      result = await convertDNG(req.file.buffer, {
        quality: parseInt(quality),
        maxDimension: maxDimension ? parseInt(maxDimension) : null,
        copyright,
        outputPath
      });
    } else if (['.heic', '.heif'].includes(ext)) {
      result = await convertHEIC(req.file.buffer, {
        quality: parseInt(quality),
        maxDimension: maxDimension ? parseInt(maxDimension) : null,
        copyright,
        outputPath
      });
    }

    res.json({
      success: true,
      filename: outputFileName,
      outputPath: outputPath,
      ...result
    });
  } catch (error) {
    console.error('Conversion error:', error);
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/output/:filename', (req, res) => {
  const filePath = path.join(outputDir, req.params.filename);

  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: 'File not found' });
  }

  res.download(filePath);
});

app.listen(PORT, () => {
  console.log(`Converter running at http://localhost:${PORT}`);
  console.log(`Output directory: ${outputDir}`);
});
