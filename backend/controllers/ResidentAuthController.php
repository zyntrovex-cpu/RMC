<?php
/**
 * Mobile App Authentication
 * - Self-registration by house number (one user per property)
 * - OTP-based verification
 * - Login / profile / password reset
 */
require_once __DIR__ . '/../config/bootstrap.php';

class ResidentAuthController {
    private PDO $db;

    public function __construct() {
        $this->db = Database::get();
    }

    /**
     * Step 1: Verify plot exists and is available for registration.
     */
    public function checkPlot(): void {
        $v = Validator::fromRequest();
        $v->required('sector_code')->required('plot_no');
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $stmt = $this->db->prepare(
            "SELECT p.id, p.plot_no, p.occupancy, p.registered_user_id,
                    p.facility_type, p.blacklisted,
                    s.code as sector_code, s.name as sector_name,
                    pc.label as category,
                    u.full_name as registered_to
             FROM properties p
             JOIN sectors s ON s.id = p.sector_id
             JOIN property_categories pc ON pc.id = p.category_id
             LEFT JOIN users u ON u.id = p.registered_user_id
             WHERE s.code = ? AND p.plot_no = ? AND p.is_active = 1"
        );
        $stmt->execute([$v->get('sector_code'), $v->get('plot_no')]);
        $property = $stmt->fetch();

        if (!$property) {
            Response::error('Plot not found. Please check sector and plot number.', 404);
        }
        if ($property['facility_type'] !== 'none') {
            Response::error('This plot is a community facility and cannot be registered.', 400);
        }
        if ($property['registered_user_id']) {
            Response::error('This plot already has a registered account. Contact RMC office if this is an error.', 409);
        }

        Response::success([
            'property_id'  => $property['id'],
            'plot_no'      => $property['plot_no'],
            'sector'       => $property['sector_name'],
            'category'     => $property['category'],
            'occupancy'    => $property['occupancy'],
            'available'    => true,
        ], 'Plot verified. You can proceed with registration.');
    }

    /**
     * Step 2: Send OTP to mobile number.
     */
    public function sendOtp(): void {
        $v = Validator::fromRequest();
        $v->required('mobile')->required('property_id');
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $mobile     = preg_replace('/[^0-9]/', '', $v->get('mobile'));
        $propertyId = (int) $v->get('property_id');

        // Check property still free
        $check = $this->db->prepare("SELECT registered_user_id FROM properties WHERE id=?");
        $check->execute([$propertyId]);
        $prop = $check->fetch();
        if (!$prop || $prop['registered_user_id']) {
            Response::error('Plot already registered or not found.', 409);
        }

        // Rate limit: max 3 OTPs in 10 minutes
        $rateCheck = $this->db->prepare(
            "SELECT COUNT(*) FROM otp_verifications
             WHERE mobile=? AND purpose='registration' AND created_at > DATE_SUB(NOW(), INTERVAL 10 MINUTE)"
        );
        $rateCheck->execute([$mobile]);
        if ((int)$rateCheck->fetchColumn() >= 3) {
            Response::error('Too many OTP requests. Please wait 10 minutes.', 429);
        }

        $otp       = str_pad(random_int(100000, 999999), 6, '0', STR_PAD_LEFT);
        $expiresAt = date('Y-m-d H:i:s', strtotime('+10 minutes'));

        $this->db->prepare(
            "INSERT INTO otp_verifications (mobile, otp_code, purpose, expires_at)
             VALUES (?, ?, 'registration', ?)"
        )->execute([$mobile, $otp, $expiresAt]);

        // Send SMS (stub — replace with actual SMS gateway)
        self::sendSms($mobile, "PNWHS RMC: Your verification code is $otp. Valid for 10 minutes. Do not share.");

        Response::success(['mobile' => substr($mobile, 0, 4) . '****' . substr($mobile, -3)], 'OTP sent to your mobile number.');
    }

    /**
     * Step 3: Complete registration — verify OTP + create account.
     */
    public function register(): void {
        $v = Validator::fromRequest();
        $v->required('property_id')->required('mobile')->required('otp_code')
          ->required('full_name')->required('password')->required('cnic');
        $v->cnic('cnic');
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $mobile     = preg_replace('/[^0-9]/', '', $v->get('mobile'));
        $propertyId = (int) $v->get('property_id');

        // Verify OTP
        $otpStmt = $this->db->prepare(
            "SELECT * FROM otp_verifications
             WHERE mobile=? AND otp_code=? AND purpose='registration'
               AND expires_at > NOW() AND used=0
             ORDER BY created_at DESC LIMIT 1"
        );
        $otpStmt->execute([$mobile, $v->get('otp_code')]);
        $otp = $otpStmt->fetch();

        if (!$otp) {
            // Increment attempt counter
            $this->db->prepare(
                "UPDATE otp_verifications SET attempts=attempts+1
                 WHERE mobile=? AND purpose='registration' AND used=0"
            )->execute([$mobile]);
            Response::error('Invalid or expired OTP.', 400);
        }

        // Final check: property still unregistered
        $propStmt = $this->db->prepare(
            "SELECT p.*, s.code as sector_code FROM properties p
             JOIN sectors s ON s.id = p.sector_id
             WHERE p.id=? AND p.is_active=1"
        );
        $propStmt->execute([$propertyId]);
        $property = $propStmt->fetch();

        if (!$property || $property['registered_user_id']) {
            Response::error('This plot is already registered or unavailable.', 409);
        }

        // Check CNIC not already used
        $cnicCheck = $this->db->prepare("SELECT id FROM users WHERE cnic=?");
        $cnicCheck->execute([$v->get('cnic')]);
        if ($cnicCheck->fetchColumn()) {
            Response::error('This CNIC is already registered in the system.', 409);
        }

        $this->db->beginTransaction();
        try {
            // Create user
            $hash = password_hash($v->get('password'), PASSWORD_BCRYPT, ['cost' => 12]);
            $this->db->prepare(
                "INSERT INTO users (full_name, cnic, mobile, whatsapp, email, password_hash, role)
                 VALUES (?,?,?,?,?,?,'owner')"
            )->execute([
                $v->get('full_name'),
                $v->get('cnic'),
                $mobile,
                $v->get('whatsapp', $mobile),
                $v->get('email'),
                $hash,
            ]);
            $userId = (int) $this->db->lastInsertId();

            // Create owner record
            $this->db->prepare(
                "INSERT INTO owners (user_id, permanent_address) VALUES (?,?)"
            )->execute([$userId, $v->get('address')]);
            $ownerId = (int) $this->db->lastInsertId();

            // Link property to user
            $this->db->prepare(
                "UPDATE properties SET registered_user_id=?, occupancy='owner_occupied' WHERE id=?"
            )->execute([$userId, $propertyId]);

            // Create ownership record
            $this->db->prepare(
                "INSERT INTO ownership_records (property_id, owner_id, transfer_date, is_current)
                 VALUES (?,?,CURDATE(),1)"
            )->execute([$propertyId, $ownerId]);

            // Mark OTP used
            $this->db->prepare("UPDATE otp_verifications SET used=1 WHERE id=?")->execute([$otp['id']]);

            $this->db->prepare(
                "INSERT INTO audit_log (user_id, action, entity_type, entity_id, new_value)
                 VALUES (?, 'resident.self_register', 'user', ?, ?)"
            )->execute([$userId, $userId, json_encode(['property_id' => $propertyId, 'sector' => $property['sector_code']])]);

            $this->db->commit();

            // Fetch user for token
            $userStmt = $this->db->prepare("SELECT * FROM users WHERE id=?");
            $userStmt->execute([$userId]);
            $user = $userStmt->fetch();
            unset($user['password_hash'], $user['otp_secret']);

            Response::success([
                'token' => AuthMiddleware::generate($user),
                'user'  => $user,
            ], 'Registration successful! Welcome to PNWHS.', 201);

        } catch (\Exception $e) {
            $this->db->rollBack();
            Response::error('Registration failed: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Resident login (mobile + password or CNIC + password).
     */
    public function login(): void {
        $v = Validator::fromRequest();
        $v->required('password');
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $identifier = $v->get('mobile') ?: $v->get('cnic') ?: $v->get('email');
        if (!$identifier) Response::error('Provide mobile, CNIC, or email.', 422);

        $stmt = $this->db->prepare(
            "SELECT * FROM users
             WHERE (mobile=? OR cnic=? OR email=?)
               AND role IN ('owner','tenant')
               AND status='active'"
        );
        $stmt->execute([$identifier, $identifier, $identifier]);
        $user = $stmt->fetch();

        if (!$user || !password_verify($v->get('password'), $user['password_hash'])) {
            Response::error('Invalid credentials.', 401);
        }

        // Get linked property
        $propStmt = $this->db->prepare(
            "SELECT p.id, p.plot_no, p.occupancy, p.blacklisted,
                    s.code as sector_code, s.name as sector_name,
                    pc.label as category
             FROM properties p
             JOIN sectors s ON s.id = p.sector_id
             JOIN property_categories pc ON pc.id = p.category_id
             WHERE p.registered_user_id = ?"
        );
        $propStmt->execute([$user['id']]);
        $property = $propStmt->fetch();

        // Update FCM token if provided
        if ($v->get('fcm_token')) {
            $this->db->prepare("UPDATE users SET fcm_token=?, last_login=NOW() WHERE id=?")
                     ->execute([$v->get('fcm_token'), $user['id']]);
        } else {
            $this->db->prepare("UPDATE users SET last_login=NOW() WHERE id=?")->execute([$user['id']]);
        }

        unset($user['password_hash'], $user['otp_secret']);
        Response::success([
            'token'    => AuthMiddleware::generate($user),
            'user'     => $user,
            'property' => $property,
        ], 'Login successful.');
    }

    /**
     * Send OTP for password reset.
     */
    public function forgotPassword(): void {
        $v = Validator::fromRequest();
        $v->required('mobile');
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $mobile = preg_replace('/[^0-9]/', '', $v->get('mobile'));

        $stmt = $this->db->prepare("SELECT id FROM users WHERE mobile=? AND status='active'");
        $stmt->execute([$mobile]);
        if (!$stmt->fetch()) {
            Response::success(null, 'If this number is registered, an OTP has been sent.');
        }

        $otp = str_pad(random_int(100000, 999999), 6, '0', STR_PAD_LEFT);
        $this->db->prepare(
            "INSERT INTO otp_verifications (mobile, otp_code, purpose, expires_at)
             VALUES (?, ?, 'password_reset', DATE_ADD(NOW(), INTERVAL 10 MINUTE))"
        )->execute([$mobile, $otp]);

        self::sendSms($mobile, "PNWHS RMC: Your password reset code is $otp. Valid 10 minutes.");
        Response::success(null, 'If this number is registered, an OTP has been sent.');
    }

    /**
     * Reset password using OTP.
     */
    public function resetPassword(): void {
        $v = Validator::fromRequest();
        $v->required('mobile')->required('otp_code')->required('new_password');
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $mobile = preg_replace('/[^0-9]/', '', $v->get('mobile'));

        $otpStmt = $this->db->prepare(
            "SELECT * FROM otp_verifications
             WHERE mobile=? AND otp_code=? AND purpose='password_reset'
               AND expires_at > NOW() AND used=0
             ORDER BY created_at DESC LIMIT 1"
        );
        $otpStmt->execute([$mobile, $v->get('otp_code')]);
        $otp = $otpStmt->fetch();

        if (!$otp) Response::error('Invalid or expired OTP.', 400);

        $hash = password_hash($v->get('new_password'), PASSWORD_BCRYPT, ['cost' => 12]);
        $this->db->prepare("UPDATE users SET password_hash=? WHERE mobile=?")->execute([$hash, $mobile]);
        $this->db->prepare("UPDATE otp_verifications SET used=1 WHERE id=?")->execute([$otp['id']]);

        Response::success(null, 'Password reset successfully.');
    }

    private static function sendSms(string $mobile, string $message): void {
        if (!SMS_API_KEY) return;
        $payload = ['api_key' => SMS_API_KEY, 'sender' => SMS_SENDER_ID, 'to' => $mobile, 'message' => $message];
        $ch = curl_init('https://api.sms-gateway.pk/send');
        curl_setopt_array($ch, [CURLOPT_POST => true, CURLOPT_POSTFIELDS => $payload, CURLOPT_RETURNTRANSFER => true]);
        curl_exec($ch);
        curl_close($ch);
    }
}

$ctrl   = new ResidentAuthController();
$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

match (true) {
    $method === 'POST' && $action === 'check-plot'       => $ctrl->checkPlot(),
    $method === 'POST' && $action === 'send-otp'         => $ctrl->sendOtp(),
    $method === 'POST' && $action === 'register'         => $ctrl->register(),
    $method === 'POST' && $action === 'login'            => $ctrl->login(),
    $method === 'POST' && $action === 'forgot-password'  => $ctrl->forgotPassword(),
    $method === 'POST' && $action === 'reset-password'   => $ctrl->resetPassword(),
    default => Response::error('Endpoint not found.', 404),
};
