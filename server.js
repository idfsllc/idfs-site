const express = require('express');
const path = require('path');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS for all routes
app.use(cors());

// Serve static files from the site directory
app.use(express.static(path.join(__dirname, 'site')));

// Mock API endpoint for contact form (no actual email sending)
app.post('/contact', express.json(), (req, res) => {
  console.log('📧 Contact form submission received:');
  console.log('Name:', req.body.name);
  console.log('Email:', req.body.email);
  console.log('Company:', req.body.company);
  console.log('Phone:', req.body.phone);
  console.log('Message:', req.body.message);
  console.log('---');
  
  // Simulate processing delay
  setTimeout(() => {
    res.json({ ok: true });
  }, 500);
});

// Handle OPTIONS preflight requests
app.options('/contact', (req, res) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  res.sendStatus(200);
});

// Serve index.html for root route
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'site', 'index.html'));
});

// Serve capabilities statement PDF with proper headers
app.get('/capabilities-statement.pdf', (req, res) => {
  res.setHeader('Content-Type', 'text/html');
  res.setHeader('Content-Disposition', 'inline; filename="IDFS-Capabilities-Statement.html"');
  res.sendFile(path.join(__dirname, 'site', 'capabilities-statement.html'));
});

// Serve one-page capabilities PDF
app.get('/one-page-capabilities.pdf', (req, res) => {
  res.setHeader('Content-Type', 'text/html');
  res.setHeader('Content-Disposition', 'inline; filename="IDFS-One-Page-Capabilities.html"');
  res.sendFile(path.join(__dirname, 'site', 'one-page-capabilities.html'));
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 IDFS Local Development Server running at:`);
  console.log(`   http://localhost:${PORT}`);
  console.log(`   http://127.0.0.1:${PORT}`);
  console.log(`\n📝 Contact form will log submissions to console (no emails sent)`);
  console.log(`🔄 Auto-reload: Make changes to HTML/CSS/JS files and refresh browser\n`);
});
