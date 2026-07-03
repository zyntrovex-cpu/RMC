// ── API Client ──────────────────────────────────────────────
const API_BASE = window.API_BASE || (window.location.pathname.replace(/\/admin\/.*$/, '/backend'));

const Api = {
  token: () => localStorage.getItem('rmc_token'),

  headers() {
    const h = { 'Content-Type': 'application/json' };
    if (this.token()) h['Authorization'] = 'Bearer ' + this.token();
    return h;
  },

  async request(method, path, body = null) {
    const opts = { method, headers: this.headers() };
    if (body) opts.body = JSON.stringify(body);
    const res = await fetch(API_BASE + path, opts);
    const data = await res.json();
    if (!res.ok) throw data;
    return data;
  },

  get:    (path)        => Api.request('GET',    path),
  post:   (path, body)  => Api.request('POST',   path, body),
  put:    (path, body)  => Api.request('PUT',    path, body),
  delete: (path)        => Api.request('DELETE', path),

  // Auth
  login:          (mobile, password) => Api.post('/auth?action=login', { mobile, password }),
  me:             ()                => Api.get('/auth?action=me'),
  changePassword: (d)               => Api.post('/auth?action=change-password', d),

  // Sectors
  sectors:        ()   => Api.get('/sectors'),
  sectorStats:    ()   => Api.get('/sectors?action=stats'),
  sectorStreets:  (id) => Api.get(`/sectors/${id}?action=streets`),

  // Properties
  properties:    (params = {}) => Api.get('/properties?' + new URLSearchParams(params)),
  property:      (id)          => Api.get(`/properties/${id}`),
  createProperty:(d)           => Api.post('/properties', d),
  updateProperty:(id, d)       => Api.put(`/properties/${id}`, d),
  transferOwner: (id, d)       => Api.post(`/properties/${id}/transfer`, d),
  ownerHistory:  (id)          => Api.get(`/properties/${id}/history`),

  // Users
  users:         (params = {}) => Api.get('/users?' + new URLSearchParams(params)),
  user:          (id)          => Api.get(`/users/${id}`),
  createUser:    (d)           => Api.post('/users', d),
  updateUser:    (id, d)       => Api.put(`/users/${id}`, d),
  resetPassword: (id)          => Api.post(`/users/${id}/reset-password`),

  // Accounts
  accounts:      ()       => Api.get('/accounts'),
  createAccount: (d)      => Api.post('/accounts', d),
  updateAccount: (id, d)  => Api.put(`/accounts/${id}`, d),

  // Challans
  challans:         (params = {}) => Api.get('/challans?' + new URLSearchParams(params)),
  challan:          (id)          => Api.get(`/challans/${id}`),
  challanDashboard: (month)       => Api.get('/challans?action=dashboard&month=' + month),
  defaulters:       ()            => Api.get('/challans?action=defaulters'),
  generateBatch:    (month)       => Api.post('/challans?action=generate-batch', { month }),
  cancelChallan:    (id, reason)  => Api.post(`/challans/${id}/cancel`, { reason }),

  // Payments
  payments:           (params = {}) => Api.get('/payments?' + new URLSearchParams(params)),
  payManual:          (d)           => Api.post('/payments?action=manual', d),
  recordPayment:      (d)           => Api.post('/payments?action=manual', d),
  getPayments:        (params = {}) => Api.get('/payments?' + new URLSearchParams(params)),
  getChallanByNo:     (no)          => Api.get('/challans?action=by-number&challan_no=' + encodeURIComponent(no)),

  // Reports
  reportMonthly:    (month)      => Api.get('/reports?action=monthly&month=' + month),
  reportSector:     (month)      => Api.get('/reports?action=sector&month=' + month),
  reportHouse:      (propertyId) => Api.get('/reports?action=house&property_id=' + propertyId),
  reportDefaulters: ()           => Api.get('/reports?action=defaulters'),
  reportArrears:    ()           => Api.get('/reports?action=arrears'),
  reportAnnual:     (year)       => Api.get('/reports?action=annual&year=' + year),

  // Complaints
  getComplaints:   (params = {}) => Api.get('/complaints?' + new URLSearchParams(params)),
  getComplaint:    (id)          => Api.get(`/complaints/${id}`),
  updateComplaint: (id, d)       => Api.put(`/complaints/${id}`, d),
  addComment:      (id, d)       => Api.post(`/complaints/${id}/comments`, d),

  // Announcements
  getAnnouncements:  (params = {}) => Api.get('/announcements?' + new URLSearchParams(params)),
  createAnnouncement:(d)           => Api.post('/announcements', d),
  deleteAnnouncement:(id)          => Api.delete(`/announcements/${id}`),

  // NOC
  getNocRequests: (params = {}) => Api.get('/noc?' + new URLSearchParams(params)),
  getNocDetail:   (id)          => Api.get(`/noc/${id}`),
  approveNoc:     (id, d)       => Api.post(`/noc/${id}?action=approve`, d),
  rejectNoc:      (id, d)       => Api.post(`/noc/${id}?action=reject`, d),

  // Aliased helpers
  getUsers:            (params={}) => Api.get('/users?' + new URLSearchParams(params)),
  getAccounts:         ()          => Api.get('/accounts'),
  getAccountRateHistory: ()        => Api.get('/accounts?action=rate-history'),
  resetUserPassword:   (id, d)     => Api.post(`/users/${id}/reset-password`, d),

  // Cron / Settings
  getCronLog: () => Api.get('/settings?action=cron-log'),
  runCron:    () => Api.post('/settings?action=run-cron', {}),

  base: API_BASE,
};
