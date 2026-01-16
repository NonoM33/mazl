// ================================================
// MAZL Landing Page - Conversion Optimized Script
// ================================================

// DOM Elements
const toast = document.getElementById('toast');
const userCountEl = document.getElementById('user-count');

// ================================================
// Live Counter Animation
// ================================================
function animateCounter() {
  if (!userCountEl) return;

  const targetCount = 2847;
  const startCount = 2500;
  const duration = 2000;
  const startTime = performance.now();

  function update(currentTime) {
    const elapsed = currentTime - startTime;
    const progress = Math.min(elapsed / duration, 1);

    // Easing function (ease-out)
    const easeOut = 1 - Math.pow(1 - progress, 3);
    const currentCount = Math.round(startCount + (targetCount - startCount) * easeOut);

    userCountEl.textContent = currentCount.toLocaleString('fr-FR');

    if (progress < 1) {
      requestAnimationFrame(update);
    }
  }

  // Start animation when element is visible
  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        requestAnimationFrame(update);
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.5 });

  observer.observe(userCountEl);
}

// Simulate live counter updates (small increments)
function simulateLiveUpdates() {
  if (!userCountEl) return;

  setInterval(() => {
    const currentCount = parseInt(userCountEl.textContent.replace(/\s/g, '').replace(/,/g, ''), 10);
    // Random +1 or +2 every 30-60 seconds
    if (Math.random() > 0.7) {
      const newCount = currentCount + (Math.random() > 0.5 ? 1 : 2);
      userCountEl.textContent = newCount.toLocaleString('fr-FR');
    }
  }, 30000);
}

// ================================================
// Analytics Event Tracking
// ================================================
function trackEvent(eventName, params = {}) {
  // Google Analytics 4
  if (typeof gtag === 'function') {
    gtag('event', eventName, params);
  }

  // Meta Pixel (if added later)
  if (typeof fbq === 'function') {
    if (eventName === 'app_download') {
      fbq('track', 'Lead', params);
    }
  }

  // Console log for debugging (remove in production)
  console.log('Track:', eventName, params);
}

// Track store badge clicks
function setupAnalytics() {
  // Track all store badge clicks
  document.querySelectorAll('.store-badge').forEach((badge) => {
    badge.addEventListener('click', () => {
      const isApple = badge.href.includes('apple');
      trackEvent('app_download', {
        platform: isApple ? 'ios' : 'android',
        location: badge.closest('.hero') ? 'hero' : badge.closest('.final-cta') ? 'final_cta' : 'other'
      });
    });
  });

  // Track nav CTA click
  const navBtn = document.querySelector('.nav-btn');
  if (navBtn) {
    navBtn.addEventListener('click', () => {
      trackEvent('nav_cta_click');
    });
  }

  // Track sticky CTA click
  const stickyCta = document.querySelector('.sticky-cta .btn-primary');
  if (stickyCta) {
    stickyCta.addEventListener('click', () => {
      trackEvent('app_download', {
        platform: 'ios',
        location: 'sticky_cta'
      });
    });
  }

  // Track scroll depth
  let scrollDepths = [25, 50, 75, 100];
  let trackedDepths = [];

  window.addEventListener('scroll', () => {
    const scrollPercent = Math.round(
      (window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100
    );

    scrollDepths.forEach((depth) => {
      if (scrollPercent >= depth && !trackedDepths.includes(depth)) {
        trackedDepths.push(depth);
        trackEvent('scroll_depth', { percent: depth });
      }
    });
  }, { passive: true });
}

// ================================================
// Toast Notification
// ================================================
function showToast(message, type = 'info') {
  if (!toast) return;

  toast.textContent = message;
  toast.className = `toast ${type} show`;

  setTimeout(() => {
    toast.classList.remove('show');
  }, 4000);
}

// ================================================
// URL Parameters Handler
// ================================================
function handleUrlParams() {
  const params = new URLSearchParams(window.location.search);

  if (params.get('confirmed') === 'true') {
    showToast('Email confirmé ! Tu es sur la liste.', 'success');
    window.history.replaceState({}, '', '/');
  }

  if (params.get('error')) {
    const error = params.get('error');
    if (error === 'token_missing' || error === 'invalid_token') {
      showToast('Lien de confirmation invalide ou expiré.', 'error');
    }
    window.history.replaceState({}, '', '/');
  }
}

// ================================================
// Smooth Scroll for Anchor Links
// ================================================
function setupSmoothScroll() {
  document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
    anchor.addEventListener('click', function (e) {
      const targetId = this.getAttribute('href');
      if (targetId === '#') return;

      const target = document.querySelector(targetId);
      if (target) {
        e.preventDefault();
        target.scrollIntoView({ behavior: 'smooth' });
      }
    });
  });
}

// ================================================
// FAQ Accordion (optional enhancement)
// ================================================
function setupFaqTracking() {
  document.querySelectorAll('.faq-item').forEach((item) => {
    item.addEventListener('toggle', () => {
      if (item.open) {
        const question = item.querySelector('summary span')?.textContent || 'unknown';
        trackEvent('faq_open', { question: question.substring(0, 50) });
      }
    });
  });
}

// ================================================
// Initialize
// ================================================
document.addEventListener('DOMContentLoaded', () => {
  handleUrlParams();
  animateCounter();
  simulateLiveUpdates();
  setupAnalytics();
  setupSmoothScroll();
  setupFaqTracking();
});
