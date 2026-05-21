/**
 * Removes SEO/social metadata from site HTML files.
 * Keeps: charset, viewport, gtag, favicon, styles, fonts, loader, redirect mechanics.
 */
const fs = require("fs");
const path = require("path");

const SITE_DIR = path.join(__dirname, "..", "site");

function walkHtml(dir, files = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === "components") continue;
      walkHtml(full, files);
    } else if (entry.name.endsWith(".html")) {
      files.push(full);
    }
  }
  return files;
}

function pageLabel(filePath) {
  const base = path.basename(filePath, ".html");
  if (base === "index") return "Home";
  return base
    .split("-")
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(" ");
}

function isRedirectStub(html) {
  return (
    /<meta http-equiv="refresh"/i.test(html) ||
    /location\.replace\s*\(/i.test(html)
  );
}

function stripHtml(filePath) {
  let html = fs.readFileSync(filePath, "utf8");
  const redirect = isRedirectStub(html);

  // Structured data (JSON-LD) — only targeted blocks (never match from unrelated comments)
  html = html.replace(
    /\s*<!--\s*(?:Enhanced\s+)?Structured Data[^]*?-->\s*/gi,
    "\n"
  );
  html = html.replace(
    /\s*<script type="application\/ld\+json">[\s\S]*?<\/script>\s*/gi,
    "\n"
  );

  // Section comments
  html = html.replace(/\s*<!--\s*Open Graph Meta Tags\s*-->\s*/gi, "\n");
  html = html.replace(/\s*<!--\s*Twitter Card Meta Tags\s*-->\s*/gi, "\n");
  html = html.replace(/\s*<!--\s*Additional SEO Meta Tags\s*-->\s*/gi, "\n");

  const removeMeta = [
    /<meta name="description"[^>]*>\s*/gi,
    /<meta name="keywords"[^>]*>\s*/gi,
    /<meta name="googlebot"[^>]*>\s*/gi,
    /<meta name="bingbot"[^>]*>\s*/gi,
    /<meta name="language"[^>]*>\s*/gi,
    /<meta name="revisit-after"[^>]*>\s*/gi,
    /<meta name="distribution"[^>]*>\s*/gi,
    /<meta name="rating"[^>]*>\s*/gi,
    /<meta name="author"[^>]*>\s*/gi,
    /<meta name="geo\.region"[^>]*>\s*/gi,
    /<meta name="geo\.placename"[^>]*>\s*/gi,
    /<meta property="og:[^"]*"[^>]*>\s*/gi,
    /<meta name="twitter:[^"]*"[^>]*>\s*/gi,
    /<link rel="canonical"[^>]*>\s*/gi,
  ];

  if (!redirect) {
    removeMeta.push(/<meta name="robots"[^>]*>\s*/gi);
  }

  for (const pattern of removeMeta) {
    html = html.replace(pattern, "");
  }

  const label = pageLabel(filePath);
  html = html.replace(/<title>[^<]*<\/title>/i, `<title>${label} | IDFS</title>`);

  // Close <head> when JSON-LD used to sit between loader and <body> (index.html)
  html = html.replace(
    /(<script[^>]*loader\.js[^>]*><\/script>)\s*(<body\b)/i,
    "$1\n</head>\n$2"
  );

  html = html.replace(/\n{3,}/g, "\n\n");
  fs.writeFileSync(filePath, html, "utf8");
}

function stripMetaJson() {
  const jsonPath = path.join(SITE_DIR, "SITE_CONTENT_AND_META_TAGS.json");
  if (!fs.existsSync(jsonPath)) return;

  const data = JSON.parse(fs.readFileSync(jsonPath, "utf8"));
  const emptyMeta = {
    description: "",
    keywords: "",
    robots: "",
    language: "",
    author: "",
    geo_region: "",
    geo_placename: "",
  };
  const emptyOg = {
    "og:title": "",
    "og:description": "",
    "og:type": "",
    "og:url": "",
    "og:image": "",
    "og:site_name": "",
    "og:locale": "",
  };
  const emptyTwitter = {
    "twitter:card": "",
    "twitter:title": "",
    "twitter:description": "",
    "twitter:image": "",
  };

  if (Array.isArray(data.pages)) {
    for (const page of data.pages) {
      page.title = "";
      page.meta_tags = { ...emptyMeta };
      page.open_graph = { ...emptyOg };
      page.twitter_card = { ...emptyTwitter };
      page.structured_data = {};
      if (page.canonical !== undefined) page.canonical = "";
    }
  }

  fs.writeFileSync(jsonPath, JSON.stringify(data, null, 2) + "\n", "utf8");
}

const files = walkHtml(SITE_DIR);
for (const file of files) {
  stripHtml(file);
  console.log("stripped:", path.relative(SITE_DIR, file));
}
stripMetaJson();
console.log("done:", files.length, "html files");
