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

const password = qs('password');

function api(path, options) {
  const url = new URL(path, window.location.origin);
  if (password) url.searchParams.set('password', password);
  return fetch(url.toString(), options);
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

    const docs = (item.documents || []).map((d) => {
      const fileUrl = new URL(`/api/admin/documents/${d.id}/file`, window.location.origin);
      if (password) fileUrl.searchParams.set('password', password);
      return `<a class="doc-link" href="${fileUrl.toString()}" target="_blank">${d.type}</a>`;
    }).join(' ');

    card.innerHTML = `
      <div class="admin-row">
        <div>
          <div class="admin-email">${item.email}</div>
          <div class="muted">status: ${item.verificationStatus}</div>
          <div class="admin-docs">${docs || '<span class="muted">aucun doc</span>'}</div>
        </div>
        <div class="admin-actions">
          <button class="btn" data-action="refresh">Rafraîchir</button>
        </div>
      </div>
    `;

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
    errEl.textContent = 'Ajoute ?password=... dans l’URL.';
    errEl.style.display = 'block';
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
