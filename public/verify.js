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

function setSubmitEnabled(enabled) {
  const btn = document.getElementById('btn-submit');
  btn.disabled = !enabled;
}

async function loadStatus() {
  if (!token) {
    statusEl.textContent = 'Lien invalide (token manquant).';
    statusEl.className = 'verify-status error';
    setSubmitEnabled(false);
    return null;
  }

  const res = await fetch(`/api/verify?token=${encodeURIComponent(token)}`);
  const data = await res.json();
  if (!data.success) {
    statusEl.textContent = data.error || 'Lien invalide.';
    statusEl.className = 'verify-status error';
    setSubmitEnabled(false);
    return null;
  }

  statusEl.textContent = `Email: ${data.email}`;
  statusEl.className = 'verify-status success';

  const missing = Array.isArray(data.missing) ? data.missing : [];
  uploadState.selfie_id = !missing.includes('selfie_id');
  uploadState.id_card_front = !missing.includes('id_card_front');
  uploadState.id_card_back = !missing.includes('id_card_back');

  return data;
}

function renderPreview(file, previewEl) {
  previewEl.innerHTML = '';
  if (!file) return;

  const isImage = file.type.startsWith('image/');
  if (isImage) {
    const img = document.createElement('img');
    img.className = 'upload-thumb';
    img.src = URL.createObjectURL(file);
    img.onload = () => URL.revokeObjectURL(img.src);
    previewEl.appendChild(img);
    return;
  }

  const p = document.createElement('div');
  p.className = 'muted';
  p.textContent = `Fichier: ${file.name}`;
  previewEl.appendChild(p);
}

const uploadState = {
  selfie_id: false,
  id_card_front: false,
  id_card_back: false,
  community_doc: false,
};

function updateSubmitButton() {
  const ready = uploadState.selfie_id && uploadState.id_card_front && uploadState.id_card_back;
  setSubmitEnabled(ready);
}

async function upload(type, fileInput, msgEl, previewEl) {
  msgEl.textContent = '';
  const file = fileInput.files?.[0];
  renderPreview(file, previewEl);
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
  uploadState[type] = true;
  updateSubmitButton();
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
  upload(
    'selfie_id',
    document.getElementById('file-selfie'),
    document.getElementById('msg-selfie'),
    document.getElementById('preview-selfie'),
  );
});

document.getElementById('btn-id-front').addEventListener('click', () => {
  upload(
    'id_card_front',
    document.getElementById('file-id-front'),
    document.getElementById('msg-id-front'),
    document.getElementById('preview-id-front'),
  );
});

document.getElementById('btn-id-back').addEventListener('click', () => {
  upload(
    'id_card_back',
    document.getElementById('file-id-back'),
    document.getElementById('msg-id-back'),
    document.getElementById('preview-id-back'),
  );
});

document.getElementById('btn-community').addEventListener('click', () => {
  upload(
    'community_doc',
    document.getElementById('file-community'),
    document.getElementById('msg-community'),
    document.getElementById('preview-community'),
  );
});

document.getElementById('btn-submit').addEventListener('click', submitAll);

loadStatus()
  .then(() => {
    updateSubmitButton();
  })
  .catch((e) => {
    console.error(e);
    showToast('Erreur de chargement', 'error');
  });
