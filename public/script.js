// DOM Elements
const form1 = document.getElementById('waitlist-form');
const form2 = document.getElementById('waitlist-form-2');
const email1 = document.getElementById('email');
const email2 = document.getElementById('email-2');
const message1 = document.getElementById('form-message');
const message2 = document.getElementById('form-message-2');
const countEl = document.getElementById('count');
const toast = document.getElementById('toast');

// Check URL params for confirmation status
document.addEventListener('DOMContentLoaded', () => {
  const params = new URLSearchParams(window.location.search);
  
  if (params.get('confirmed') === 'true') {
    showToast('Email confirmé ! Tu es sur la liste.', 'success');
    // Clean URL
    window.history.replaceState({}, '', '/');
  }
  
  if (params.get('error')) {
    const error = params.get('error');
    if (error === 'token_missing' || error === 'invalid_token') {
      showToast('Lien de confirmation invalide ou expiré.', 'error');
    }
    window.history.replaceState({}, '', '/');
  }
  
  // Load count
  loadCount();
});

// Load waitlist count
async function loadCount() {
  try {
    const res = await fetch('/api/count');
    const data = await res.json();
    animateCount(data.total || 0);
  } catch (e) {
    console.error('Failed to load count:', e);
  }
}

// Animate count number
function animateCount(target) {
  const duration = 1500;
  const start = 0;
  const startTime = performance.now();
  
  function update(currentTime) {
    const elapsed = currentTime - startTime;
    const progress = Math.min(elapsed / duration, 1);
    
    // Easing
    const eased = 1 - Math.pow(1 - progress, 3);
    const current = Math.floor(start + (target - start) * eased);
    
    countEl.textContent = current;
    
    if (progress < 1) {
      requestAnimationFrame(update);
    }
  }
  
  requestAnimationFrame(update);
}

// Handle form submission
async function handleSubmit(e, emailInput, messageEl) {
  e.preventDefault();
  
  const email = emailInput.value.trim();
  const btn = e.target.querySelector('button');
  const btnText = btn.querySelector('.btn-text');
  const btnLoader = btn.querySelector('.btn-loader');
  
  if (!email) return;
  
  // Show loading
  btn.disabled = true;
  if (btnText) btnText.style.display = 'none';
  if (btnLoader) btnLoader.style.display = 'flex';
  
  try {
    const res = await fetch('/api/subscribe', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email })
    });
    
    const data = await res.json();
    
    if (data.success) {
      messageEl.textContent = data.message;
      messageEl.className = 'form-message success';
      emailInput.value = '';
      showToast('Bienvenue sur la waitlist !', 'success');
      // Increment count optimistically
      const current = parseInt(countEl.textContent) || 0;
      countEl.textContent = current + 1;
    } else {
      messageEl.textContent = data.error || 'Une erreur est survenue';
      messageEl.className = 'form-message error';
      showToast(data.error || 'Erreur', 'error');
    }
  } catch (err) {
    messageEl.textContent = 'Erreur de connexion. Réessaie.';
    messageEl.className = 'form-message error';
    showToast('Erreur de connexion', 'error');
  } finally {
    // Hide loading
    btn.disabled = false;
    if (btnText) btnText.style.display = 'inline';
    if (btnLoader) btnLoader.style.display = 'none';
  }
}

// Show toast notification
function showToast(message, type = 'info') {
  toast.textContent = message;
  toast.className = `toast ${type} show`;
  
  setTimeout(() => {
    toast.classList.remove('show');
  }, 4000);
}

// Event listeners
form1.addEventListener('submit', (e) => handleSubmit(e, email1, message1));
form2.addEventListener('submit', (e) => handleSubmit(e, email2, message2));

// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
  anchor.addEventListener('click', function(e) {
    e.preventDefault();
    const target = document.querySelector(this.getAttribute('href'));
    if (target) {
      target.scrollIntoView({ behavior: 'smooth' });
    }
  });
});
