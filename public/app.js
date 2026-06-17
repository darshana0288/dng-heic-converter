class Converter {
  constructor() {
    this.files = [];
    this.results = [];
    this.init();
  }

  init() {
    this.setupDragDrop();
    this.setupEventListeners();
  }

  setupDragDrop() {
    const dragDropArea = document.getElementById('dragDropArea');
    const fileInput = document.getElementById('fileInput');

    dragDropArea.addEventListener('click', () => fileInput.click());

    dragDropArea.addEventListener('dragover', (e) => {
      e.preventDefault();
      dragDropArea.classList.add('dragover');
    });

    dragDropArea.addEventListener('dragleave', () => {
      dragDropArea.classList.remove('dragover');
    });

    dragDropArea.addEventListener('drop', (e) => {
      e.preventDefault();
      dragDropArea.classList.remove('dragover');
      this.handleFiles(e.dataTransfer.files);
    });

    fileInput.addEventListener('change', (e) => {
      this.handleFiles(e.target.files);
    });
  }

  setupEventListeners() {
    document.getElementById('qualitySlider').addEventListener('input', (e) => {
      document.getElementById('qualityValue').textContent = e.target.value;
    });

    document.getElementById('convertButton').addEventListener('click', () => {
      this.convertAll();
    });

    document.getElementById('clearButton').addEventListener('click', () => {
      this.clearFiles();
    });

    document.getElementById('downloadZipButton').addEventListener('click', () => {
      this.downloadAsZip();
    });
  }

  handleFiles(fileList) {
    const supportedTypes = ['.dng', '.heic', '.heif'];
    const newFiles = Array.from(fileList).filter((file) => {
      const ext = '.' + file.name.split('.').pop().toLowerCase();
      if (!supportedTypes.includes(ext)) {
        alert(`Unsupported file: ${file.name}`);
        return false;
      }
      return true;
    });

    this.files = [...this.files, ...newFiles];
    this.renderFileList();
  }

  renderFileList() {
    const fileList = document.getElementById('fileList');
    const filesSection = document.getElementById('filesSection');

    if (this.files.length === 0) {
      filesSection.style.display = 'none';
      return;
    }

    filesSection.style.display = 'block';
    fileList.innerHTML = this.files
      .map(
        (file, index) => `
        <div class="file-item">
          <div class="file-item-info">
            <div class="file-item-name">${file.name}</div>
            <div class="file-item-size">${this.formatFileSize(file.size)}</div>
          </div>
          <button class="file-item-remove" onclick="converter.removeFile(${index})">✕</button>
        </div>
      `
      )
      .join('');
  }

  removeFile(index) {
    this.files.splice(index, 1);
    this.renderFileList();
  }

  clearFiles() {
    this.files = [];
    this.renderFileList();
  }

  async convertAll() {
    if (this.files.length === 0) {
      alert('No files selected');
      return;
    }

    const progressSection = document.getElementById('progressSection');
    const resultsSection = document.getElementById('resultsSection');

    document.getElementById('filesSection').style.display = 'none';
    progressSection.style.display = 'block';
    resultsSection.style.display = 'none';

    this.results = [];
    const quality = document.getElementById('qualitySlider').value;
    const maxDimension = document.getElementById('maxDimension').value;
    const copyright = document.getElementById('copyrightText').value;

    for (let i = 0; i < this.files.length; i++) {
      const file = this.files[i];
      this.updateProgress(i, this.files.length);

      try {
        const result = await this.convertFile(file, { quality, maxDimension, copyright });
        this.results.push({ ...result, success: true, file });
        this.addConversionResult(file.name, true, result.originalResolution);
      } catch (error) {
        this.results.push({ success: false, file, error: error.message });
        this.addConversionResult(file.name, false, error.message);
      }
    }

    this.updateProgress(this.files.length, this.files.length);
    this.showResults();
  }

  async convertFile(file, options) {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('quality', options.quality);
    if (options.maxDimension) {
      formData.append('maxDimension', options.maxDimension);
    }
    if (options.copyright) {
      formData.append('copyright', options.copyright);
    }

    const response = await fetch('/api/convert', {
      method: 'POST',
      body: formData
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Conversion failed');
    }

    return await response.json();
  }

  updateProgress(current, total) {
    const percentage = (current / total) * 100;
    document.getElementById('overallProgressFill').style.width = percentage + '%';
    document.getElementById('progressText').textContent = `${current} / ${total} files`;
  }

  addConversionResult(filename, success, detail) {
    const results = document.getElementById('conversionResults');
    const resultDiv = document.createElement('div');
    resultDiv.className = `conversion-item ${success ? 'success' : 'error'}`;
    resultDiv.innerHTML = `
      <div class="conversion-item-name">${filename}</div>
      <div class="conversion-item-status">
        ${success ? '✓ Converted' : '✗ Failed'}: ${detail}
      </div>
    `;
    results.appendChild(resultDiv);
  }

  showResults() {
    const resultsSection = document.getElementById('resultsSection');
    const resultsGrid = document.getElementById('resultsGrid');

    resultsSection.style.display = 'block';
    resultsGrid.innerHTML = this.results
      .filter((r) => r.success)
      .map(
        (result) => `
        <div class="result-card">
          <div class="result-card-thumbnail">
            <img src="/api/output/${result.filename}?t=${Date.now()}" alt="${result.file.name}">
          </div>
          <div class="result-card-info">
            <div class="result-card-name">${result.file.name}</div>
            <div class="result-card-detail">${result.originalResolution}</div>
            <div class="result-card-detail">Quality: ${result.quality}</div>
            <div class="result-card-detail">Method: ${result.decodeMethod}</div>
            <div class="result-card-actions">
              <button onclick="converter.downloadFile('${result.filename}')">Download</button>
              <button onclick="converter.viewFile('${result.filename}')">View</button>
            </div>
          </div>
        </div>
      `
      )
      .join('');
  }

  async downloadFile(filename) {
    const link = document.createElement('a');
    link.href = `/api/output/${filename}`;
    link.download = filename;
    link.click();
  }

  viewFile(filename) {
    window.open(`/api/output/${filename}`, '_blank');
  }

  async downloadAsZip() {
    alert('ZIP download not yet implemented in MVP');
  }

  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
  }
}

const converter = new Converter();
