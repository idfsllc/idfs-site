# IDFS Development & Deployment Workflow

## 🏠 **Local Development (No AWS Required)**

### Start Local Server:
```bash
npm install  # First time only
npm start    # Starts local server at http://localhost:3000
```

### What Runs Locally:
- ✅ Full website (all pages)
- ✅ Contact form (submits to local API)
- ✅ Console logging (no emails sent)
- ✅ Real-time testing (make changes, refresh browser)

### Local Development Files:
- `package.json` - Node.js dependencies
- `server.js` - Express server
- `node_modules/` - Installed packages
- `README-LOCAL-DEV.md` - Local dev instructions

---

## ☁️ **AWS Deployment (Production)**

### Deploy to AWS:
```bash
./deploy-to-aws.sh  # One command deploys everything
```

### What Gets Deployed to AWS:
- ✅ Website files (HTML, CSS, JS, images)
- ✅ Contact form (submits to real AWS API)
- ✅ Real email sending via SES
- ✅ CloudFront CDN
- ✅ SSL certificates

### AWS Deployment Files:
- `index.html` - Homepage
- `contact.html` - Contact page
- `capabilities.html` - Capabilities page
- `certifications.html` - Certifications page
- `industries.html` - Industries page
- `styles.css` - Main stylesheet
- `script.js` - JavaScript (with AWS API endpoint)
- `assets/Logo.png` - Logo image
- `robots.txt` - SEO file
- `sitemap.xml` - SEO file

---

## 🔄 **Development Workflow**

### 1. **Make Changes Locally:**
```bash
# Start local server
npm start

# Make changes to HTML/CSS/JS files
# Refresh browser to see changes
# Test contact form (logs to console)
```

### 2. **Deploy to AWS:**
```bash
# Stop local server (Ctrl+C)
# Deploy to AWS
./deploy-to-aws.sh
```

### 3. **Verify Deployment:**
- Check AWS console for resources
- Test live site
- Test contact form (sends real emails)

---

## 📁 **File Organization**

```
idfs/
├── 🏠 LOCAL DEVELOPMENT FILES (stay on your machine)
│   ├── package.json
│   ├── server.js
│   ├── node_modules/
│   └── README-LOCAL-DEV.md
│
├── ☁️ AWS DEPLOYMENT FILES (go to S3)
│   ├── index.html
│   ├── contact.html
│   ├── capabilities.html
│   ├── certifications.html
│   ├── industries.html
│   ├── styles.css
│   ├── script.js (with AWS API endpoint)
│   ├── assets/Logo.png
│   ├── robots.txt
│   └── sitemap.xml
│
├── 🛠️ INFRASTRUCTURE FILES
│   └── infra/ (Terraform configuration)
│
└── 📋 WORKFLOW FILES
    ├── deploy-to-aws.sh
    ├── .gitignore
    └── WORKFLOW.md (this file)
```

---

## ✅ **Verification Checklist**

### Local Development:
- [ ] `npm start` works
- [ ] Site loads at http://localhost:3000
- [ ] Contact form submits (logs to console)
- [ ] No AWS resources created

### AWS Deployment:
- [ ] `./deploy-to-aws.sh` runs successfully
- [ ] Only website files deployed to S3
- [ ] Local dev files NOT deployed
- [ ] Contact form sends real emails
- [ ] Site accessible via CloudFront URL

---

## 🚨 **Important Notes**

1. **Local dev files NEVER go to AWS** - They stay on your machine
2. **AWS deployment files NEVER run locally** - They go to S3/CloudFront
3. **Two different `script.js`** - Local version uses `/contact`, AWS version uses full API URL
4. **Separate workflows** - Local development vs AWS production are completely separate

---

## 🆘 **Troubleshooting**

### Local Server Issues:
- Check if port 3000 is available
- Run `npm install` if dependencies missing
- Check console for errors

### AWS Deployment Issues:
- Ensure AWS CLI configured
- Check Terraform state
- Verify S3 bucket permissions
- Check CloudFront cache invalidation

---

## 🎯 **Quick Commands**

```bash
# Local Development
npm start                    # Start local server
Ctrl+C                      # Stop local server

# AWS Deployment
./deploy-to-aws.sh          # Deploy to AWS
terraform destroy           # Tear down AWS resources

# File Management
git status                  # Check what files are tracked
git add .                   # Add files to git
git commit -m "message"     # Commit changes
```
