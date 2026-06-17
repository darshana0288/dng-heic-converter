# DNG/HEIC to JPEG Converter

A local, fully-automated batch converter for converting iPhone ProRAW (DNG) and HEIC photos to high-quality JPEGs suitable for stock photo uploads.

## Features

- ✅ **DNG Support**: Extracts embedded previews from iPhone ProRAW files
- ✅ **HEIC Support**: Converts HEIC/HEIF images to JPEG
- ✅ **Quality Control**: Adjustable JPEG quality slider (70-100, default 92)
- ✅ **Resize Option**: Optional max-dimension resize with aspect ratio preservation
- ✅ **Color Management**: Automatic conversion to sRGB
- ✅ **Metadata Handling**: Preserves EXIF, strips GPS data for privacy
- ✅ **Batch Processing**: Multi-file upload with progress tracking
- ✅ **Local Processing**: No cloud, no accounts - all files stay on your machine
- ✅ **ZIP Download**: Download all converted files as a ZIP archive
- ✅ **Before/After Thumbnails**: Preview converted images

## Quick Start

### Installation (Automated)

1. **Extract the ZIP** to any folder on your computer
2. **Double-click `INSTALL-AUTO.bat`**
3. Wait for installation to complete (installs Node.js, ImageMagick, exiftool automatically)
4. **Close and reopen Command Prompt**
5. Done! Everything is installed

### Starting the Converter

**Option 1 (Easiest):**
- Double-click `START.bat` in the folder

**Option 2 (Manual):**
```cmd
cd path\to\dng-heic-converter
npm start
```

Then open your browser to: **http://localhost:3000**

## System Requirements

- Windows 10 or later
- That's it! Everything else installs automatically

## How It Works

### Installation Process

The automated installer (`INSTALL-AUTO.bat`) does the following:

1. **Downloads and sets up Node.js v26.3.0** (portable version)
   - Extracts to `C:\nodejs`
   - No system restart needed

2. **Installs npm dependencies**
   - Required Node.js packages for the app

3. **Downloads and installs ImageMagick**
   - Used for HEIC to JPEG conversion
   - Installs to `C:\ImageMagick`

4. **Downloads and extracts exiftool**
   - Used for DNG metadata extraction
   - Extracts to `C:\exiftool`

5. **Updates system PATH**
   - Makes all tools accessible from anywhere

6. **Tests all installations**
   - Verifies everything works before starting

### Conversion Pipeline

#### DNG (iPhone ProRAW)
1. **Extract Embedded Preview**: iPhone embeds a full-resolution JPEG preview in DNG files
2. **Process with Sharp**: Resize (if requested), convert to sRGB, encode as JPEG
3. **Output**: High-quality JPEG with preserved metadata

#### HEIC (iPhone Photos)
1. **Decode with ImageMagick**: Convert HEIC to intermediate format
2. **Process with Sharp**: Resize (if requested), convert to sRGB, encode as JPEG
3. **Output**: High-quality JPEG with metadata

## Usage Guide

### Upload Files

1. **Drag & Drop**: Drag DNG or HEIC files onto the upload area
2. **Or Click to Select**: Click the upload area to browse files
3. **Or Use Folder Upload**: Select entire folders for batch processing

### Adjust Settings

- **JPEG Quality** (70-100): Higher = better quality, larger file size
  - Default: 92 (excellent quality)
- **Max Dimension**: Resize if width or height exceeds this value
  - Leave empty to keep original size
- **Copyright/Contributor Name**: Optional text to add to image metadata

### Convert

1. Click **"Convert All"** button
2. Watch the progress bars
3. Review the results with thumbnails

### Download

- **Individual Files**: Click "Download" on any result card
- **Batch ZIP**: Click "Download All as ZIP" to get everything at once

## File Structure

```
dng-heic-converter/
├── server.js                 # Express backend server
├── package.json             # Node.js dependencies
├── INSTALL-AUTO.bat         # Automated installer (run this!)
├── START.bat                # Quick start shortcut
├── README.md                # This file
├── SETUP_GUIDE.txt          # Detailed setup instructions
│
├── public/                  # Web interface
│   ├── index.html
│   ├── style.css
│   └── app.js
│
├── lib/                     # Core conversion logic
│   └── convert.js
│
└── output/                  # Converted files (auto-created)
```

## Stock Photo Site Requirements

Typical minimum requirements:
- **Shutterstock**: 4 MP (2048×2048 or similar)
- **Adobe Stock**: 4 MP minimum
- **iStock/Getty**: 4 MP minimum
- **Alamy**: 4 MP minimum

**Always verify current requirements** on your target platform.

## Troubleshooting

### "Port 3000 is already in use"
Another program is using port 3000. Either:
- Close the other program
- Or change the port in `server.js` (line with `PORT = 3000`)

### Files aren't converting
Check browser console (F12) for error messages. Common issues:
- DNG file has no embedded preview (rare)
- HEIC file is corrupted
- Insufficient disk space

### Quality seems low
- Increase quality slider (try 95-100)
- Make sure original image resolution is high enough
- Don't resize too aggressively

### ImageMagick or exiftool not working
- Close PowerShell completely
- Run `INSTALL-AUTO.bat` again
- If still fails, restart your computer

## Advanced Configuration

### Change Default Quality

Edit `public/index.html`, find line with `value="92"` and change the number.

### Change Output Folder

Edit `server.js`, change:
```javascript
const outputDir = path.join(__dirname, 'output');
```

### Change Server Port

Edit `server.js`, change:
```javascript
const PORT = process.env.PORT || 3000;
```

## What Gets Downloaded During Installation

The installer automatically downloads:

1. **Node.js v26.3.0** (~150 MB)
   - Runtime for the app
   - From: nodejs.org official distribution

2. **ImageMagick 7.1.2-25** (~50 MB)
   - Image processing for HEIC conversion
   - From: Custom S3 bucket (trusted source)

3. **exiftool** (~5 MB)
   - Metadata extraction for DNG files
   - From: Custom S3 bucket (trusted source)

Total download size: ~200 MB (one-time)

## Uninstalling

1. Delete the `dng-heic-converter` folder
2. (Optional) Delete the tools if you don't need them:
   - `C:\nodejs` (Node.js)
   - `C:\ImageMagick` (ImageMagick)
   - `C:\exiftool` (exiftool)

## License

MIT

## Support

If you encounter issues:
1. Read the troubleshooting section above
2. Check the browser console (F12) for error messages
3. Review the command prompt output when starting the app
4. Ensure all files are valid DNG/HEIC formats

---

**Happy converting!** 🎉
