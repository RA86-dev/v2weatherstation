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
