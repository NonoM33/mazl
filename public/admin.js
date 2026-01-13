const toast = document.getElementById('toast');
const listEl = document.getElementById('admin-list');
const errEl = document.getElementById('admin-error');

function showToast(message, type = 'info') {
  toast.textContent = message;
  toast.className = `toast ${type} show`;
  setTimeout(() => toast.classList.remove('show'), 4000);
}

function qs(name) {
  return new URLSearchParams(window.location.search).get(name);
}

const STORAGE_KEY = 'mzl_admin_password';

// Backward compatibility: if password in query, store it then clean URL.
const passwordFromQuery = qs('password');
if (passwordFromQuery) {
  localStorage.setItem(STORAGE_KEY, passwordFromQuery);
  const cleaned = new URL(window.location.href);
  cleaned.searchParams.delete('password');
  window.history.replaceState({}, '', cleaned.toString());
}

const password = localStorage.getItem(STORAGE_KEY);
const showRejected = qs('showRejected') === '1';

const toggleEl = document.getElementById('admin-toggle');
if (toggleEl) {
  const base = new URL(window.location.href);
  if (!password) {
    toggleEl.innerHTML = 'Session expirée. <a href="/admin">Se reconnecter</a>';
  } else {
    if (showRejected) {
      base.searchParams.delete('showRejected');
      toggleEl.innerHTML = `Mode: <strong>historique ON</strong> — <a href="${base.toString()}">Masquer les refusés</a>`;
    } else {
      base.searchParams.set('showRejected', '1');
      toggleEl.innerHTML = `Mode: <strong>historique OFF</strong> — <a href="${base.toString()}">Afficher les refusés</a>`;
    }
  }
}

const logoutBtn = document.getElementById('admin-logout');
if (logoutBtn) {
  logoutBtn.addEventListener('click', () => {
    localStorage.removeItem(STORAGE_KEY);
    window.location.href = '/admin';
  });
}

function api(path, options = {}) {
  const url = new URL(path, window.location.origin);
  const headers = new Headers(options.headers || {});
  if (password) headers.set('x-admin-password', password);

  return fetch(url.toString(), {
    ...options,
    headers,
  });
}

function render(items) {
  listEl.innerHTML = '';

  if (!items.length) {
    listEl.innerHTML = '<div class="muted">Rien à valider.</div>';
    return;
  }

  for (const item of items) {
    const card = document.createElement('div');
    card.className = 'admin-card';

    const docs = (item.documents || [])
      .filter((d) => showRejected || d.status !== 'rejected')
      .map((d) => {
        const fileUrl = new URL(`/api/admin/documents/${d.id}/file`, window.location.origin);
        // Images/PDF previews can't send headers, so we pass password in query for this endpoint only.
        if (password) fileUrl.searchParams.set('password', password);

        const isImage = (d.mimeType || '').startsWith('image/');
        const preview = isImage
          ? `<img class="doc-thumb" src="${fileUrl.toString()}" alt="${d.type}" />`
          : `<a class="doc-link" href="${fileUrl.toString()}" target="_blank">Ouvrir ${d.type}</a>`;

        return `<div class="doc-item ${d.status}">
          <div class="doc-label">${d.type} <span class="doc-status">(${d.status})</span></div>
          ${preview}
        </div>`;
      })
      .join('');

    card.innerHTML = `
      <div class="admin-row">
        <div>
          <div class="admin-email">${item.email}</div>
          <div class="muted">status: ${item.verificationStatus}</div>
        </div>
        <div class="admin-actions">
          <button class="btn btn-primary" data-action="approve">Valider profil</button>
          <button class="btn" data-action="reupload">Demander re-upload</button>
        </div>
      </div>
      <div class="admin-docs-grid">${docs || '<span class="muted">aucun doc</span>'}</div>
    `;

    // Profile actions
    const approveBtn = card.querySelector('[data-action="approve"]');
    const reuploadBtn = card.querySelector('[data-action="reupload"]');

    approveBtn.addEventListener('click', async () => {
      const res = await api(`/api/admin/profiles/${item.waitlistId}/approve`, { method: 'POST' });
      const data = await res.json();
      if (!data.success) {
        showToast(data.error || 'Erreur', 'error');
        return;
      }
      showToast('Profil validé', 'success');
      load();
    });

    reuploadBtn.addEventListener('click', async () => {
      const notes = prompt('Motif / instruction pour re-upload (obligatoire)') || '';
      if (!notes.trim()) {
        showToast('Motif requis', 'error');
        return;
      }
      const res = await api(`/api/admin/profiles/${item.waitlistId}/request-reupload`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ notes }),
      });
      const data = await res.json();
      if (!data.success) {
        showToast(data.error || 'Erreur', 'error');
        return;
      }
      showToast('Re-upload demandé', 'success');
      load();
    });

    // Per-document actions
    const actions = document.createElement('div');
    actions.className = 'admin-actions-row';

    for (const d of item.documents || []) {
      const approve = document.createElement('button');
      approve.className = 'btn btn-primary';
      approve.textContent = `Approuver ${d.type}`;
      approve.addEventListener('click', async () => {
        await api(`/api/admin/documents/${d.id}/approve`, { method: 'POST' });
        showToast('Approuvé', 'success');
        load();
      });

      const reject = document.createElement('button');
      reject.className = 'btn';
      reject.textContent = `Rejeter ${d.type}`;
      reject.addEventListener('click', async () => {
        const notes = prompt('Motif (optionnel)') || '';
        await api(`/api/admin/documents/${d.id}/reject`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ notes }),
        });
        showToast('Rejeté', 'error');
        load();
      });

      actions.appendChild(approve);
      actions.appendChild(reject);
    }

    card.appendChild(actions);
    listEl.appendChild(card);
  }
}

async function load() {
  errEl.style.display = 'none';

  if (!password) {
    window.location.href = '/admin';
    return;
  }

  const res = await api('/api/admin/pending');
  const data = await res.json();

  if (!data.success) {
    errEl.textContent = data.error || 'Erreur.';
    errEl.style.display = 'block';
    return;
  }

  render(data.items || []);
}

load().catch((e) => {
  console.error(e);
  showToast('Erreur chargement', 'error');
});
