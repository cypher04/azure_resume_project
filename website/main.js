// Smooth scrolling for navigation links
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

// Navbar background change on scroll
const header = document.querySelector('header');
let lastScroll = 0;

window.addEventListener('scroll', () => {
    const currentScroll = window.pageYOffset;
    
    if (currentScroll > 100) {
        header.style.background = 'rgba(255, 255, 255, 0.98)';
        header.style.boxShadow = '0 2px 20px rgba(0,0,0,0.15)';
    } else {
        header.style.background = 'var(--white)';
        header.style.boxShadow = '0 2px 10px rgba(0,0,0,0.1)';
    }
    
    lastScroll = currentScroll;
});

// Intersection Observer for fade-in animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Observe all timeline items, education cards, and skill categories
document.addEventListener('DOMContentLoaded', () => {
    // Animate timeline items
    const timelineItems = document.querySelectorAll('.timeline-item');
    timelineItems.forEach((item, index) => {
        item.style.opacity = '0';
        item.style.transform = 'translateY(30px)';
        item.style.transition = 'all 0.6s ease';
        item.style.transitionDelay = `${index * 0.1}s`;
        observer.observe(item);
    });
    
    // Animate education cards
    const educationCards = document.querySelectorAll('.education-card');
    educationCards.forEach((card, index) => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(30px)';
        card.style.transition = 'all 0.6s ease';
        card.style.transitionDelay = `${index * 0.2}s`;
        observer.observe(card);
    });
    
    // Animate skill categories
    const skillCategories = document.querySelectorAll('.skill-category');
    skillCategories.forEach((category, index) => {
        category.style.opacity = '0';
        category.style.transform = 'translateY(30px)';
        category.style.transition = 'all 0.6s ease';
        category.style.transitionDelay = `${index * 0.15}s`;
        observer.observe(category);
    });
    
    // Animate about content
    const aboutContent = document.querySelector('.about-content');
    if (aboutContent) {
        aboutContent.style.opacity = '0';
        aboutContent.style.transform = 'translateY(30px)';
        aboutContent.style.transition = 'all 0.8s ease';
        observer.observe(aboutContent);
    }
    
    // Animate contact content
    const contactContent = document.querySelector('.contact-content');
    if (contactContent) {
        contactContent.style.opacity = '0';
        contactContent.style.transform = 'translateY(30px)';
        contactContent.style.transition = 'all 0.8s ease';
        observer.observe(contactContent);
    }
});

// Add active state to navigation links
const sections = document.querySelectorAll('section[id]');
const navLinks = document.querySelectorAll('.nav-links a');

window.addEventListener('scroll', () => {
    let current = '';
    sections.forEach(section => {
        const sectionTop = section.offsetTop;
        const sectionHeight = section.clientHeight;
        if (window.pageYOffset >= sectionTop - 200) {
            current = section.getAttribute('id');
        }
    });
    
    navLinks.forEach(link => {
        link.classList.remove('active');
        if (link.getAttribute('href').slice(1) === current) {
            link.classList.add('active');
        }
    });
});

// Skill tags hover effect enhancement
const skillTags = document.querySelectorAll('.skill-tag');
skillTags.forEach(tag => {
    tag.addEventListener('mouseenter', function() {
        this.style.transform = 'translateY(-2px) scale(1.05)';
    });
    
    tag.addEventListener('mouseleave', function() {
        this.style.transform = 'translateY(0) scale(1)';
    });
});

// Visitor Counter - Azure Cosmos DB Integration

const API_BASE_URL = 'https://<your-function-app>.azurewebsites.net/api';

async function updateVisitorCount() {
    const response = await fetch(`${API_BASE_URL}/visitor`, { method: 'POST' });
    const data = await response.json();
    document.getElementById('visitor-count').textContent = data.count;
}

document.addEventListener('DOMContentLoaded', updateVisitorCount);




// Replace YOUR_API_ENDPOINT with your Azure Function URL that connects to Cosmos DB
const VISITOR_API_ENDPOINT = 'https://your-function-app.azurewebsites.net/api/visitor-counter';

async function updateVisitorCount() {
    const visitorCountElement = document.getElementById('visitor-count');
    
    try {
        // POST request to increment and get the current count
        const response = await fetch(VISITOR_API_ENDPOINT, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        });
        
        if (!response.ok) {
            throw new Error('Failed to fetch visitor count');
        }
        
        const data = await response.json();
        
        if (visitorCountElement) {
            // Animate the count update
            visitorCountElement.classList.add('count-updated');
            visitorCountElement.textContent = `${data.count.toLocaleString()} visitors`;
            
            setTimeout(() => {
                visitorCountElement.classList.remove('count-updated');
            }, 300);
        }
    } catch (error) {
        console.error('Error updating visitor count:', error);
        
        // Fallback: Show a placeholder or use localStorage for demo
        if (visitorCountElement) {
            const localCount = parseInt(localStorage.getItem('visitorCount') || '0') + 1;
            localStorage.setItem('visitorCount', localCount.toString());
            visitorCountElement.textContent = `${localCount.toLocaleString()} visitors`;
        }
    }
}

// Fetch visitor count on page load
document.addEventListener('DOMContentLoaded', updateVisitorCount);





// Console message
console.log('%c👋 Welcome to my resume!', 'font-size: 20px; font-weight: bold; color: #3498db;');
console.log('%cInterested in the code? Check it out on GitHub!', 'font-size: 14px; color: #2c3e50;');
