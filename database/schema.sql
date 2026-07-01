-- ============================================================
-- PNWHS RMC — Society Management System
-- Database Schema v1.0
-- ============================================================

SET NAMES utf8mb4;
SET foreign_key_checks = 0;

-- ------------------------------------------------------------
-- SECTORS
-- ------------------------------------------------------------
CREATE TABLE sectors (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code        VARCHAR(10) NOT NULL UNIQUE,   -- '1A','1B','1C','2','3','4'
    name        VARCHAR(100) NOT NULL,
    description TEXT,
    is_active   TINYINT(1) NOT NULL DEFAULT 1,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO sectors (code, name) VALUES
    ('1A', 'Sector 1A'),
    ('1B', 'Sector 1B'),
    ('1C', 'Sector 1C'),
    ('2',  'Sector 2'),
    ('3',  'Sector 3'),
    ('4',  'Sector 4');

-- ------------------------------------------------------------
-- STREETS  (numbered per sector)
-- ------------------------------------------------------------
CREATE TABLE streets (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sector_id   INT UNSIGNED NOT NULL,
    street_no   VARCHAR(20) NOT NULL,          -- '1','2','3A' etc.
    width_feet  SMALLINT UNSIGNED,             -- e.g. 35, 80
    street_type ENUM('internal','avenue','boulevard','circular') DEFAULT 'internal',
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sector_id) REFERENCES sectors(id),
    UNIQUE KEY uq_sector_street (sector_id, street_no)
);

-- ------------------------------------------------------------
-- PROPERTY CATEGORIES  (plot size / type)
-- ------------------------------------------------------------
CREATE TABLE property_categories (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code        VARCHAR(10) NOT NULL UNIQUE,   -- 'A','B','C','COMM'
    label       VARCHAR(50) NOT NULL,          -- '240 Sq Yds','180 Sq Yds'
    area_sqyds  SMALLINT UNSIGNED,
    is_commercial TINYINT(1) DEFAULT 0
);

INSERT INTO property_categories (code, label, area_sqyds, is_commercial) VALUES
    ('A',    '240 Sq Yds', 240, 0),
    ('B',    '180 Sq Yds', 180, 0),
    ('C',    '120 Sq Yds', 120, 0),
    ('COMM', 'Commercial',  NULL, 1);

-- ------------------------------------------------------------
-- PROPERTIES (plots/houses)
-- ------------------------------------------------------------
CREATE TABLE properties (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sector_id       INT UNSIGNED NOT NULL,
    street_id       INT UNSIGNED,
    plot_no         VARCHAR(20) NOT NULL,
    old_plot_no     VARCHAR(20),
    category_id     INT UNSIGNED NOT NULL,
    property_type   ENUM('residential','commercial','plot') DEFAULT 'residential',
    occupancy       ENUM('owner_occupied','rented','vacant','disputed','exempt') DEFAULT 'vacant',
    is_corner       TINYINT(1) DEFAULT 0,
    is_canal_facing TINYINT(1) DEFAULT 0,
    is_active       TINYINT(1) DEFAULT 1,
    facility_type   ENUM('none','mosque','park','community','utility') DEFAULT 'none',
    remarks         TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (sector_id)   REFERENCES sectors(id),
    FOREIGN KEY (street_id)   REFERENCES streets(id),
    FOREIGN KEY (category_id) REFERENCES property_categories(id),
    UNIQUE KEY uq_sector_plot (sector_id, plot_no)
);

-- ------------------------------------------------------------
-- USERS  (admin staff + residents)
-- ------------------------------------------------------------
CREATE TABLE users (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name       VARCHAR(150) NOT NULL,
    cnic            VARCHAR(15) UNIQUE,
    mobile          VARCHAR(20),
    mobile_alt      VARCHAR(20),
    whatsapp        VARCHAR(20),
    email           VARCHAR(150) UNIQUE,
    password_hash   VARCHAR(255),
    role            ENUM('super_admin','rmc_admin','data_entry','owner','tenant') NOT NULL,
    status          ENUM('active','inactive','blacklisted') DEFAULT 'active',
    otp_secret      VARCHAR(64),
    fcm_token       VARCHAR(255),
    last_login      TIMESTAMP NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO users (full_name, cnic, mobile, email, password_hash, role, status) VALUES
    ('RMC Super Admin', NULL, 'admin', 'admin@pnwhs-rmc.com',
     '$2y$12$0eR2O22k2sWk4srYhI0gHugGQD2mm4C3muXjSvh3OOJt86F7fDTe2', 'super_admin', 'active');

-- ------------------------------------------------------------
-- OWNERS
-- ------------------------------------------------------------
CREATE TABLE owners (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id             INT UNSIGNED NOT NULL,
    permanent_address   TEXT,
    ownership_doc_ref   VARCHAR(100),
    noc_cleared         TINYINT(1) DEFAULT 0,
    noc_issued_at       DATE,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ------------------------------------------------------------
-- TENANTS
-- ------------------------------------------------------------
CREATE TABLE tenants (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id             INT UNSIGNED NOT NULL,
    emergency_contact   VARCHAR(20),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ------------------------------------------------------------
-- OWNERSHIP RECORDS  (property <-> owner, with history)
-- ------------------------------------------------------------
CREATE TABLE ownership_records (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    property_id     INT UNSIGNED NOT NULL,
    owner_id        INT UNSIGNED NOT NULL,
    transfer_date   DATE NOT NULL,
    transfer_doc    VARCHAR(100),
    is_current      TINYINT(1) DEFAULT 1,
    notes           TEXT,
    created_by      INT UNSIGNED,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES properties(id),
    FOREIGN KEY (owner_id)    REFERENCES owners(id),
    FOREIGN KEY (created_by)  REFERENCES users(id)
);

-- ------------------------------------------------------------
-- TENANCY RECORDS  (property <-> tenant, with history)
-- ------------------------------------------------------------
CREATE TABLE tenancy_records (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    property_id     INT UNSIGNED NOT NULL,
    tenant_id       INT UNSIGNED NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE,
    agreement_ref   VARCHAR(100),
    challan_to      ENUM('owner','tenant') DEFAULT 'owner',
    status          ENUM('active','vacated','archived') DEFAULT 'active',
    created_by      INT UNSIGNED,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES properties(id),
    FOREIGN KEY (tenant_id)   REFERENCES tenants(id),
    FOREIGN KEY (created_by)  REFERENCES users(id)
);

-- ------------------------------------------------------------
-- ACCOUNTS  (fee heads)
-- ------------------------------------------------------------
CREATE TABLE accounts (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL UNIQUE,
    code            VARCHAR(20)  NOT NULL UNIQUE,
    description     TEXT,
    monthly_amount  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    is_active       TINYINT(1) DEFAULT 1,
    sort_order      TINYINT UNSIGNED DEFAULT 0,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO accounts (name, code, monthly_amount, sort_order) VALUES
    ('Maintenance Fund', 'MAINT',  0.00, 1),
    ('Water Fund',       'WATER',  0.00, 2),
    ('Security Fund',    'SEC',    0.00, 3),
    ('Masjid Fund',      'MASJID', 0.00, 4);

-- ------------------------------------------------------------
-- ACCOUNT RATE HISTORY
-- ------------------------------------------------------------
CREATE TABLE account_rate_history (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id      INT UNSIGNED NOT NULL,
    old_amount      DECIMAL(10,2),
    new_amount      DECIMAL(10,2) NOT NULL,
    effective_from  DATE NOT NULL,
    changed_by      INT UNSIGNED,
    reason          TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES accounts(id),
    FOREIGN KEY (changed_by) REFERENCES users(id)
);

-- ------------------------------------------------------------
-- DUES  (one record per property per account per month)
-- ------------------------------------------------------------
CREATE TABLE dues (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    property_id     INT UNSIGNED NOT NULL,
    account_id      INT UNSIGNED NOT NULL,
    due_month       DATE NOT NULL,
    amount          DECIMAL(10,2) NOT NULL,
    arrears         DECIMAL(10,2) DEFAULT 0.00,
    total_due       DECIMAL(10,2) GENERATED ALWAYS AS (amount + arrears) STORED,
    amount_paid     DECIMAL(10,2) DEFAULT 0.00,
    status          ENUM('unpaid','partial','paid','waived') DEFAULT 'unpaid',
    waiver_reason   TEXT,
    waived_by       INT UNSIGNED,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES properties(id),
    FOREIGN KEY (account_id)  REFERENCES accounts(id),
    FOREIGN KEY (waived_by)   REFERENCES users(id),
    UNIQUE KEY uq_due (property_id, account_id, due_month)
);

-- ------------------------------------------------------------
-- CHALLANS
-- ------------------------------------------------------------
CREATE TABLE challans (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    challan_no      VARCHAR(30) NOT NULL UNIQUE,
    due_id          INT UNSIGNED NOT NULL,
    property_id     INT UNSIGNED NOT NULL,
    account_id      INT UNSIGNED NOT NULL,
    issue_date      DATE NOT NULL,
    due_date        DATE NOT NULL,
    amount          DECIMAL(10,2) NOT NULL,
    arrears         DECIMAL(10,2) DEFAULT 0.00,
    total_amount    DECIMAL(10,2) NOT NULL,
    bill_1bill_code VARCHAR(50),
    raast_id        VARCHAR(50),
    status          ENUM('unpaid','partial','paid','overdue','cancelled') DEFAULT 'unpaid',
    cancelled_by    INT UNSIGNED,
    cancel_reason   TEXT,
    created_by      INT UNSIGNED,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (due_id)       REFERENCES dues(id),
    FOREIGN KEY (property_id)  REFERENCES properties(id),
    FOREIGN KEY (account_id)   REFERENCES accounts(id),
    FOREIGN KEY (cancelled_by) REFERENCES users(id),
    FOREIGN KEY (created_by)   REFERENCES users(id)
);

-- ------------------------------------------------------------
-- PAYMENTS
-- ------------------------------------------------------------
CREATE TABLE payments (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    challan_id      INT UNSIGNED NOT NULL,
    property_id     INT UNSIGNED NOT NULL,
    amount          DECIMAL(10,2) NOT NULL,
    payment_method  ENUM('1bill','raast','card','cash','cheque','ibft') NOT NULL,
    payment_date    DATE NOT NULL,
    reference_no    VARCHAR(100),
    cheque_status   ENUM('pending','cleared','bounced') DEFAULT NULL,
    receipt_no      VARCHAR(30) UNIQUE,
    gateway_response JSON,
    recorded_by     INT UNSIGNED,
    notes           TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (challan_id)   REFERENCES challans(id),
    FOREIGN KEY (property_id)  REFERENCES properties(id),
    FOREIGN KEY (recorded_by)  REFERENCES users(id)
);

-- ------------------------------------------------------------
-- AUDIT LOG
-- ------------------------------------------------------------
CREATE TABLE audit_log (
    id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id     INT UNSIGNED,
    action      VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id   INT UNSIGNED,
    old_value   JSON,
    new_value   JSON,
    ip_address  VARCHAR(45),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ------------------------------------------------------------
-- NOTIFICATIONS
-- ------------------------------------------------------------
CREATE TABLE notifications (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id     INT UNSIGNED NOT NULL,
    title       VARCHAR(200) NOT NULL,
    body        TEXT NOT NULL,
    type        ENUM('due_reminder','payment_confirm','announcement','system') DEFAULT 'system',
    is_read     TINYINT(1) DEFAULT 0,
    sent_at     TIMESTAMP NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ------------------------------------------------------------
-- SYSTEM SETTINGS
-- ------------------------------------------------------------
CREATE TABLE settings (
    `key`       VARCHAR(100) PRIMARY KEY,
    `value`     TEXT,
    label       VARCHAR(200),
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO settings (`key`, `value`, `label`) VALUES
    ('society_name',        'PNWHS bin Qasim',      'Society Name'),
    ('rmc_office_address',  'Port Qasim, Karachi',  'RMC Office Address'),
    ('rmc_contact',         '',                      'RMC Contact Number'),
    ('challan_due_day',     '25',                    'Challan Due Day of Month'),
    ('late_fee_percentage', '0',                     'Late Fee %'),
    ('sms_enabled',         '1',                     'SMS Notifications Enabled'),
    ('fcm_enabled',         '1',                     'Push Notifications Enabled'),
    ('currency',            'PKR',                   'Currency'),
    ('fiscal_year_start',   '07',                    'Fiscal Year Start Month');

SET foreign_key_checks = 1;
