// Mobile Navigation Toggle
document.addEventListener('DOMContentLoaded', function() {
    const navToggle = document.querySelector('.nav-toggle');
    const navMenu = document.querySelector('.nav-menu');
    const navLinks = document.querySelectorAll('.nav-link');

    // Toggle mobile menu
    navToggle.addEventListener('click', function() {
        navMenu.classList.toggle('active');
        navToggle.classList.toggle('active');
    });

    // Close mobile menu when clicking on a link
    navLinks.forEach(link => {
        link.addEventListener('click', function() {
            navMenu.classList.remove('active');
            navToggle.classList.remove('active');
        });
    });

    // Close mobile menu when clicking outside
    document.addEventListener('click', function(event) {
        if (!navToggle.contains(event.target) && !navMenu.contains(event.target)) {
            navMenu.classList.remove('active');
            navToggle.classList.remove('active');
        }
    });

    // Hero Carousel functionality
    const heroCarouselTrack = document.getElementById('heroCarouselTrack');
    const heroPrevBtn = document.getElementById('heroPrevBtn');
    const heroNextBtn = document.getElementById('heroNextBtn');
    const heroCarouselDots = document.getElementById('heroCarouselDots');
    
    if (heroCarouselTrack && heroPrevBtn && heroNextBtn && heroCarouselDots) {
        const slides = heroCarouselTrack.querySelectorAll('.hero-carousel-slide');
        let currentSlide = 0;
        
        // Create dots
        slides.forEach((_, index) => {
            const dot = document.createElement('div');
            dot.className = 'hero-carousel-dot';
            if (index === 0) dot.classList.add('active');
            dot.addEventListener('click', () => goToSlide(index));
            heroCarouselDots.appendChild(dot);
        });
        
        function updateCarousel() {
            slides.forEach((slide, index) => {
                slide.classList.toggle('active', index === currentSlide);
            });
            
            const dots = heroCarouselDots.querySelectorAll('.hero-carousel-dot');
            dots.forEach((dot, index) => {
                dot.classList.toggle('active', index === currentSlide);
            });
        }
        
        function goToSlide(slideIndex) {
            currentSlide = slideIndex;
            updateCarousel();
        }
        
        function nextSlide() {
            currentSlide = (currentSlide + 1) % slides.length;
            updateCarousel();
        }
        
        function prevSlide() {
            currentSlide = (currentSlide - 1 + slides.length) % slides.length;
            updateCarousel();
        }
        
        heroNextBtn.addEventListener('click', nextSlide);
        heroPrevBtn.addEventListener('click', prevSlide);
        
        // Auto-advance carousel every 8 seconds
        setInterval(nextSlide, 8000);
    }

    // Full-Width Hero Carousel functionality
    const heroCarouselTrackFull = document.getElementById('heroCarouselTrackFull');
    const heroPrevBtnFull = document.getElementById('heroPrevBtnFull');
    const heroNextBtnFull = document.getElementById('heroNextBtnFull');
    const heroCarouselDotsFull = document.getElementById('heroCarouselDotsFull');
    
    if (heroCarouselTrackFull && heroPrevBtnFull && heroNextBtnFull && heroCarouselDotsFull) {
        const slidesFull = heroCarouselTrackFull.querySelectorAll('.hero-carousel-slide-full');
        let currentSlideFull = 0;
        
        // Create dots
        slidesFull.forEach((_, index) => {
            const dot = document.createElement('div');
            dot.className = 'hero-carousel-dot-full';
            if (index === 0) dot.classList.add('active');
            dot.addEventListener('click', () => goToSlideFull(index));
            heroCarouselDotsFull.appendChild(dot);
        });
        
        function updateCarouselFull() {
            slidesFull.forEach((slide, index) => {
                slide.classList.toggle('active', index === currentSlideFull);
            });
            
            const dots = heroCarouselDotsFull.querySelectorAll('.hero-carousel-dot-full');
            dots.forEach((dot, index) => {
                dot.classList.toggle('active', index === currentSlideFull);
            });
        }
        
        function goToSlideFull(slideIndex) {
            currentSlideFull = slideIndex;
            updateCarouselFull();
        }
        
        function nextSlideFull() {
            currentSlideFull = (currentSlideFull + 1) % slidesFull.length;
            updateCarouselFull();
        }
        
        function prevSlideFull() {
            currentSlideFull = (currentSlideFull - 1 + slidesFull.length) % slidesFull.length;
            updateCarouselFull();
        }
        
        heroNextBtnFull.addEventListener('click', nextSlideFull);
        heroPrevBtnFull.addEventListener('click', prevSlideFull);
        
        // Auto-advance carousel every 6 seconds for more dynamic feel
        setInterval(nextSlideFull, 6000);
    }
});

// Smooth scrolling for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            const offsetTop = target.offsetTop - 70; // Account for fixed navbar
            window.scrollTo({
                top: offsetTop,
                behavior: 'smooth'
            });
        }
    });
});

// Enhanced form validation with real-time feedback
function validateFormField(field) {
    const value = field.value.trim();
    const fieldGroup = field.closest('.form-group');
    
    // Remove existing validation classes
    fieldGroup.classList.remove('error', 'success');
    
    if (field.hasAttribute('required') && !value) {
        fieldGroup.classList.add('error');
        return false;
    }
    
    // Email validation
    if (field.type === 'email' && value) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(value)) {
            fieldGroup.classList.add('error');
            return false;
        }
    }
    
    // Phone validation
    if (field.type === 'tel' && value) {
        const phoneRegex = /^[\+]?[1-9][\d]{0,15}$/;
        if (!phoneRegex.test(value.replace(/\D/g, ''))) {
            fieldGroup.classList.add('error');
            return false;
        }
    }
    
    if (value) {
        fieldGroup.classList.add('success');
    }
    
    return true;
}

// Add real-time validation to form fields
document.addEventListener('DOMContentLoaded', function() {
    const formFields = document.querySelectorAll('input, textarea, select');
    
    formFields.forEach(field => {
        field.addEventListener('blur', function() {
            validateFormField(this);
        });
        
        field.addEventListener('input', function() {
            // Clear error state on input
            const fieldGroup = this.closest('.form-group');
            fieldGroup.classList.remove('error');
        });
    });
});

// RFQ Form Handling
const rfqForm = document.getElementById('rfqForm');
if (rfqForm) {
    rfqForm.addEventListener('submit', function(e) {
    e.preventDefault();
    
    // Get form data
    const formData = new FormData(this);
    const data = Object.fromEntries(formData);
    
    // Basic validation
    if (!data.name || !data.email || !data.project) {
        alert('Please fill in all required fields.');
        return;
    }
    
    // Email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(data.email)) {
        alert('Please enter a valid email address.');
        return;
    }
    
    // Simulate form submission
    const submitButton = this.querySelector('button[type="submit"]');
    const originalText = submitButton.textContent;

    submitButton.textContent = 'Submitting...';
    submitButton.disabled = true;
    
        // Send data to API
        fetch('/contact', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                name: data.name,
                email: data.email,
                message: data.project, // Map project field to message for API
                company: data.company,
                phone: data.phone,
                serviceType: data['service-type'] // Include service type
            })
        })
    .then(response => response.json())
    .then(result => {
        if (result.ok) {
            alert('Thank you for your RFQ submission! We will contact you within 24 hours.');
            this.reset();
        } else {
            alert('Error: ' + (result.error || 'Failed to submit form. Please try again.'));
        }
    })
    .catch(error => {
        console.error('Error:', error);
        alert('There was an error submitting your request. Please try again or contact us directly.');
    })
    .finally(() => {
        submitButton.textContent = originalText;
        submitButton.disabled = false;
    });
    });
}

// Enhanced Navbar scroll effect with class-based approach
window.addEventListener('scroll', function() {
    const navbar = document.querySelector('.navbar');
    if (window.scrollY > 50) {
        navbar.classList.add('scrolled');
    } else {
        navbar.classList.remove('scrolled');
    }
});

// Intersection Observer for animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver(function(entries) {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Observe elements for animation
document.addEventListener('DOMContentLoaded', function() {
    const animateElements = document.querySelectorAll('.highlight-item, .capability-item, .industry-item, .case-study, .equipment-category');
    
    animateElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });
});

// File upload validation
document.getElementById('files').addEventListener('change', function(e) {
    const files = e.target.files;
    const maxSize = 10 * 1024 * 1024; // 10MB
    const allowedTypes = ['application/pdf', 'image/vnd.dxf', 'application/step', 'application/octet-stream'];
    
    for (let file of files) {
        if (file.size > maxSize) {
            alert(`File ${file.name} is too large. Maximum size is 10MB.`);
            this.value = '';
            return;
        }
        
        if (!allowedTypes.includes(file.type) && !file.name.toLowerCase().endsWith('.dxf') && !file.name.toLowerCase().endsWith('.step') && !file.name.toLowerCase().endsWith('.stp')) {
            alert(`File ${file.name} is not a supported format. Please upload PDF, DXF, or STEP files.`);
            this.value = '';
            return;
        }
    }
});

// Lazy loading for images (if any are added later)
if ('IntersectionObserver' in window) {
    const imageObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                img.src = img.dataset.src;
                img.classList.remove('lazy');
                imageObserver.unobserve(img);
            }
        });
    });

    document.querySelectorAll('img[data-src]').forEach(img => {
        imageObserver.observe(img);
    });
}

// Performance optimization: Debounce scroll events
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Apply debouncing to scroll events
const debouncedScrollHandler = debounce(function() {
    const navbar = document.querySelector('.navbar');
    if (window.scrollY > 50) {
        navbar.style.backgroundColor = 'rgba(255, 255, 255, 0.95)';
        navbar.style.backdropFilter = 'blur(10px)';
    } else {
        navbar.style.backgroundColor = '#fff';
        navbar.style.backdropFilter = 'none';
    }
}, 10);

window.addEventListener('scroll', debouncedScrollHandler);

// Add loading states and error handling
function showLoading(element) {
    element.style.opacity = '0.6';
    element.style.pointerEvents = 'none';
}

function hideLoading(element) {
    element.style.opacity = '1';
    element.style.pointerEvents = 'auto';
}

// Error handling for form submission
function handleFormError(error) {
    console.error('Form submission error:', error);
    alert('There was an error submitting your request. Please try again or contact us directly.');
}

// Accessibility improvements
document.addEventListener('keydown', function(e) {
    // Close mobile menu with Escape key
    if (e.key === 'Escape') {
        const navMenu = document.querySelector('.nav-menu');
        const navToggle = document.querySelector('.nav-toggle');
        navMenu.classList.remove('active');
        navToggle.classList.remove('active');
    }
});

// Focus management for mobile menu
function trapFocus(element) {
    const focusableElements = element.querySelectorAll(
        'a[href], button, textarea, input[type="text"], input[type="radio"], input[type="checkbox"], select'
    );
    const firstFocusableElement = focusableElements[0];
    const lastFocusableElement = focusableElements[focusableElements.length - 1];

    element.addEventListener('keydown', function(e) {
        if (e.key === 'Tab') {
            if (e.shiftKey) {
                if (document.activeElement === firstFocusableElement) {
                    lastFocusableElement.focus();
                    e.preventDefault();
                }
            } else {
                if (document.activeElement === lastFocusableElement) {
                    firstFocusableElement.focus();
                    e.preventDefault();
                }
            }
        }
    });
}

// Apply focus trapping to mobile menu when it's open
const navMenu = document.querySelector('.nav-menu');
if (navMenu) {
    trapFocus(navMenu);
}
