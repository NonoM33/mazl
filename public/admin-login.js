const STORAGE_KEY = 'mzl_admin_password';

function redirectToDashboard() {
  window.location.href = '/admin/dashboard';
}

async function checkExistingSession() {
  const password = localStorage.getItem(STORAGE_KEY);
  if (!password) return;

  // Quick check
  const res = await fetch('/api/admin/pending', {
    headers: { 'x-admin-password': password },
  });

  if (res.ok) {
    redirectToDashboard();
  } else {
    localStorage.removeItem(STORAGE_KEY);
  }
}

const form = document.getElementById('login-form');
const errorEl = document.getElementById('login-error');

form.addEventListener('submit', async (e) => {
  e.preventDefault();

  const password = document.getElementById('password').value;

  const res = await fetch('/api/admin/pending', {
    headers: { 'x-admin-password': password },
  });

  if (!res.ok) {
    errorEl.textContent = 'Mot de passe incorrect.';
    errorEl.style.display = 'block';
    return;
  }

  localStorage.setItem(STORAGE_KEY, password);
  redirectToDashboard();
});

checkExistingSession().catch(() => {
  // ignore
});
