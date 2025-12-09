const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 8080;
const REPORTS_DIR = path.join(__dirname, '../results/web-reports');

if (!fs.existsSync(REPORTS_DIR)) {
  fs.mkdirSync(REPORTS_DIR, { recursive: true });
}

const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  if (req.method === 'POST' && req.url === '/api/report') {
    let body = '';

    req.on('data', chunk => {
      body += chunk.toString();
    });

    req.on('end', () => {
      try {
        const report = JSON.parse(body);
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const filename = `report-${timestamp}.json`;

        fs.writeFileSync(
          path.join(REPORTS_DIR, filename),
          JSON.stringify(report, null, 2)
        );

        console.log(`saved report: ${filename}`);
        console.log(`  ip: ${report.ip}`);
        console.log(`  isp: ${report.isp}`);

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ ok: true, id: filename }));

      } catch (e) {
        console.error('failed to save report:', e);
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ ok: false, error: e.message }));
      }
    });

  } else if (req.method === 'GET' && req.url === '/') {
    fs.readFile(path.join(__dirname, 'diagnostic.html'), (err, data) => {
      if (err) {
        res.writeHead(500);
        res.end('error loading page');
        return;
      }
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(data);
    });

  } else {
    res.writeHead(404);
    res.end('not found');
  }
});

server.listen(PORT, () => {
  console.log(`report collector running on http://localhost:${PORT}`);
  console.log(`reports will be saved to: ${REPORTS_DIR}`);
});
