const toast = document.getElementById('toast');

function showToast(message, type = 'info') {
  toast.textContent = message;
  toast.className = `toast ${type} show`;
  setTimeout(() => toast.classList.remove('show'), 4000);
}

function qs(name) {
  return new URLSearchParams(window.location.search).get(name);
}

const token = qs('token');
const statusEl = document.getElementById('verify-status');

async function loadStatus() {
  if (!token) {
    statusEl.textContent = 'Lien invalide (token manquant).';
    statusEl.className = 'verify-status error';
    return;
  }

  const res = await fetch(`/api/verify?token=${encodeURIComponent(token)}`);
  const data = await res.json();
  if (!data.success) {
    statusEl.textContent = data.error || 'Lien invalide.';
    statusEl.className = 'verify-status error';
    return;
  }

  statusEl.textContent = `Email: ${data.email}`;
  statusEl.className = 'verify-status success';
}

async function upload(type, fileInput, msgEl) {
  msgEl.textContent = '';
  const file = fileInput.files?.[0];
  if (!file) {
    msgEl.textContent = 'Choisis un fichier.';
    msgEl.className = 'upload-msg error';
    return;
  }

  const fd = new FormData();
  fd.append('type', type);
  fd.append('file', file);

  msgEl.textContent = 'Upload en cours…';
  msgEl.className = 'upload-msg';

  const res = await fetch(`/api/verify/upload?token=${encodeURIComponent(token)}`, {
    method: 'POST',
    body: fd,
  });

  const data = await res.json();
  if (!data.success) {
    msgEl.textContent = data.error || 'Erreur upload.';
    msgEl.className = 'upload-msg error';
    showToast(msgEl.textContent, 'error');
    return;
  }

  msgEl.textContent = 'OK ✅';
  msgEl.className = 'upload-msg success';
  showToast('Document uploadé', 'success');
}

async function submitAll() {
  const msg = document.getElementById('msg-submit');
  msg.textContent = 'Envoi…';
  msg.className = 'upload-msg';

  const res = await fetch(`/api/verify/submit?token=${encodeURIComponent(token)}`, { method: 'POST' });
  const data = await res.json();

  if (!data.success) {
    msg.textContent = data.error || 'Erreur.';
    msg.className = 'upload-msg error';
    showToast(msg.textContent, 'error');
    return;
  }

  msg.textContent = 'Merci ! On te répond vite.';
  msg.className = 'upload-msg success';
  showToast('Soumis pour validation', 'success');
}

document.getElementById('btn-selfie').addEventListener('click', () => {
  upload('selfie_id', document.getElementById('file-selfie'), document.getElementById('msg-selfie'));
});

document.getElementById('btn-id').addEventListener('click', () => {
  upload('id_card', document.getElementById('file-id'), document.getElementById('msg-id'));
});

document.getElementById('btn-community').addEventListener('click', () => {
  upload('community_doc', document.getElementById('file-community'), document.getElementById('msg-community'));
});

document.getElementById('btn-submit').addEventListener('click', submitAll);

loadStatus().catch((e) => {
  console.error(e);
  showToast('Erreur de chargement', 'error');
});
