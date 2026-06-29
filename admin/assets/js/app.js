// ── App Shell ────────────────────────────────────────────────

const App = {
  user: null,

  async init() {
    const token = localStorage.getItem('rmc_token');
    if (!token) { this.redirect('login.html'); return; }

    try {
      const res  = await Api.me();
      this.user  = res.data;
      this.renderUser();
      this.highlightNav();
    } catch {
      localStorage.clear();
      this.redirect('login.html');
    }
  },

  redirect(page) {
    window.location.href = page;
  },

  renderUser() {
    const el = document.getElementById('user-avatar');
    if (el && this.user) {
      el.textContent = this.user.full_name.split(' ').map(w => w[0]).join('').slice(0,2).toUpperCase();
      el.title       = this.user.full_name + ' (' + this.user.role + ')';
    }
    const nameEl = document.getElementById('user-name');
    if (nameEl && this.user) nameEl.textContent = this.user.full_name;
    const adminEl = document.getElementById('adminName');
    if (adminEl && this.user) adminEl.textContent = this.user.full_name;
  },

  highlightNav() {
    const page = window.location.pathname.split('/').pop();
    document.querySelectorAll('#sidebar nav a, .sidebar-nav .nav-item').forEach(a => {
      a.classList.toggle('active', a.getAttribute('href') === page);
    });
  },

  logout() {
    localStorage.clear();
    window.location.href = 'login.html';
  },
};

// ── Toast ─────────────────────────────────────────────────────
function toast(msg, type = 'success') {
  let container = document.getElementById('toast-container');
  if (!container) {
    container = document.createElement('div');
    container.id = 'toast-container';
    document.body.appendChild(container);
  }
  const t = document.createElement('div');
  t.className = `toast toast-${type}`;
  t.textContent = msg;
  container.appendChild(t);
  setTimeout(() => t.remove(), 3500);
}

// ── Modal ─────────────────────────────────────────────────────
function openModal(id) {
  const el = document.getElementById(id);
  if (el) el.style.display = 'flex';
}
function closeModal(id) {
  const el = document.getElementById(id);
  if (el) el.style.display = 'none';
}

// ── Pagination (#sidebar layout) ─────────────────────────────
function renderPagination(containerId, meta, onPage) {
  const el = document.getElementById(containerId);
  if (!el) return;

  const from = (meta.page - 1) * meta.per_page + 1;
  const to   = Math.min(meta.page * meta.per_page, meta.total);

  el.innerHTML = `
    <span>Showing ${from}–${to} of ${meta.total}</span>
    <div class="pages">
      <button ${meta.page <= 1 ? 'disabled' : ''} onclick="(${onPage})(${meta.page - 1})">&#8249;</button>
      ${Array.from({length: meta.last_page}, (_,i) => i+1)
        .filter(p => Math.abs(p - meta.page) <= 2)
        .map(p => `<button class="${p === meta.page ? 'active' : ''}" onclick="(${onPage})(${p})">${p}</button>`)
        .join('')}
      <button ${meta.page >= meta.last_page ? 'disabled' : ''} onclick="(${onPage})(${meta.page + 1})">&#8250;</button>
    </div>
  `;
}

// ── Badge helper ───────────────────────────────────────────────
function statusBadge(status) {
  const map = {
    paid:    'badge-paid',    unpaid:  'badge-unpaid',
    partial: 'badge-partial', overdue: 'badge-overdue',
    waived:  'badge-waived',  active:  'badge-success',
    inactive:'badge-secondary',
  };
  return `<span class="badge ${map[status] || 'badge-secondary'}">${status}</span>`;
}

// ── Currency formatter ─────────────────────────────────────────
function pkr(val) {
  return parseFloat(val || 0).toLocaleString('en-PK', { minimumFractionDigits: 0 });
}

// ── Date formatter ─────────────────────────────────────────────
function fmtDate(d) {
  if (!d) return '—';
  return new Date(d).toLocaleDateString('en-PK', { day:'2-digit', month:'short', year:'numeric' });
}
