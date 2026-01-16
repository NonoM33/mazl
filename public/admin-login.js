const STORAGE_KEY = 'mazl_admin_token';
const EMAIL_KEY = 'mazl_admin_email';

function redirectToDashboard() {
  window.location.href = '/admin/dashboard';
}

async function checkExistingSession() {
  const token = localStorage.getItem(STORAGE_KEY);
  if (!token) return;

  // Verify token is still valid
  const res = await fetch('/api/admin/verify', {
    headers: { 'Authorization': `Bearer ${token}` },
  });

  if (res.ok) {
    redirectToDashboard();
  } else {
    // Token expired or invalid
    localStorage.removeItem(STORAGE_KEY);
    localStorage.removeItem(EMAIL_KEY);
  }
}

const form = document.getElementById('login-form');
const errorEl = document.getElementById('login-error');
const submitBtn = document.getElementById('btn-submit');

form.addEventListener('submit', async (e) => {
  e.preventDefault();

  const email = document.getElementById('email').value.trim();
  const password = document.getElementById('password').value;

  // Disable button during request
  submitBtn.disabled = true;
  submitBtn.textContent = 'Connexion...';
  errorEl.style.display = 'none';

  try {
    const res = await fetch('/api/admin/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });

    const data = await res.json();

    if (!res.ok || !data.success) {
      throw new Error(data.error || 'Identifiants incorrects');
    }

    // Store token and redirect
    localStorage.setItem(STORAGE_KEY, data.token);
    localStorage.setItem(EMAIL_KEY, email);
    redirectToDashboard();

  } catch (err) {
    errorEl.textContent = err.message;
    errorEl.style.display = 'block';
  } finally {
    submitBtn.disabled = false;
    submitBtn.textContent = 'Se connecter';
  }
});

// Check for existing session on page load
checkExistingSession().catch(() => {
  // ignore errors, just stay on login page
});
