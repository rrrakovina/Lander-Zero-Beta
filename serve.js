const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;
const PUBLIC_DIR = path.join(__dirname, 'build', 'web');

const MIME_TYPES = {
  '.html': 'text/html',
  '.css': 'text/css',
  '.js': 'text/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

const server = http.createServer((req, res) => {
  const requestTime = new Date().toISOString();
  
  res.on('finish', () => {
    console.log(`[${requestTime}] ${req.method} ${req.url} -> ${res.statusCode}`);
  });

  // Resolve file path
  let filePath = path.join(PUBLIC_DIR, req.url.split('?')[0]);
  if (filePath === PUBLIC_DIR || filePath.endsWith(path.sep)) {
    filePath = path.join(filePath, 'index.html');
  }

  // Check if file is outside of PUBLIC_DIR
  if (!filePath.startsWith(PUBLIC_DIR)) {
    res.statusCode = 403;
    res.end('Forbidden');
    return;
  }

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      res.statusCode = 404;
      res.setHeader('Content-Type', 'text/plain');
      res.end('Not Found');
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';

    // Set security and cache headers
    res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
    res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
    res.setHeader('Content-Type', contentType);
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0');

    // Intercept flutter_bootstrap.js to disable service worker loading
    if (ext === '.js' && path.basename(filePath) === 'flutter_bootstrap.js') {
      fs.readFile(filePath, 'utf8', (readErr, content) => {
        if (readErr) {
          res.statusCode = 500;
          res.end('Internal Server Error');
          return;
        }
        // Remove service worker settings block
        const modifiedContent = content.replace(/serviceWorkerSettings:\s*\{[\s\S]*?\}/g, 'serviceWorkerSettings: null');
        res.end(modifiedContent);
      });
      return;
    }

    const stream = fs.createReadStream(filePath);
    stream.on('error', (streamErr) => {
      console.error(streamErr);
      res.statusCode = 500;
      res.end('Internal Server Error');
    });
    stream.pipe(res);
  });
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`Server is running at http://localhost:${PORT}`);
});
