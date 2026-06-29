-- ============================================================
-- PNWHS RMC — Advanced Features Migration
-- ============================================================

SET NAMES utf8mb4;
SET foreign_key_checks = 0;

-- One resident account per property (enforced at DB level)
ALTER TABLE properties
    ADD COLUMN registered_user_id INT UNSIGNED NULL AFTER facility_type,
    ADD COLUMN blacklisted TINYINT(1) DEFAULT 0 AFTER registered_user_id,
    ADD COLUMN blacklist_reason TEXT AFTER blacklisted,
    ADD FOREIGN KEY fk_prop_user (registered_user_id) REFERENCES users(id);

CREATE TABLE otp_verifications (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    mobile      VARCHAR(20) NOT NULL,
    otp_code    VARCHAR(10) NOT NULL,
    purpose     ENUM('registration','password_reset','payment') NOT NULL,
    expires_at  TIMESTAMP NOT NULL,
    used        TINYINT(1) DEFAULT 0,
    attempts    TINYINT DEFAULT 0,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_mobile_purpose (mobile, purpose)
);

CREATE TABLE complaints (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    property_id     INT UNSIGNED NOT NULL,
    user_id         INT UNSIGNED NOT NULL,
    type            ENUM('maintenance','water','security','electricity','cleanliness','noise','other') NOT NULL,
    title           VARCHAR(200) NOT NULL,
    description     TEXT NOT NULL,
    priority        ENUM('low','medium','high','urgent') DEFAULT 'medium',
    status          ENUM('open','in_progress','resolved','closed','rejected') DEFAULT 'open',
    assigned_to     INT UNSIGNED,
    resolved_at     TIMESTAMP NULL,
    resolution_note TEXT,
    rating          TINYINT UNSIGNED,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES properties(id),
    FOREIGN KEY (user_id)     REFERENCES users(id),
    FOREIGN KEY (assigned_to) REFERENCES users(id)
);

CREATE TABLE complaint_comments (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    complaint_id INT UNSIGNED NOT NULL,
    user_id      INT UNSIGNED NOT NULL,
    comment      TEXT NOT NULL,
    is_internal  TINYINT(1) DEFAULT 0,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (complaint_id) REFERENCES complaints(id),
    FOREIGN KEY (user_id)      REFERENCES users(id)
);

CREATE TABLE announcements (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title       VARCHAR(200) NOT NULL,
    body        TEXT NOT NULL,
    sector_id   INT UNSIGNED NULL,
    is_pinned   TINYINT(1) DEFAULT 0,
    push_sent   TINYINT(1) DEFAULT 0,
    sms_sent    TINYINT(1) DEFAULT 0,
    created_by  INT UNSIGNED NOT NULL,
    expires_at  DATE NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sector_id)  REFERENCES sectors(id),
    FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE noc_requests (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    property_id     INT UNSIGNED NOT NULL,
    owner_id        INT UNSIGNED NOT NULL,
    purpose         ENUM('sale','bank','general','transfer') NOT NULL,
    status          ENUM('pending','approved','rejected') DEFAULT 'pending',
    reviewed_by     INT UNSIGNED,
    review_note     TEXT,
    noc_number      VARCHAR(50) UNIQUE,
    issued_at       TIMESTAMP NULL,
    expires_at      DATE NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES properties(id),
    FOREIGN KEY (owner_id)    REFERENCES owners(id),
    FOREIGN KEY (reviewed_by) REFERENCES users(id)
);

CREATE TABLE visitor_passes (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    property_id     INT UNSIGNED NOT NULL,
    registered_by   INT UNSIGNED NOT NULL,
    visitor_name    VARCHAR(150) NOT NULL,
    visitor_cnic    VARCHAR(15),
    visitor_mobile  VARCHAR(20),
    vehicle_no      VARCHAR(20),
    purpose         VARCHAR(200),
    visit_date      DATE NOT NULL,
    valid_from      DATETIME NOT NULL,
    valid_until     DATETIME NOT NULL,
    pass_code       VARCHAR(10) UNIQUE NOT NULL,
    status          ENUM('active','used','expired','cancelled') DEFAULT 'active',
    used_at         TIMESTAMP NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (property_id)   REFERENCES properties(id),
    FOREIGN KEY (registered_by) REFERENCES users(id)
);

CREATE TABLE property_documents (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    property_id     INT UNSIGNED NOT NULL,
    uploaded_by     INT UNSIGNED NOT NULL,
    doc_type        ENUM('allotment_letter','transfer_deed','cnic','tenancy_agreement','noc','other') NOT NULL,
    file_name       VARCHAR(255) NOT NULL,
    file_path       VARCHAR(500) NOT NULL,
    file_size       INT UNSIGNED,
    mime_type       VARCHAR(100),
    is_verified     TINYINT(1) DEFAULT 0,
    verified_by     INT UNSIGNED,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES properties(id),
    FOREIGN KEY (uploaded_by) REFERENCES users(id),
    FOREIGN KEY (verified_by) REFERENCES users(id)
);

CREATE TABLE payment_plans (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    property_id     INT UNSIGNED NOT NULL,
    total_arrears   DECIMAL(12,2) NOT NULL,
    installments    TINYINT NOT NULL,
    monthly_install DECIMAL(12,2) NOT NULL,
    start_month     DATE NOT NULL,
    status          ENUM('active','completed','defaulted') DEFAULT 'active',
    created_by      INT UNSIGNED NOT NULL,
    notes           TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES properties(id),
    FOREIGN KEY (created_by)  REFERENCES users(id)
);

CREATE TABLE cron_log (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    job_name    VARCHAR(100) NOT NULL,
    status      ENUM('success','failed','partial') NOT NULL,
    details     JSON,
    duration_ms INT UNSIGNED,
    ran_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

SET foreign_key_checks = 1;
