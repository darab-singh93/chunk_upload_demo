const express = require('express');
const fs = require('fs');
const path = require('path');
const cors = require('cors');

const app = express();
app.use(cors());

// Require to create a folder uploads to save files inside node project.
const UPLOAD_DIR = path.join(__dirname, 'uploads');
if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR);

// Get uploaded file size (resumable status)
app.get('/status', (req, res) => {
  const fileName = req.query.fileName;
  const filePath = path.join(UPLOAD_DIR, fileName);
  if (!fs.existsSync(filePath)) return res.json({ uploaded: 0 });

  const stats = fs.statSync(filePath);
  res.json({ uploaded: stats.size });
});

// Upload chunk
app.post('/upload', express.raw({ type: '*/*', limit: '10mb' }), (req, res) => {
  const fileName = req.headers['file-name'];
  const contentRange = req.headers['content-range']; // e.g., "bytes 0-999999/5000000"
  const filePath = path.join(UPLOAD_DIR, fileName);

  if (!fileName || !contentRange) {
    return res.status(400).send('Missing headers');
  }

  const matches = contentRange.match(/bytes (\d+)-(\d+)\/(\d+)/);
  if (!matches) return res.status(400).send('Invalid Content-Range');

  const start = parseInt(matches[1], 10);
  const end = parseInt(matches[2], 10);

  const writeStream = fs.createWriteStream(filePath, {
    flags: 'a',
    start: start,
  });

  writeStream.write(req.body);
  writeStream.end(() => {
    res.status(200).send('Chunk received');
  });
});

app.listen(3000, '0.0.0.0', () => {
  console.log('🚀 Server running at http://0.0.0.0:3000');
});
