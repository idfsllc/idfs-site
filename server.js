/**
 * IDFS Local Development Server
 * Serves static site files and provides mock API endpoints for local development
 */

const express = require('express');
const path = require('path');
const cors = require('cors');
const puppeteer = require('puppeteer');

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS for all routes
app.use(cors());

// Disable caching for development (allows seeing changes immediately)
app.use((req, res, next) => {
    res.set('Cache-Control', 'no-store, no-cache, must-revalidate, private');
    res.set('Pragma', 'no-cache');
    res.set('Expires', '0');
    next();
});

// Generate and serve capabilities statement as PDF (must be before static middleware)
app.get('/capabilities-statement.pdf', async (req, res) => {
  try {
    // Use request host or fallback to localhost for local dev
    const protocol = req.protocol || 'http';
    const host = req.get('host') || `localhost:${PORT}`;
    const htmlUrl = `${protocol}://${host}/one-page-capabilities-pdf.html`;
    
    console.log(`📄 Generating PDF from: ${htmlUrl}`);
    
    // Launch browser
    const browser = await puppeteer.launch({
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const page = await browser.newPage();
    
    // Load the HTML file via HTTP
    await page.goto(htmlUrl, {
      waitUntil: 'networkidle0',
      timeout: 30000
    });
    
    // Generate PDF
    const pdfBuffer = await page.pdf({
      format: 'Letter',
      margin: {
        top: '0.5in',
        right: '0.5in',
        bottom: '0.5in',
        left: '0.5in'
      },
      printBackground: true
    });
    
    await browser.close();
    
    console.log(`✅ PDF generated successfully (${pdfBuffer.length} bytes)`);
    
    // Send PDF as download
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'attachment; filename="IDFS-Capabilities-Statement.pdf"');
    res.setHeader('Content-Length', pdfBuffer.length);
    res.end(pdfBuffer, 'binary');
  } catch (error) {
    console.error('❌ Error generating PDF:', error);
    res.status(500).send('Error generating PDF: ' + error.message);
  }
});

// Serve static files from the site directory with proper MIME types
app.use(express.static(path.join(__dirname, 'site'), {
    setHeaders: (res, filePath) => {
        // Ensure MP4 videos are served with correct MIME type
        if (filePath.endsWith('.mp4')) {
            res.setHeader('Content-Type', 'video/mp4');
        }
    }
}));

// Mock API endpoint for contact form (no actual email sending in dev)
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

// Handle OPTIONS preflight requests for CORS
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

// Serve one-page capabilities as HTML (served as PDF route for compatibility)
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
