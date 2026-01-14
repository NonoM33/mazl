const toast = document.getElementById('toast');
const listEl = document.getElementById('admin-list');
const errEl = document.getElementById('admin-error');
const modalEl = document.getElementById('modal');
const modalReasonEl = document.getElementById('modal-reason');
const modalConfirmEl = document.getElementById('modal-confirm');
const modalSubtitleEl = document.getElementById('modal-subtitle');

const STORAGE_KEY = 'mazl_admin_password';

function showToast(message, type = 'info') {
  toast.textContent = message;
  toast.className = `toast ${type} show`;
  setTimeout(() => toast.classList.remove('show'), 4000);
}

function qs(name) {
  return new URLSearchParams(window.location.search).get(name);
}

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
let currentTab = 'pending';

const toggleEl = document.getElementById('admin-toggle');
if (toggleEl) {
  const base = new URL(window.location.href);
  if (!password) {
    toggleEl.innerHTML = 'Session expirée. <a href="/admin">Se reconnecter</a>';
  } else {
    if (showRejected) {
      base.searchParams.delete('showRejected');
      toggleEl.innerHTML = `Mode: <strong>Historique ON</strong> — <a href="${base.toString()}">Masquer refusés</a>`;
    } else {
      base.searchParams.set('showRejected', '1');
      toggleEl.innerHTML = `Mode: <strong>Historique OFF</strong> — <a href="${base.toString()}">Afficher refusés</a>`;
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

function openModal({ title, subtitle, onConfirm }) {
  modalEl.querySelector('h2').textContent = title;
  modalSubtitleEl.textContent = subtitle || '';
  modalReasonEl.value = '';
  modalEl.classList.remove('hidden');

  const close = () => {
    modalEl.classList.add('hidden');
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
    listEl.innerHTML = `
      <div class="text-center py-xl bg-white border-radius-24 shadow-sm">
        <div style="font-size: 48px;">✨</div>
        <h3 class="mt-md">Rien à afficher ici</h3>
        <p class="muted">Tous les dossiers ont été traités.</p>
      </div>
    `;
    return;
  }

  for (const item of items) {
    const card = document.createElement('div');
    card.className = 'admin-card mb-md';

    const docs = (item.documents || [])
      .filter((d) => showRejected || d.status !== 'rejected')
      .map((d) => {
        const fileUrl = new URL(`/api/admin/documents/${d.id}/file`, window.location.origin);
        if (password) fileUrl.searchParams.set('password', password);

        const isImage = (d.mimeType || '').startsWith('image/');
        const preview = isImage
          ? `<img class="doc-thumb" src="${fileUrl.toString()}" alt="${d.type}" onclick="window.open('${fileUrl.toString()}')" style="cursor:zoom-in" />`
          : `<a class="doc-link" href="${fileUrl.toString()}" target="_blank">📄 ${d.type}</a>`;

        return `
          <div class="doc-item ${d.status}" data-doc-id="${d.id}" data-doc-type="${d.type}">
            ${currentTab === 'pending' ? '<input class="doc-check" type="checkbox" />' : ''}
            <div class="doc-label">${d.type}</div>
            ${preview}
            <div class="doc-status mt-sm">${d.status}</div>
          </div>`;
      })
      .join('');

    const osBadge = item.os 
      ? `<span class="admin-os-badge ${item.os}">${item.os === 'ios' ? '🍎 iOS' : '🤖 Android'}</span>`
      : '';

    const actionsHtml = currentTab === 'pending' ? `
      <div class="admin-actions-inline">
        <button class="btn btn-sm" data-action="approve-selected">Approuver docs</button>
        <button class="btn btn-sm" data-action="reject-selected">Refuser docs</button>
        <button class="btn btn-primary btn-sm" data-action="approve-profile">Valider profil ✅</button>
      </div>
    ` : `
      <div class="admin-actions-inline">
        <span class="doc-pill success">Profil Validé</span>
      </div>
    `;

    card.innerHTML = `
      <div class="admin-row mb-md">
        <div>
          <div class="admin-email">${item.email} ${osBadge}</div>
          <div class="muted" style="font-size:12px;">Waitlist ID: ${item.waitlistId} • Status: ${item.verificationStatus}</div>
        </div>
        ${actionsHtml}
      </div>
      <div class="admin-docs-grid">${docs || '<span class="muted">aucun doc</span>'}</div>
    `;

    if (currentTab === 'pending') {
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

      docsGrid.addEventListener('change', (e) => {
        if (e.target.classList.contains('doc-check')) {
          e.target.closest('.doc-item').classList.toggle('selected', e.target.checked);
        }
      });

      card.querySelector('[data-action="approve-selected"]').addEventListener('click', async () => {
        const selected = getSelectedDocumentIds();
        if (!selected.length) return showToast('Sélectionne au moins 1 doc', 'error');
        const res = await api(`/api/admin/profiles/${item.waitlistId}/review`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ approveDocumentIds: selected }),
        });
        if (res.ok) { showToast('Docs approuvés', 'success'); load(); }
      });

      card.querySelector('[data-action="reject-selected"]').addEventListener('click', async () => {
        const selected = getSelectedDocumentIds();
        if (!selected.length) return showToast('Sélectionne au moins 1 doc', 'error');
        openModal({
          title: 'Refuser des documents',
          subtitle: `L'utilisateur recevra un email pour re-télécharger ${selected.length} document(s).`,
          onConfirm: async (reason) => {
            const res = await api(`/api/admin/profiles/${item.waitlistId}/review`, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ rejectDocumentIds: selected, reason }),
            });
            if (res.ok) { showToast('Email de refus envoyé', 'success'); load(); }
          },
        });
      });

      card.querySelector('[data-action="approve-profile"]').addEventListener('click', async () => {
        const selected = getSelectedDocumentIds();
        const res = await api(`/api/admin/profiles/${item.waitlistId}/review`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ approveDocumentIds: selected, approveProfile: true }),
        });
        if (res.ok) { showToast('Profil validé ! Email envoyé.', 'success'); load(); }
        else { const d = await res.json(); showToast(d.error || 'Erreur', 'error'); }
      });
    }

    listEl.appendChild(card);
  }
}

async function load() {
  errEl.style.display = 'none';
  if (!password) { window.location.href = '/admin'; return; }

  const endpoint = currentTab === 'pending' ? '/api/admin/pending' : '/api/admin/verified';
  const res = await api(endpoint);
  const data = await res.json();

  if (!data.success) {
    errEl.innerHTML = `<div class="alert error">${data.error || 'Erreur lors du chargement.'}</div>`;
    errEl.style.display = 'block';
    return;
  }

  render(data.items || []);
}

// Tab handling
document.querySelectorAll('.tab-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    currentTab = btn.dataset.tab;
    load();
  });
});

load().catch((e) => {
  console.error(e);
  showToast('Erreur chargement', 'error');
});
