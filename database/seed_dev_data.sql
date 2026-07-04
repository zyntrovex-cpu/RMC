-- ============================================================
-- PNWHS RMC — Development Seed Data
-- ============================================================
-- This file contains sample test data for local development.
-- Do NOT merge with schema.sql
--
-- TEST CREDENTIALS:
-- Mobile App Resident Login:
--   Mobile: 03001234567
--   Password: Password@123
--
-- Properties are created across different sectors with different categories
-- ============================================================

SET NAMES utf8mb4;
SET foreign_key_checks = 0;

-- ── SAMPLE PROPERTIES (across different sectors and categories) ──
INSERT INTO properties (sector_id, street_id, plot_no, old_plot_no, category_id, property_type, occupancy, is_corner, is_canal_facing, facility_type, remarks, created_at)
VALUES
  (1, NULL, '1', NULL, 1, 'residential', 'owner_occupied', 0, 0, 'none', 'Test property - Category A', NOW()),
  (1, NULL, '2', NULL, 1, 'residential', 'vacant', 1, 0, 'none', 'Corner plot - Category A', NOW()),
  (1, NULL, '3', NULL, 2, 'residential', 'rented', 0, 1, 'none', 'Canal facing - Category B', NOW()),
  (2, NULL, '1', NULL, 2, 'residential', 'owner_occupied', 0, 0, 'none', 'Test property - Category B', NOW()),
  (2, NULL, '2', NULL, 3, 'residential', 'vacant', 0, 0, 'none', 'Test property - Category C', NOW()),
  (3, NULL, '1', NULL, 1, 'residential', 'rented', 0, 0, 'none', 'Test property - Category A', NOW()),
  (4, NULL, '1', NULL, 2, 'residential', 'owner_occupied', 0, 0, 'none', 'Test property - Category B', NOW());

-- ── TEST RESIDENT USER (for mobile app login) ──
-- Password: Password@123 (hashed with bcrypt)
INSERT INTO users (full_name, cnic, mobile, email, password_hash, role, status, created_at)
VALUES
  ('Test Resident', '42201-1234567-1', '03001234567', 'resident@example.com',
   '$2y$12$8rvFNz7Rp8VQhVYvPp9mje9.zPL5.gKlKqVVF5zYS5Z7K5FV5V1vS', 'owner', 'active', NOW());

-- ── OWNERSHIP RECORD (link resident to first property for testing) ──
INSERT INTO owners (user_id, permanent_address, ownership_doc_ref, noc_cleared, noc_issued_at, created_at)
VALUES
  (2, '123 Test Street, Lahore', 'DOC-001', 0, NULL, NOW());

INSERT INTO ownership_records (property_id, owner_id, transfer_date, transfer_doc, is_current, created_by, created_at)
VALUES
  (1, 1, CURDATE(), 'TRANS-001', 1, 1, NOW());

-- ── SAMPLE CHALLANS (for the resident's property) ──
INSERT INTO challans (account_id, property_id, challan_no, amount, billed_month, due_date, status, created_at)
VALUES
  (1, 1, 'CH-2024-001', 5000, '2024-01', '2024-02-15', 'pending', NOW()),
  (1, 1, 'CH-2024-002', 5000, '2024-02', '2024-03-15', 'partial', NOW()),
  (1, 1, 'CH-2024-003', 5000, '2024-03', '2024-04-15', 'paid', NOW());

-- ── SAMPLE PAYMENTS (partial and full) ──
INSERT INTO payments (challan_id, receipt_no, amount, payment_method, payment_date, created_at)
VALUES
  (2, 'RCP-001', 3000, 'cash', NOW(), NOW()),
  (3, 'RCP-002', 5000, 'bank_transfer', NOW() - INTERVAL 2 MONTH, NOW());

-- ── SAMPLE COMPLAINTS ──
INSERT INTO complaints (property_id, subject, description, status, created_at, updated_at)
VALUES
  (1, 'Water Supply Issue', 'No water supply since morning', 'open', NOW(), NOW()),
  (1, 'Road Maintenance', 'Pothole near the property entrance', 'in_progress', NOW() - INTERVAL 5 DAY, NOW());

-- ── SAMPLE ANNOUNCEMENTS ──
INSERT INTO announcements (title, body, category, is_active, created_at)
VALUES
  ('Maintenance Notice', 'General maintenance scheduled for next weekend', 'maintenance', 1, NOW()),
  ('Community Event', 'Sports day for residents on Saturday', 'event', 1, NOW()),
  ('Fee Update', 'Monthly fee remains unchanged for this quarter', 'fees', 1, NOW());

-- ── SAMPLE VISITOR PASSES ──
INSERT INTO visitor_passes (property_id, visitor_name, visitor_phone, purpose, entry_date, exit_date, status, created_at)
VALUES
  (1, 'John Smith', '03009876543', 'Business Meeting', NOW(), DATE_ADD(NOW(), INTERVAL 3 DAY), 'active', NOW()),
  (1, 'Jane Doe', '03008765432', 'Social Visit', NOW() - INTERVAL 7 DAY, NOW() - INTERVAL 6 DAY, 'expired', NOW());

-- ── SAMPLE NOC REQUESTS ──
INSERT INTO noc_requests (property_id, purpose, requested_date, status, created_at)
VALUES
  (1, 'Property Sale', NOW(), 'pending', NOW()),
  (3, 'Rental Documentation', NOW() - INTERVAL 10 DAY, 'approved', NOW());

SET foreign_key_checks = 1;
