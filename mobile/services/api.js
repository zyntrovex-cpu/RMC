import axios from 'axios';

// Backend IP - change to your PC's Wi-Fi IP
const API_BASE = 'http://192.168.1.5/RMC/RMC/backend';

class ApiService {
  constructor() {
    this.token = null;
  }

  setToken(token) {
    this.token = token;
  }

  getHeaders() {
    return {
      'Content-Type': 'application/json',
      ...(this.token && { 'Authorization': `Bearer ${this.token}` })
    };
  }

  async request(method, path, data = null) {
    try {
      const config = {
        method,
        url: `${API_BASE}${path}`,
        headers: this.getHeaders(),
      };
      if (data) config.data = data;

      const response = await axios(config);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Network error' };
    }
  }

  // Auth endpoints
  login(mobile, password) {
    return this.request('POST', '/resident-auth?action=login', { mobile, password });
  }

  register(data) {
    return this.request('POST', '/resident-auth?action=register', data);
  }

  checkPlot(sector, plotNo) {
    return this.request('POST', '/resident-auth?action=check-plot', {
      sector_code: sector,
      plot_no: plotNo,
    });
  }

  sendOtp(mobile, propertyId) {
    return this.request('POST', '/resident-auth?action=send-otp', { mobile, property_id: propertyId });
  }

  forgotPassword(mobile) {
    return this.request('POST', '/resident-auth?action=forgot-password', { mobile });
  }

  resetPassword(data) {
    return this.request('POST', '/resident-auth?action=reset-password', data);
  }

  // Resident endpoints
  getDashboard() {
    return this.request('GET', '/resident?action=dashboard');
  }

  getProfile() {
    return this.request('GET', '/resident?action=profile');
  }

  getChallans() {
    return this.request('GET', '/resident?action=my-challans');
  }

  getVisitorPasses() {
    return this.request('GET', '/resident?action=my-visitor-passes');
  }

  createVisitorPass(data) {
    return this.request('POST', '/resident?action=create-visitor-pass', data);
  }

  cancelVisitorPass(id) {
    return this.request('POST', '/resident?action=cancel-visitor-pass', { pass_id: id });
  }

  getNocs() {
    return this.request('GET', '/resident?action=my-noc-requests');
  }

  getNocRequests() {
    return this.getNocs();
  }

  createNoc(data) {
    return this.request('POST', '/resident?action=request-noc', data);
  }

  requestNoc(purpose) {
    return this.request('POST', '/resident?action=request-noc', { purpose });
  }

  getComplaints() {
    return this.request('GET', '/resident?action=my-complaints');
  }

  createComplaint(data) {
    return this.request('POST', '/resident?action=submit-complaint', data);
  }

  submitComplaint(data) {
    return this.createComplaint(data);
  }
}

export default new ApiService();
