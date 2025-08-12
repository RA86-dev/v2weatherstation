#!/bin/bash

#
# Weather Station v2.0 - Documentation to HTML Converter
# ======================================================
# This script converts Markdown documentation in docs/ to HTML
# with enhanced features:
# - Beautiful responsive HTML with CSS styling
# - Syntax highlighting for code blocks
# - Automatic table of contents generation
# - Cross-references and navigation
# - Mobile-friendly design
# - Search functionality
# - Print-friendly styles
#

set -e

SCRIPT_VERSION="1.0.0"
DOCS_DIR="docs"
OUTPUT_DIR="docs-html"
TEMPLATE_DIR="${OUTPUT_DIR}/assets"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Logging functions
echo_header() {
    echo
    echo -e "${PURPLE}============================================${NC}"
    echo -e "${WHITE} $1 ${NC}"
    echo -e "${PURPLE}============================================${NC}"
    echo
}

echo_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo_step() {
    echo -e "${CYAN}🔧 $1${NC}"
}

# Check requirements
check_requirements() {
    echo_header "Checking Requirements"
    
    local requirements_met=true
    
    # Check for pandoc (preferred)
    if command -v pandoc >/dev/null 2>&1; then
        CONVERTER="pandoc"
        echo_success "Pandoc found - using high-quality conversion"
    # Check for markdown command
    elif command -v markdown >/dev/null 2>&1; then
        CONVERTER="markdown"
        echo_warning "Using basic markdown converter (install pandoc for better results)"
    # Check for Python markdown
    elif python3 -c "import markdown" 2>/dev/null; then
        CONVERTER="python"
        echo_warning "Using Python markdown module"
    else
        echo_error "No markdown converter found"
        echo_info "Please install one of:"
        echo_info "  • pandoc: https://pandoc.org/installing.html"
        echo_info "  • markdown: apt-get install markdown (Linux) or brew install markdown (macOS)"
        echo_info "  • Python markdown: pip install markdown"
        requirements_met=false
    fi
    
    if [ "$requirements_met" = false ]; then
        exit 1
    fi
}

# Create CSS styles
create_css() {
    echo_step "Creating CSS styles..."
    
    cat > "${TEMPLATE_DIR}/style.css" << 'EOF'
/* Weather Station Documentation Styles */
:root {
    --primary-color: #2563eb;
    --secondary-color: #64748b;
    --accent-color: #059669;
    --text-color: #1e293b;
    --text-light: #64748b;
    --bg-color: #ffffff;
    --bg-secondary: #f8fafc;
    --border-color: #e2e8f0;
    --code-bg: #f1f5f9;
    --shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
    --border-radius: 8px;
}

@media (prefers-color-scheme: dark) {
    :root {
        --primary-color: #3b82f6;
        --secondary-color: #94a3b8;
        --accent-color: #10b981;
        --text-color: #f1f5f9;
        --text-light: #94a3b8;
        --bg-color: #0f172a;
        --bg-secondary: #1e293b;
        --border-color: #334155;
        --code-bg: #1e293b;
    }
}

* {
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
    line-height: 1.6;
    color: var(--text-color);
    background-color: var(--bg-color);
    margin: 0;
    padding: 0;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 20px;
}

/* Header */
.header {
    background: linear-gradient(135deg, var(--primary-color), var(--accent-color));
    color: white;
    padding: 2rem 0;
    margin-bottom: 2rem;
}

.header h1 {
    margin: 0;
    font-size: 2.5rem;
    font-weight: 700;
}

.header p {
    margin: 0.5rem 0 0 0;
    font-size: 1.2rem;
    opacity: 0.9;
}

/* Navigation */
.nav {
    background: var(--bg-secondary);
    border-bottom: 1px solid var(--border-color);
    padding: 1rem 0;
    position: sticky;
    top: 0;
    z-index: 100;
}

.nav ul {
    list-style: none;
    margin: 0;
    padding: 0;
    display: flex;
    flex-wrap: wrap;
    gap: 2rem;
}

.nav a {
    color: var(--text-color);
    text-decoration: none;
    font-weight: 500;
    padding: 0.5rem 1rem;
    border-radius: var(--border-radius);
    transition: all 0.2s;
}

.nav a:hover {
    background: var(--primary-color);
    color: white;
}

/* Main content */
.main {
    display: grid;
    grid-template-columns: 1fr;
    gap: 2rem;
    margin-bottom: 3rem;
}

@media (min-width: 768px) {
    .main {
        grid-template-columns: 250px 1fr;
    }
}

/* Sidebar */
.sidebar {
    background: var(--bg-secondary);
    border: 1px solid var(--border-color);
    border-radius: var(--border-radius);
    padding: 1.5rem;
    height: fit-content;
    position: sticky;
    top: 100px;
}

.sidebar h3 {
    margin-top: 0;
    color: var(--primary-color);
}

.sidebar ul {
    list-style: none;
    padding: 0;
    margin: 0;
}

.sidebar li {
    margin: 0.5rem 0;
}

.sidebar a {
    color: var(--text-light);
    text-decoration: none;
    display: block;
    padding: 0.25rem 0;
    font-size: 0.9rem;
}

.sidebar a:hover {
    color: var(--primary-color);
}

/* Content */
.content {
    background: var(--bg-color);
    border: 1px solid var(--border-color);
    border-radius: var(--border-radius);
    padding: 2rem;
    box-shadow: var(--shadow);
}

/* Typography */
h1, h2, h3, h4, h5, h6 {
    margin-top: 2rem;
    margin-bottom: 1rem;
    font-weight: 600;
    line-height: 1.3;
}

h1 {
    font-size: 2.25rem;
    color: var(--primary-color);
    border-bottom: 3px solid var(--primary-color);
    padding-bottom: 0.5rem;
}

h2 {
    font-size: 1.875rem;
    color: var(--primary-color);
    border-bottom: 2px solid var(--border-color);
    padding-bottom: 0.25rem;
}

h3 {
    font-size: 1.5rem;
    color: var(--accent-color);
}

h4 {
    font-size: 1.25rem;
}

p {
    margin: 1rem 0;
}

/* Links */
a {
    color: var(--primary-color);
    text-decoration: none;
}

a:hover {
    text-decoration: underline;
}

/* Lists */
ul, ol {
    margin: 1rem 0;
    padding-left: 2rem;
}

li {
    margin: 0.5rem 0;
}

/* Tables */
table {
    width: 100%;
    border-collapse: collapse;
    margin: 1.5rem 0;
    background: var(--bg-color);
    border-radius: var(--border-radius);
    overflow: hidden;
    box-shadow: var(--shadow);
}

th, td {
    padding: 0.75rem 1rem;
    text-align: left;
    border-bottom: 1px solid var(--border-color);
}

th {
    background: var(--bg-secondary);
    font-weight: 600;
    color: var(--primary-color);
}

tr:nth-child(even) {
    background: var(--bg-secondary);
}

/* Code */
code {
    background: var(--code-bg);
    padding: 0.2rem 0.4rem;
    border-radius: 4px;
    font-family: 'SFMono-Regular', Consolas, monospace;
    font-size: 0.9em;
}

pre {
    background: var(--code-bg);
    border: 1px solid var(--border-color);
    border-radius: var(--border-radius);
    padding: 1rem;
    overflow-x: auto;
    margin: 1.5rem 0;
}

pre code {
    background: none;
    padding: 0;
    border-radius: 0;
}

/* Blockquotes */
blockquote {
    border-left: 4px solid var(--accent-color);
    background: var(--bg-secondary);
    margin: 1.5rem 0;
    padding: 1rem 1.5rem;
    border-radius: 0 var(--border-radius) var(--border-radius) 0;
}

/* Badges */
.badge {
    display: inline-block;
    padding: 0.25rem 0.75rem;
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    border-radius: 9999px;
    margin: 0.25rem;
}

.badge-primary {
    background: var(--primary-color);
    color: white;
}

.badge-success {
    background: var(--accent-color);
    color: white;
}

.badge-warning {
    background: #f59e0b;
    color: white;
}

/* Alerts */
.alert {
    padding: 1rem 1.5rem;
    border-radius: var(--border-radius);
    margin: 1.5rem 0;
    border-left: 4px solid;
}

.alert-info {
    background: #dbeafe;
    border-color: var(--primary-color);
    color: #1e40af;
}

.alert-success {
    background: #d1fae5;
    border-color: var(--accent-color);
    color: #047857;
}

.alert-warning {
    background: #fef3c7;
    border-color: #f59e0b;
    color: #92400e;
}

.alert-error {
    background: #fee2e2;
    border-color: #ef4444;
    color: #dc2626;
}

/* Footer */
.footer {
    background: var(--bg-secondary);
    border-top: 1px solid var(--border-color);
    padding: 2rem 0;
    margin-top: 3rem;
    text-align: center;
    color: var(--text-light);
}

/* Search */
.search {
    margin-bottom: 1rem;
}

.search input {
    width: 100%;
    padding: 0.75rem 1rem;
    border: 1px solid var(--border-color);
    border-radius: var(--border-radius);
    font-size: 1rem;
    background: var(--bg-color);
    color: var(--text-color);
}

.search input:focus {
    outline: none;
    border-color: var(--primary-color);
    box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
}

/* Responsive */
@media (max-width: 767px) {
    .header h1 {
        font-size: 2rem;
    }
    
    .nav ul {
        flex-direction: column;
        gap: 0.5rem;
    }
    
    .content {
        padding: 1rem;
    }
    
    .sidebar {
        position: static;
        margin-bottom: 2rem;
    }
}

/* Print styles */
@media print {
    .nav, .sidebar, .search {
        display: none;
    }
    
    .main {
        grid-template-columns: 1fr;
    }
    
    .content {
        border: none;
        box-shadow: none;
        padding: 0;
    }
    
    a {
        text-decoration: none;
    }
    
    a[href]:after {
        content: " (" attr(href) ")";
        font-size: 0.8em;
        color: var(--text-light);
    }
}

/* Syntax highlighting */
.hljs {
    background: var(--code-bg) !important;
    color: var(--text-color) !important;
}

.hljs-keyword, .hljs-selector-tag, .hljs-title {
    color: var(--primary-color) !important;
}

.hljs-string, .hljs-attr {
    color: var(--accent-color) !important;
}

.hljs-comment {
    color: var(--text-light) !important;
    font-style: italic;
}
EOF
    
    echo_success "CSS styles created"
}

# Create JavaScript for enhanced functionality
create_javascript() {
    echo_step "Creating JavaScript functionality..."
    
    cat > "${TEMPLATE_DIR}/script.js" << 'EOF'
// Weather Station Documentation JavaScript

document.addEventListener('DOMContentLoaded', function() {
    // Initialize functionality
    initializeSearch();
    initializeNavigation();
    initializeTOC();
    initializeThemeToggle();
    initializeScrollspy();
});

// Search functionality
function initializeSearch() {
    const searchInput = document.getElementById('search');
    if (!searchInput) return;
    
    searchInput.addEventListener('input', function(e) {
        const query = e.target.value.toLowerCase();
        const content = document.querySelector('.content');
        const elements = content.querySelectorAll('h1, h2, h3, h4, p, li');
        
        elements.forEach(element => {
            const text = element.textContent.toLowerCase();
            if (query && !text.includes(query)) {
                element.style.opacity = '0.3';
            } else {
                element.style.opacity = '1';
            }
        });
    });
}

// Navigation enhancement
function initializeNavigation() {
    // Add active states
    const currentPath = window.location.pathname;
    const navLinks = document.querySelectorAll('.nav a');
    
    navLinks.forEach(link => {
        if (link.getAttribute('href') === currentPath) {
            link.style.background = 'var(--primary-color)';
            link.style.color = 'white';
        }
    });
    
    // Smooth scrolling for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
}

// Table of contents generation
function initializeTOC() {
    const sidebar = document.querySelector('.sidebar ul');
    if (!sidebar) return;
    
    const headings = document.querySelectorAll('.content h2, .content h3');
    
    headings.forEach((heading, index) => {
        // Add ID if not present
        if (!heading.id) {
            heading.id = `heading-${index}`;
        }
        
        // Create TOC entry
        const li = document.createElement('li');
        const a = document.createElement('a');
        a.href = `#${heading.id}`;
        a.textContent = heading.textContent;
        a.style.paddingLeft = heading.tagName === 'H3' ? '1rem' : '0';
        
        li.appendChild(a);
        sidebar.appendChild(li);
    });
}

// Theme toggle functionality
function initializeThemeToggle() {
    // Create theme toggle button
    const nav = document.querySelector('.nav .container');
    if (nav) {
        const themeToggle = document.createElement('button');
        themeToggle.innerHTML = '🌙';
        themeToggle.style.cssText = `
            background: none;
            border: 1px solid var(--border-color);
            padding: 0.5rem;
            border-radius: var(--border-radius);
            cursor: pointer;
            font-size: 1rem;
            margin-left: auto;
        `;
        
        themeToggle.addEventListener('click', function() {
            document.body.classList.toggle('dark-theme');
            this.innerHTML = document.body.classList.contains('dark-theme') ? '☀️' : '🌙';
        });
        
        nav.appendChild(themeToggle);
    }
}

// Scroll spy for navigation
function initializeScrollspy() {
    const sections = document.querySelectorAll('.content h2[id]');
    const navLinks = document.querySelectorAll('.sidebar a');
    
    function updateActiveSection() {
        let current = '';
        
        sections.forEach(section => {
            const sectionTop = section.offsetTop;
            const sectionHeight = section.offsetHeight;
            
            if (window.scrollY >= sectionTop - 100) {
                current = section.getAttribute('id');
            }
        });
        
        navLinks.forEach(link => {
            link.style.color = 'var(--text-light)';
            if (link.getAttribute('href') === `#${current}`) {
                link.style.color = 'var(--primary-color)';
                link.style.fontWeight = '600';
            }
        });
    }
    
    window.addEventListener('scroll', updateActiveSection);
    updateActiveSection();
}

// Copy code functionality
document.addEventListener('click', function(e) {
    if (e.target.matches('pre code') || e.target.closest('pre')) {
        const code = e.target.matches('code') ? e.target : e.target.querySelector('code');
        if (code) {
            navigator.clipboard.writeText(code.textContent).then(() => {
                // Show copy feedback
                const feedback = document.createElement('div');
                feedback.textContent = 'Copied!';
                feedback.style.cssText = `
                    position: fixed;
                    top: 20px;
                    right: 20px;
                    background: var(--accent-color);
                    color: white;
                    padding: 0.5rem 1rem;
                    border-radius: var(--border-radius);
                    z-index: 1000;
                `;
                document.body.appendChild(feedback);
                
                setTimeout(() => {
                    document.body.removeChild(feedback);
                }, 2000);
            });
        }
    }
});
EOF
    
    echo_success "JavaScript functionality created"
}

# HTML template
create_html_template() {
    echo_step "Creating HTML template..."
    
    cat > "${TEMPLATE_DIR}/template.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{TITLE}} - Weather Station v2.0 Documentation</title>
    <meta name="description" content="{{DESCRIPTION}}">
    <meta name="generator" content="Weather Station Documentation Generator">
    
    <!-- Styles -->
    <link rel="stylesheet" href="assets/style.css">
    
    <!-- Syntax highlighting -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github.min.css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
    
    <!-- Favicon -->
    <link rel="icon" type="image/x-icon" href="data:image/x-icon;base64,AAABAAEAEBAAAAEAIABoBAAAFgAAACgAAAAQAAAAIAAAAAEAIAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAA==">
</head>
<body>
    <!-- Header -->
    <header class="header">
        <div class="container">
            <h1>Weather Station v2.0</h1>
            <p>{{TITLE}}</p>
        </div>
    </header>

    <!-- Navigation -->
    <nav class="nav">
        <div class="container">
            <ul>
                {{NAVIGATION}}
            </ul>
        </div>
    </nav>

    <!-- Main Content -->
    <main class="main container">
        <!-- Sidebar -->
        <aside class="sidebar">
            <h3>Table of Contents</h3>
            <div class="search">
                <input type="text" id="search" placeholder="Search documentation...">
            </div>
            <ul>
                <!-- Generated by JavaScript -->
            </ul>
        </aside>

        <!-- Content -->
        <div class="content">
            {{CONTENT}}
        </div>
    </main>

    <!-- Footer -->
    <footer class="footer">
        <div class="container">
            <p>Generated on {{DATE}} | Weather Station v2.0 Documentation</p>
            <p><a href="https://github.com/RA86-dev/v2weatherstation">GitHub Repository</a></p>
        </div>
    </footer>

    <!-- Scripts -->
    <script src="assets/script.js"></script>
    <script>
        // Initialize syntax highlighting
        hljs.highlightAll();
    </script>
</body>
</html>
EOF
    
    echo_success "HTML template created"
}

# Convert markdown to HTML using different converters
convert_markdown() {
    local input_file="$1"
    local output_file="$2"
    local title="$3"
    
    case "$CONVERTER" in
        pandoc)
            pandoc \
                --from markdown \
                --to html \
                --standalone \
                --template="${TEMPLATE_DIR}/template.html" \
                --variable title="$title" \
                --variable date="$(date)" \
                --highlight-style=github \
                --toc \
                --toc-depth=3 \
                "$input_file" > "$output_file"
            ;;
        markdown)
            local content=$(markdown "$input_file")
            local template=$(cat "${TEMPLATE_DIR}/template.html")
            template=${template//\{\{TITLE\}\}/$title}
            template=${template//\{\{CONTENT\}\}/$content}
            template=${template//\{\{DATE\}\}/$(date)}
            template=${template//\{\{DESCRIPTION\}\}/Weather Station v2.0 Documentation}
            template=${template//\{\{NAVIGATION\}\}/<li><a href="index.html">Home</a></li><li><a href="installation.html">Installation</a></li>}
            echo "$template" > "$output_file"
            ;;
        python)
            python3 << EOF
import markdown
import sys

with open('$input_file', 'r') as f:
    content = f.read()

html_content = markdown.markdown(content, extensions=['toc', 'codehilite', 'tables'])

with open('${TEMPLATE_DIR}/template.html', 'r') as f:
    template = f.read()

template = template.replace('{{TITLE}}', '$title')
template = template.replace('{{CONTENT}}', html_content)
template = template.replace('{{DATE}}', '$(date)')
template = template.replace('{{DESCRIPTION}}', 'Weather Station v2.0 Documentation')
template = template.replace('{{NAVIGATION}}', '<li><a href="index.html">Home</a></li><li><a href="installation.html">Installation</a></li>')

with open('$output_file', 'w') as f:
    f.write(template)
EOF
            ;;
    esac
}

# Process documentation files
process_docs() {
    echo_header "Converting Documentation Files"
    
    if [ ! -d "$DOCS_DIR" ]; then
        echo_error "Documentation directory '$DOCS_DIR' not found"
        exit 1
    fi
    
    # Create output directory
    rm -rf "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR" "$TEMPLATE_DIR"
    
    # Create assets
    create_css
    create_javascript
    create_html_template
    
    # Find all markdown files
    local md_files=()
    while IFS= read -r -d '' file; do
        md_files+=("$file")
    done < <(find "$DOCS_DIR" -name "*.md" -type f -print0)
    
    if [ ${#md_files[@]} -eq 0 ]; then
        echo_warning "No markdown files found in $DOCS_DIR"
        return
    fi
    
    echo_info "Found ${#md_files[@]} markdown files to convert"
    
    # Convert each file
    local nav_links=""
    for md_file in "${md_files[@]}"; do
        local relative_path="${md_file#$DOCS_DIR/}"
        local html_file="${OUTPUT_DIR}/${relative_path%.md}.html"
        local title=$(basename "$relative_path" .md)
        
        # Create directory structure
        mkdir -p "$(dirname "$html_file")"
        
        # Generate title from filename
        title=$(echo "$title" | tr '-_' ' ' | sed 's/\b\w/\U&/g')
        
        echo_step "Converting: $md_file -> $html_file"
        convert_markdown "$md_file" "$html_file" "$title"
        
        # Build navigation
        local nav_name=$(basename "$html_file" .html)
        nav_name=$(echo "$nav_name" | tr '-_' ' ' | sed 's/\b\w/\U&/g')
        local nav_path="${relative_path%.md}.html"
        nav_links="$nav_links<li><a href=\"$nav_path\">$nav_name</a></li>"
    done
    
    # Update navigation in all files
    if [ -n "$nav_links" ]; then
        echo_step "Updating navigation in all files..."
        for html_file in $(find "$OUTPUT_DIR" -name "*.html" -type f); do
            sed -i.bak "s|{{NAVIGATION}}|$nav_links|g" "$html_file"
            rm -f "${html_file}.bak"
        done
    fi
    
    # Create index if main.md exists
    if [ -f "$DOCS_DIR/main.md" ]; then
        echo_step "Creating index.html from main.md..."
        cp "${OUTPUT_DIR}/main.html" "${OUTPUT_DIR}/index.html"
    elif [ -f "$DOCS_DIR/README.md" ]; then
        echo_step "Creating index.html from README.md..."
        cp "${OUTPUT_DIR}/README.html" "${OUTPUT_DIR}/index.html"
    fi
    
    echo_success "Documentation conversion completed"
}

# Create additional files
create_additional_files() {
    echo_step "Creating additional files..."
    
    # Create .htaccess for Apache servers
    cat > "${OUTPUT_DIR}/.htaccess" << 'EOF'
# Weather Station Documentation - Apache Configuration

# Enable compression
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/plain
    AddOutputFilterByType DEFLATE text/html
    AddOutputFilterByType DEFLATE text/xml
    AddOutputFilterByType DEFLATE text/css
    AddOutputFilterByType DEFLATE application/xml
    AddOutputFilterByType DEFLATE application/xhtml+xml
    AddOutputFilterByType DEFLATE application/rss+xml
    AddOutputFilterByType DEFLATE application/javascript
    AddOutputFilterByType DEFLATE application/x-javascript
</IfModule>

# Enable browser caching
<IfModule mod_expires.c>
    ExpiresActive on
    ExpiresByType text/css "access plus 1 year"
    ExpiresByType application/javascript "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/jpg "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
</IfModule>

# Security headers
<IfModule mod_headers.c>
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
</IfModule>

# Default document
DirectoryIndex index.html

# Pretty URLs
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^([^\.]+)$ $1.html [NC,L]
EOF
    
    # Create robots.txt
    cat > "${OUTPUT_DIR}/robots.txt" << 'EOF'
User-agent: *
Allow: /

Sitemap: /sitemap.xml
EOF
    
    # Create sitemap.xml
    cat > "${OUTPUT_DIR}/sitemap.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
EOF
    
    find "$OUTPUT_DIR" -name "*.html" -type f | while read -r file; do
        local url_path="${file#$OUTPUT_DIR/}"
        cat >> "${OUTPUT_DIR}/sitemap.xml" << EOF
    <url>
        <loc>/$url_path</loc>
        <lastmod>$(date -Iseconds)</lastmod>
        <changefreq>weekly</changefreq>
        <priority>0.8</priority>
    </url>
EOF
    done
    
    cat >> "${OUTPUT_DIR}/sitemap.xml" << 'EOF'
</urlset>
EOF
    
    echo_success "Additional files created"
}

# Generate file listing
create_file_listing() {
    echo_step "Generating file listing..."
    
    cat > "${OUTPUT_DIR}/files.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>File Listing - Weather Station Documentation</title>
    <link rel="stylesheet" href="assets/style.css">
</head>
<body>
    <header class="header">
        <div class="container">
            <h1>Documentation Files</h1>
            <p>Complete listing of all documentation files</p>
        </div>
    </header>
    
    <main class="container">
        <div class="content">
            <h2>Generated Files</h2>
            <ul>
EOF
    
    find "$OUTPUT_DIR" -type f -name "*.html" | sort | while read -r file; do
        local relative_path="${file#$OUTPUT_DIR/}"
        local file_size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "Unknown")
        echo "                <li><a href=\"$relative_path\">$relative_path</a> (${file_size} bytes)</li>" >> "${OUTPUT_DIR}/files.html"
    done
    
    cat >> "${OUTPUT_DIR}/files.html" << 'EOF'
            </ul>
            
            <h2>Assets</h2>
            <ul>
                <li><a href="assets/style.css">style.css</a></li>
                <li><a href="assets/script.js">script.js</a></li>
            </ul>
        </div>
    </main>
</body>
</html>
EOF
    
    echo_success "File listing created"
}

# Display final information
display_final_info() {
    echo_header "Documentation Conversion Complete!"
    
    local file_count=$(find "$OUTPUT_DIR" -name "*.html" -type f | wc -l)
    local total_size=$(du -sh "$OUTPUT_DIR" 2>/dev/null | cut -f1 || echo "Unknown")
    
    echo_success "Successfully converted documentation to HTML!"
    echo
    echo -e "${CYAN}📊 Statistics:${NC}"
    echo "   • HTML files created: $file_count"
    echo "   • Total size: $total_size"
    echo "   • Output directory: $OUTPUT_DIR"
    echo
    echo -e "${CYAN}📁 Generated Files:${NC}"
    find "$OUTPUT_DIR" -name "*.html" -type f | sort | while read -r file; do
        echo "   • ${file#$OUTPUT_DIR/}"
    done
    echo
    echo -e "${CYAN}🌐 Viewing Documentation:${NC}"
    echo "   • Open in browser: file://$(pwd)/$OUTPUT_DIR/index.html"
    echo "   • Local server:    python3 -m http.server 8000 --directory $OUTPUT_DIR"
    echo "   • File listing:    $OUTPUT_DIR/files.html"
    echo
    echo -e "${CYAN}🚀 Publishing Options:${NC}"
    echo "   • Copy to web server: rsync -av $OUTPUT_DIR/ user@server:/var/www/html/"
    echo "   • GitHub Pages: Copy contents to gh-pages branch"
    echo "   • Static hosting: Upload $OUTPUT_DIR to any static host"
    echo
    echo -e "${CYAN}🔧 Customization:${NC}"
    echo "   • Edit CSS: $OUTPUT_DIR/assets/style.css"
    echo "   • Edit JS:  $OUTPUT_DIR/assets/script.js"
    echo "   • Templates: Modify and re-run this script"
    echo
    echo -e "${GREEN}📖 Your documentation is ready to use!${NC}"
}

# Usage information
show_usage() {
    cat << EOF
Weather Station Documentation to HTML Converter v$SCRIPT_VERSION

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -i, --input DIR         Input documentation directory (default: docs)
    -o, --output DIR        Output HTML directory (default: docs-html)
    -c, --converter TOOL    Markdown converter (pandoc|markdown|python)
    --no-assets             Don't generate CSS/JS assets
    --serve                 Start local server after conversion
    --port PORT             Server port for --serve (default: 8000)

EXAMPLES:
    # Basic conversion
    $0

    # Custom directories
    $0 --input my-docs --output html-output

    # Convert and serve immediately
    $0 --serve

    # Use specific converter
    $0 --converter pandoc

REQUIREMENTS:
    One of the following markdown converters:
    • pandoc (recommended): https://pandoc.org/
    • markdown command
    • Python markdown module: pip install markdown

FEATURES:
    • Responsive HTML with modern CSS
    • Syntax highlighting for code blocks
    • Automatic table of contents
    • Search functionality
    • Navigation between pages
    • Mobile-friendly design
    • Print-optimized styles
    • SEO-friendly structure

OUTPUT:
    The generated HTML documentation includes:
    • index.html (main page)
    • Individual HTML files for each markdown file
    • assets/style.css (styling)
    • assets/script.js (functionality)
    • .htaccess (Apache configuration)
    • robots.txt and sitemap.xml (SEO)

For more information, visit: https://github.com/RA86-dev/v2weatherstation
EOF
}

# Main function
main() {
    local serve=false
    local serve_port=8000
    local generate_assets=true
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -i|--input)
                DOCS_DIR="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                TEMPLATE_DIR="${OUTPUT_DIR}/assets"
                shift 2
                ;;
            -c|--converter)
                CONVERTER="$2"
                shift 2
                ;;
            --no-assets)
                generate_assets=false
                shift
                ;;
            --serve)
                serve=true
                shift
                ;;
            --port)
                serve_port="$2"
                shift 2
                ;;
            *)
                echo_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    echo_header "Weather Station Documentation Converter v$SCRIPT_VERSION"
    echo_info "Converting: $DOCS_DIR -> $OUTPUT_DIR"
    echo_info "Using converter: ${CONVERTER:-auto-detect}"
    
    # Run conversion
    check_requirements
    process_docs
    
    if [ "$generate_assets" = true ]; then
        create_additional_files
        create_file_listing
    fi
    
    display_final_info
    
    # Start local server if requested
    if [ "$serve" = true ]; then
        echo
        echo_step "Starting local server on port $serve_port..."
        echo_info "Press Ctrl+C to stop the server"
        cd "$OUTPUT_DIR"
        python3 -m http.server "$serve_port" 2>/dev/null || python -m SimpleHTTPServer "$serve_port"
    fi
}

# Error handling
trap 'echo; echo_error "Conversion interrupted"; exit 1' INT TERM

# Run main function
main "$@"