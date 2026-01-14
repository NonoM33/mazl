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

const uploadState = {
  selfie_id: false,
  id_card_front: false,
  id_card_back: false,
  community_doc: false,
};

function setSubmitEnabled(enabled) {
  const btn = document.getElementById('btn-submit');
  btn.disabled = !enabled;
}

function updateSubmitButton() {
  const osSelected = document.querySelector('input[name="os"]:checked');
  const ready = uploadState.selfie_id && uploadState.id_card_front && uploadState.id_card_back && osSelected;
  setSubmitEnabled(ready);
}

async function loadStatus() {
  if (!token) {
    statusEl.innerHTML = '<div class="alert error">Lien invalide (token manquant).</div>';
    setSubmitEnabled(false);
    return null;
  }

  const res = await fetch(`/api/verify?token=${encodeURIComponent(token)}`);
  const data = await res.json();
  if (!data.success) {
    statusEl.innerHTML = `<div class="alert error">${data.error || 'Lien invalide.'}</div>`;
    setSubmitEnabled(false);
    return null;
  }

  statusEl.innerHTML = `<div class="alert success">Connecté en tant que : <strong>${data.email}</strong></div>`;

  const missing = Array.isArray(data.missing) ? data.missing : [];
  uploadState.selfie_id = !missing.includes('selfie_id');
  uploadState.id_card_front = !missing.includes('id_card_front');
  uploadState.id_card_back = !missing.includes('id_card_back');

  if (data.os) {
    const radio = document.querySelector(`input[name="os"][value="${data.os}"]`);
    if (radio) radio.checked = true;
  }

  return data;
}

function renderPreview(file, previewEl) {
  previewEl.innerHTML = '';
  if (!file) return;

  const isImage = file.type.startsWith('image/');
  if (isImage) {
    const img = document.createElement('img');
    img.className = 'upload-thumb-modern';
    img.src = URL.createObjectURL(file);
    img.onload = () => URL.revokeObjectURL(img.src);
    previewEl.appendChild(img);
    return;
  }

  const p = document.createElement('div');
  p.className = 'doc-pill';
  p.textContent = `📄 ${file.name}`;
  previewEl.appendChild(p);
}

async function upload(type, fileInput, msgEl, previewEl) {
  msgEl.textContent = '';
  const file = fileInput.files?.[0];
  renderPreview(file, previewEl);
  if (!file) return;

  const fd = new FormData();
  fd.append('type', type);
  fd.append('file', file);

  msgEl.textContent = 'Upload en cours...';
  msgEl.className = 'upload-msg progress';

  try {
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

    msgEl.textContent = 'Téléchargé avec succès ✅';
    msgEl.className = 'upload-msg success';
    uploadState[type] = true;
    updateSubmitButton();
    showToast('Document enregistré', 'success');
  } catch (err) {
    msgEl.textContent = 'Erreur réseau.';
    msgEl.className = 'upload-msg error';
  }
}

async function submitAll() {
  const btn = document.getElementById('btn-submit');
  const btnText = btn.querySelector('.btn-text');
  const btnLoader = btn.querySelector('.btn-loader');
  const os = document.querySelector('input[name="os"]:checked')?.value;

  btn.disabled = true;
  btnText.style.display = 'none';
  btnLoader.style.display = 'inline-block';

  try {
    const res = await fetch(`/api/verify/submit?token=${encodeURIComponent(token)}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ os })
    });
    const data = await res.json();

    if (!data.success) {
      showToast(data.error || 'Erreur lors de l’envoi.', 'error');
      btn.disabled = false;
      btnText.style.display = 'inline';
      btnLoader.style.display = 'none';
      return;
    }

    document.querySelector('.stepper-form').innerHTML = `
      <div class="success-screen text-center py-xl">
        <div class="success-icon mb-lg">✅</div>
        <h1 class="mb-md">Documents reçus !</h1>
        <p class="subtitle mb-xl">Merci ! Notre équipe va vérifier ton profil. Tu recevras un email dès que c'est validé.</p>
        <a href="/" class="btn btn-primary btn-lg">Retour à l'accueil</a>
      </div>
    `;
    showToast('Dossier soumis avec succès', 'success');
  } catch (err) {
    showToast('Erreur de connexion', 'error');
    btn.disabled = false;
    btnText.style.display = 'inline';
    btnLoader.style.display = 'none';
  }
}

// Auto-upload on change
document.getElementById('file-selfie').addEventListener('change', (e) => {
  upload('selfie_id', e.target, document.getElementById('msg-selfie'), document.getElementById('preview-selfie'));
});
document.getElementById('file-id-front').addEventListener('change', (e) => {
  upload('id_card_front', e.target, document.getElementById('msg-id-front'), document.getElementById('preview-id-front'));
});
document.getElementById('file-id-back').addEventListener('change', (e) => {
  upload('id_card_back', e.target, document.getElementById('msg-id-back'), document.getElementById('preview-id-back'));
});
document.getElementById('file-community').addEventListener('change', (e) => {
  upload('community_doc', e.target, document.getElementById('msg-community'), document.getElementById('preview-community'));
});

// OS change
document.querySelectorAll('input[name="os"]').forEach(radio => {
  radio.addEventListener('change', updateSubmitButton);
});

document.getElementById('btn-submit').addEventListener('click', submitAll);

loadStatus()
  .then(() => updateSubmitButton())
  .catch((e) => {
    console.error(e);
    showToast('Erreur de chargement', 'error');
  });
