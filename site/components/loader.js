/**
 * Component Loader
 * Loads HTML components and injects them into the page
 */

class ComponentLoader {
    constructor() {
        this.components = new Map();
        this.loaded = false;
    }

    /**
     * Get the base path for components based on current page location
     * @returns {string} Base path to components directory
     */
    getBasePath() {
        const path = window.location.pathname;
        const depth = (path.match(/\//g) || []).length - 1; // Subtract 1 for root
        
        // #region agent log
        fetch('http://127.0.0.1:7244/ingest/507464c6-94e3-44b5-b047-102244760801',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'loader.js:18',message:'getBasePath called',data:{path,depth,calculatedPath:depth===0?'components/':'../'.repeat(depth)+'components/'},timestamp:Date.now(),sessionId:'debug-session',runId:'run1',hypothesisId:'B'})}).catch(()=>{});
        // #endregion
        
        if (depth === 0) {
            return 'components/';
        } else {
            return '../'.repeat(depth) + 'components/';
        }
    }

    /**
     * Fix relative paths in HTML based on current page depth
     * @param {string} html - HTML string to fix
     * @returns {string} HTML with fixed paths
     */
    fixRelativePaths(html) {
        const path = window.location.pathname;
        const depth = (path.match(/\//g) || []).length - 1;
        
        // #region agent log
        fetch('http://127.0.0.1:7244/ingest/507464c6-94e3-44b5-b047-102244760801',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'loader.js:33',message:'fixRelativePaths entry',data:{path,depth,htmlLength:html.length,hasIndexHtml:html.includes('href="index.html"'),hasAssets:html.includes('assets/')},timestamp:Date.now(),sessionId:'debug-session',runId:'post-fix',hypothesisId:'A'})}).catch(()=>{});
        // #endregion
        
        if (depth === 0) {
            // Root level - paths are already correct
            return html;
        }
        
        // For subdirectories, need to add ../ prefix to asset paths and page links
        const prefix = '../'.repeat(depth);
        
        // Fix asset paths (src, href attributes that point to assets/)
        let fixedHtml = html.replace(
            /(src|href)=["'](assets\/[^"']+)["']/g,
            (match, attr, path) => {
                // Don't fix if already has ../ or is absolute
                if (path.startsWith('../') || path.startsWith('http') || path.startsWith('/')) {
                    return match;
                }
                return `${attr}="${prefix}${path}"`;
            }
        );
        
        // Fix page links (href attributes that point to .html files in root)
        // Match href="page.html" or href="page.html#anchor" but not href="../page.html" or absolute URLs
        fixedHtml = fixedHtml.replace(
            /(href)=["']([^"']+\.html(?:#[^"']*)?)["']/g,
            (match, attr, linkPath) => {
                // Don't fix if already has ../ or is absolute or starts with http
                if (linkPath.startsWith('../') || linkPath.startsWith('http') || linkPath.startsWith('/') || linkPath.includes('/')) {
                    return match;
                }
                // Only fix simple page links like index.html, capabilities.html, etc.
                return `${attr}="${prefix}${linkPath}"`;
            }
        );
        
        // #region agent log
        fetch('http://127.0.0.1:7244/ingest/507464c6-94e3-44b5-b047-102244760801',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'loader.js:62',message:'fixRelativePaths after all fixes',data:{fixedHtmlLength:fixedHtml.length,stillHasIndexHtml:fixedHtml.includes('href="index.html"'),hasFixedIndexHtml:fixedHtml.includes('href="../index.html"'),hasFixedCapabilities:fixedHtml.includes('href="../capabilities.html"')},timestamp:Date.now(),sessionId:'debug-session',runId:'post-fix',hypothesisId:'A'})}).catch(()=>{});
        // #endregion
        
        return fixedHtml;
    }

    /**
     * Load a component from a file
     * @param {string} componentName - Name of the component (without .html)
     * @param {string} targetSelector - CSS selector where component should be inserted
     * @param {string} basePath - Base path for components (auto-detected if not provided)
     */
    async loadComponent(componentName, targetSelector, basePath = null) {
        try {
            if (!basePath) {
                basePath = this.getBasePath();
            }
            
            // #region agent log
            fetch('http://127.0.0.1:7244/ingest/507464c6-94e3-44b5-b047-102244760801',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'loader.js:66',message:'loadComponent entry',data:{componentName,targetSelector,basePath,url:`${basePath}${componentName}.html`},timestamp:Date.now(),sessionId:'debug-session',runId:'run1',hypothesisId:'C'})}).catch(()=>{});
            // #endregion
            
            const response = await fetch(`${basePath}${componentName}.html`);
            
            // #region agent log
            fetch('http://127.0.0.1:7244/ingest/507464c6-94e3-44b5-b047-102244760801',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'loader.js:71',message:'fetch response',data:{ok:response.ok,status:response.status,statusText:response.statusText},timestamp:Date.now(),sessionId:'debug-session',runId:'run1',hypothesisId:'C'})}).catch(()=>{});
            // #endregion
            
            if (!response.ok) {
                throw new Error(`Failed to load component: ${componentName}`);
            }
            const html = await response.text();
            const target = document.querySelector(targetSelector);
            
            // #region agent log
            fetch('http://127.0.0.1:7244/ingest/507464c6-94e3-44b5-b047-102244760801',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'loader.js:78',message:'target element check',data:{targetFound:!!target,htmlLength:html.length},timestamp:Date.now(),sessionId:'debug-session',runId:'run1',hypothesisId:'D'})}).catch(()=>{});
            // #endregion
            
            if (!target) {
                console.warn(`Target selector "${targetSelector}" not found for component "${componentName}"`);
                return;
            }

            // Fix relative paths in HTML based on current page depth
            const fixedHtml = this.fixRelativePaths(html);
            
            // #region agent log
            fetch('http://127.0.0.1:7244/ingest/507464c6-94e3-44b5-b047-102244760801',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'loader.js:87',message:'before innerHTML insert',data:{fixedHtmlLength:fixedHtml.length,fixedHtmlPreview:fixedHtml.substring(0,200)},timestamp:Date.now(),sessionId:'debug-session',runId:'run1',hypothesisId:'A'})}).catch(()=>{});
            // #endregion
            
            // Insert the component HTML
            target.innerHTML = fixedHtml;
            
            // Store component for potential reuse
            this.components.set(componentName, fixedHtml);
            
            // Initialize component-specific functionality if needed
            this.initializeComponent(componentName);
            
            return fixedHtml;
        } catch (error) {
            // #region agent log
            fetch('http://127.0.0.1:7244/ingest/507464c6-94e3-44b5-b047-102244760801',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'loader.js:97',message:'loadComponent error',data:{error:error.message,stack:error.stack},timestamp:Date.now(),sessionId:'debug-session',runId:'run1',hypothesisId:'C'})}).catch(()=>{});
            // #endregion
            console.error(`Error loading component ${componentName}:`, error);
        }
    }

    /**
     * Initialize component-specific functionality
     * @param {string} componentName - Name of the component
     */
    initializeComponent(componentName) {
        if (componentName === 'navbar') {
            // Navbar functionality is handled by script.js
            // This ensures it works after component is loaded
            this.setupNavbar();
        }
    }

    /**
     * Setup navbar functionality after component is loaded
     */
    setupNavbar() {
        // Wait a tick to ensure DOM is ready
        setTimeout(() => {
            const navToggle = document.querySelector('.nav-toggle');
            const navMenu = document.querySelector('.nav-menu');
            const navLinks = document.querySelectorAll('.nav-link');
            const navbar = document.querySelector('.navbar');

            // #region agent log
            fetch('http://127.0.0.1:7244/ingest/507464c6-94e3-44b5-b047-102244760801',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'loader.js:119',message:'setupNavbar elements check',data:{navToggleFound:!!navToggle,navMenuFound:!!navMenu,navbarFound:!!navbar,navLinksCount:navLinks.length},timestamp:Date.now(),sessionId:'debug-session',runId:'run1',hypothesisId:'D'})}).catch(()=>{});
            // #endregion

            if (navToggle && navMenu) {
                // Remove existing listeners if any
                const newToggle = navToggle.cloneNode(true);
                navToggle.parentNode.replaceChild(newToggle, navToggle);

                // Add click listener
                newToggle.addEventListener('click', function() {
                    navMenu.classList.toggle('active');
                    newToggle.classList.toggle('active');
                });

                // Close menu when clicking links
                navLinks.forEach(link => {
                    link.addEventListener('click', function() {
                        navMenu.classList.remove('active');
                        newToggle.classList.remove('active');
                    });
                });

                // Close menu when clicking outside
                document.addEventListener('click', function(event) {
                    if (!newToggle.contains(event.target) && !navMenu.contains(event.target)) {
                        navMenu.classList.remove('active');
                        newToggle.classList.remove('active');
                    }
                });
            }

            // Setup scroll handler for navbar logo switching
            if (navbar) {
                this.setupNavbarScroll(navbar);
            }
        }, 0);
    }

    /**
     * Setup scroll handler for navbar logo switching
     * @param {HTMLElement} navbar - The navbar element
     */
    setupNavbarScroll(navbar) {
        // Ensure navbar is visible
        navbar.style.opacity = '1';
        navbar.style.visibility = 'visible';
        
        // Remove any conflicting inline styles that might override CSS
        navbar.style.backgroundColor = '';
        navbar.style.backdropFilter = '';
        navbar.style.webkitBackdropFilter = '';
        
        // Check initial scroll position
        if (window.scrollY > 50) {
            navbar.classList.add('scrolled');
        } else {
            navbar.classList.remove('scrolled');
        }

        // Add scroll event listener (throttled for performance)
        let ticking = false;
        const handleScroll = () => {
            if (!ticking) {
                window.requestAnimationFrame(() => {
                    if (window.scrollY > 50) {
                        navbar.classList.add('scrolled');
                    } else {
                        navbar.classList.remove('scrolled');
                    }
                    ticking = false;
                });
                ticking = true;
            }
        };
        
        window.addEventListener('scroll', handleScroll, { passive: true });
    }

    /**
     * Load multiple components
     * @param {Array} components - Array of {name, selector, basePath} objects
     */
    async loadComponents(components) {
        const promises = components.map(comp => 
            this.loadComponent(comp.name, comp.selector, comp.basePath)
        );
        await Promise.all(promises);
        this.loaded = true;
    }
}

// Create global instance
const componentLoader = new ComponentLoader();

// Auto-load components marked with data-component attribute
document.addEventListener('DOMContentLoaded', function() {
    const componentElements = document.querySelectorAll('[data-component]');
    
    componentElements.forEach(element => {
        const componentName = element.getAttribute('data-component');
        const basePath = element.getAttribute('data-base-path') || null; // Auto-detect if not provided
        const selector = `[data-component="${componentName}"]`;
        
        componentLoader.loadComponent(componentName, selector, basePath);
    });
});

