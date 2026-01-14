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

const STORAGE_KEY = 'mazl_admin_password';

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

const modalEl = document.getElementById('modal');
const modalReasonEl = document.getElementById('modal-reason');
const modalConfirmEl = document.getElementById('modal-confirm');
const modalSubtitleEl = document.getElementById('modal-subtitle');

function openModal({ title, subtitle, onConfirm }) {
  modalEl.querySelector('#modal-title').textContent = title;
  modalSubtitleEl.textContent = subtitle || '';
  modalReasonEl.value = '';
  modalEl.classList.remove('hidden');
  modalEl.setAttribute('aria-hidden', 'false');

  const close = () => {
    modalEl.classList.add('hidden');
    modalEl.setAttribute('aria-hidden', 'true');
    modalConfirmEl.onclick = null;
  };

  modalEl.querySelectorAll('[data-modal-close]').forEach((el) => {
    el.onclick = close;
  });

  modalConfirmEl.onclick = async () => {
    const reason = (modalReasonEl.value || '').trim();
    if (!reason) {
      showToast('Motif requis', 'error');
      return;
    }
    await onConfirm(reason);
    close();
  };
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

        return `<div class="doc-item ${d.status}" data-doc-id="${d.id}" data-doc-type="${d.type}">
          <input class="doc-check" type="checkbox" />
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
        <div class="admin-actions-inline">
          <button class="btn" data-action="approve-selected">Approuver docs</button>
          <button class="btn" data-action="reject-selected">Refuser docs</button>
          <button class="btn btn-primary" data-action="approve-profile">Valider profil</button>
        </div>
      </div>
      <div class="admin-docs-grid">${docs || '<span class="muted">aucun doc</span>'}</div>
    `;

    const docsGrid = card.querySelector('.admin-docs-grid');

    const getSelectedDocumentIds = () => {
      const selected = [];
      for (const el of docsGrid.querySelectorAll('.doc-item')) {
        const cb = el.querySelector('.doc-check');
        if (cb && cb.checked) {
          selected.push(parseInt(el.dataset.docId, 10));
        }
      }
      return selected;
    };

    // Toggle selected style
    docsGrid.addEventListener('change', (e) => {
      const target = e.target;
      if (target && target.classList && target.classList.contains('doc-check')) {
        const itemEl = target.closest('.doc-item');
        if (itemEl) {
          itemEl.classList.toggle('selected', target.checked);
        }
      }
    });

    const approveSelectedBtn = card.querySelector('[data-action="approve-selected"]');
    const rejectSelectedBtn = card.querySelector('[data-action="reject-selected"]');
    const approveProfileBtn = card.querySelector('[data-action="approve-profile"]');

    approveSelectedBtn.addEventListener('click', async () => {
      const selected = getSelectedDocumentIds();
      if (!selected.length) {
        showToast('Sélectionne au moins 1 document', 'error');
        return;
      }

      const res = await api(`/api/admin/profiles/${item.waitlistId}/review`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ approveDocumentIds: selected }),
      });
      const data = await res.json();
      if (!data.success) {
        showToast(data.error || 'Erreur', 'error');
        return;
      }
      showToast('Documents approuvés', 'success');
      load();
    });

    rejectSelectedBtn.addEventListener('click', async () => {
      const selected = getSelectedDocumentIds();
      if (!selected.length) {
        showToast('Sélectionne au moins 1 document', 'error');
        return;
      }

      openModal({
        title: 'Refuser des documents',
        subtitle: 'Un email sera envoyé pour demander un re-upload.',
        onConfirm: async (reason) => {
          const res = await api(`/api/admin/profiles/${item.waitlistId}/review`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ rejectDocumentIds: selected, reason }),
          });
          const data = await res.json();
          if (!data.success) {
            showToast(data.error || 'Erreur', 'error');
            return;
          }
          showToast('Re-upload demandé (email envoyé)', 'success');
          load();
        },
      });
    });

    approveProfileBtn.addEventListener('click', async () => {
      const selected = getSelectedDocumentIds();
      const res = await api(`/api/admin/profiles/${item.waitlistId}/review`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ approveDocumentIds: selected, approveProfile: true }),
      });
      const data = await res.json();
      if (!data.success) {
        showToast(data.error || 'Erreur', 'error');
        return;
      }
      showToast('Profil validé (email envoyé)', 'success');
      load();
    });

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
