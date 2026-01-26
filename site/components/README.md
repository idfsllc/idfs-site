# Component System

This directory contains reusable HTML components for the IDFS website.

## Usage

### Adding a Component to a Page

1. Add the component loader script to your HTML `<head>`:
```html
<script src="components/loader.js" defer></script>
```

For pages in subdirectories, use the relative path:
```html
<script src="../components/loader.js" defer></script>
```

2. Add a placeholder div where you want the component to appear:
```html
<div data-component="navbar"></div>
```

The component loader will automatically:
- Detect the component name from the `data-component` attribute
- Load the component HTML from `components/[name].html`
- Fix relative paths based on the current page depth
- Inject the component into the placeholder
- Initialize any component-specific functionality

### Available Components

#### Navbar (`navbar.html`)
The main navigation bar used across all pages.

**Usage:**
```html
<header>
    <div data-component="navbar"></div>
</header>
```

### Creating New Components

1. Create a new HTML file in the `components/` directory (e.g., `footer.html`)
2. Add the component HTML (without `<html>`, `<head>`, or `<body>` tags)
3. Use relative paths for assets (they will be automatically fixed based on page depth)
4. Add any initialization logic to `loader.js` if needed

### Path Handling

The component loader automatically fixes relative paths based on the current page depth:
- Root level pages (`index.html`): `assets/logo.png` → `assets/logo.png`
- Subdirectory pages (`capabilities/cnc-machining.html`): `assets/logo.png` → `../assets/logo.png`

This ensures components work correctly regardless of where they're used.

### Component Initialization

If a component needs special initialization (like event listeners), add it to the `initializeComponent()` method in `loader.js`.

