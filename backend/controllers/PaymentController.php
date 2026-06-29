<?php
require_once __DIR__ . '/../config/bootstrap.php';

class PaymentController {
    private PDO $db;

    public function __construct() {
        $this->db = Database::get();
    }

    public function index(): void {
        $page    = max(1, (int)($_GET['page'] ?? 1));
        $perPage = min(100, (int)($_GET['per_page'] ?? 25));
        $offset  = ($page - 1) * $perPage;

        $where = ['1=1']; $params = [];
        if (!empty($_GET['property_id'])) { $where[] = 'py.property_id=?';     $params[] = $_GET['property_id']; }
        if (!empty($_GET['method']))      { $where[] = 'py.payment_method=?';  $params[] = $_GET['method']; }
        if (!empty($_GET['from']))        { $where[] = 'py.payment_date >= ?'; $params[] = $_GET['from']; }
        if (!empty($_GET['to']))          { $where[] = 'py.payment_date <= ?'; $params[] = $_GET['to']; }
        if (!empty($_GET['month']))       { $where[] = "DATE_FORMAT(py.payment_date,'%Y-%m')=?"; $params[] = $_GET['month']; }

        $whereStr = implode(' AND ', $where);

        $countStmt = $this->db->prepare("SELECT COUNT(*) FROM payments py WHERE $whereStr");
        $countStmt->execute($params);
        $total = (int) $countStmt->fetchColumn();

        $stmt = $this->db->prepare(
            "SELECT py.*, c.challan_no, a.name as account_name,
                p.plot_no, s.code as sector_code,
                u.full_name as recorded_by_name
             FROM payments py
             JOIN challans c ON c.id = py.challan_id
             JOIN accounts a ON a.id = c.account_id
             JOIN properties p ON p.id = py.property_id
             JOIN sectors s ON s.id = p.sector_id
             LEFT JOIN users u ON u.id = py.recorded_by
             WHERE $whereStr
             ORDER BY py.created_at DESC
             LIMIT $perPage OFFSET $offset"
        );
        $stmt->execute($params);
        Response::paginated($stmt->fetchAll(), $total, $page, $perPage);
    }

    public function recordManual(): void {
        AuthMiddleware::require('super_admin', 'rmc_admin', 'data_entry');
        $v = Validator::fromRequest();
        $v->required('challan_id')->required('amount')->required('payment_method')->required('payment_date');
        $v->numeric('amount');
        $v->inList('payment_method', ['cash','cheque','ibft']);
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $admin     = AuthMiddleware::user();
        $challanId = (int) $v->get('challan_id');
        $amount    = (float) $v->get('amount');

        $challanStmt = $this->db->prepare("SELECT * FROM challans WHERE id=? AND status != 'cancelled'");
        $challanStmt->execute([$challanId]);
        $challan = $challanStmt->fetch();
        if (!$challan) Response::error('Challan not found or cancelled.', 404);

        $this->db->beginTransaction();
        try {
            $seqStmt = $this->db->query("SELECT COUNT(*) FROM payments");
            $seq = (int) $seqStmt->fetchColumn() + 1;
            $receiptNo = ChallanHelper::generateReceipt($seq);

            $this->db->prepare(
                "INSERT INTO payments
                    (challan_id, property_id, amount, payment_method, payment_date, reference_no, cheque_status, receipt_no, recorded_by, notes)
                 VALUES (?,?,?,?,?,?,?,?,?,?)"
            )->execute([
                $challanId,
                $challan['property_id'],
                $amount,
                $v->get('payment_method'),
                $v->get('payment_date'),
                $v->get('reference_no'),
                $v->get('payment_method') === 'cheque' ? 'pending' : null,
                $receiptNo,
                $admin['sub'],
                $v->get('notes'),
            ]);

            $this->updateChallanStatus($challanId);

            $this->db->prepare(
                "INSERT INTO audit_log (user_id, action, entity_type, entity_id, new_value)
                 VALUES (?, 'payment.manual', 'payment', LAST_INSERT_ID(), ?)"
            )->execute([$admin['sub'], json_encode(['amount' => $amount, 'method' => $v->get('payment_method')])]);

            $this->db->commit();
            Response::success(['receipt_no' => $receiptNo], 'Payment recorded successfully.');
        } catch (\Exception $e) {
            $this->db->rollBack();
            Response::error('Payment recording failed: ' . $e->getMessage(), 500);
        }
    }

    public function webhook(): void {
        $payload = json_decode(file_get_contents('php://input'), true);

        $signature = $_SERVER['HTTP_X_GATEWAY_SIGNATURE'] ?? '';
        $expected  = hash_hmac('sha256', json_encode($payload), KUICKPAY_API_KEY);
        if (!hash_equals($expected, $signature)) {
            http_response_code(401);
            exit;
        }

        $challanNo = $payload['consumer_number'] ?? '';
        $amount    = (float) ($payload['amount'] ?? 0);
        $txnId     = $payload['transaction_id'] ?? '';
        $status    = $payload['status'] ?? '';

        if ($status !== 'success' || !$challanNo || !$amount) {
            http_response_code(200);
            exit;
        }

        $challanStmt = $this->db->prepare("SELECT * FROM challans WHERE challan_no=?");
        $challanStmt->execute([$challanNo]);
        $challan = $challanStmt->fetch();

        if (!$challan || $challan['status'] === 'paid') {
            http_response_code(200);
            exit;
        }

        $this->db->beginTransaction();
        try {
            $seq = (int) $this->db->query("SELECT COUNT(*) FROM payments")->fetchColumn() + 1;
            $this->db->prepare(
                "INSERT INTO payments
                    (challan_id, property_id, amount, payment_method, payment_date, reference_no, receipt_no, gateway_response)
                 VALUES (?,?,?,'1bill',NOW(),?,?,?)"
            )->execute([
                $challan['id'], $challan['property_id'], $amount, $txnId,
                ChallanHelper::generateReceipt($seq),
                json_encode($payload),
            ]);

            $this->updateChallanStatus($challan['id']);
            $this->db->commit();
        } catch (\Exception $e) {
            $this->db->rollBack();
        }

        http_response_code(200);
        echo json_encode(['status' => 'ok']);
        exit;
    }

    private function updateChallanStatus(int $challanId): void {
        $stmt = $this->db->prepare("SELECT total_amount FROM challans WHERE id=?");
        $stmt->execute([$challanId]);
        $challan = $stmt->fetch();

        $totalPaidStmt = $this->db->prepare("SELECT COALESCE(SUM(amount),0) FROM payments WHERE challan_id=?");
        $totalPaidStmt->execute([$challanId]);
        $totalPaid = (float) $totalPaidStmt->fetchColumn();

        $status = match(true) {
            $totalPaid >= $challan['total_amount'] => 'paid',
            $totalPaid > 0                         => 'partial',
            default                                => 'unpaid',
        };

        $this->db->prepare("UPDATE challans SET status=? WHERE id=?")->execute([$status, $challanId]);
        $this->db->prepare(
            "UPDATE dues SET amount_paid=?, status=? WHERE id=(SELECT due_id FROM challans WHERE id=?)"
        )->execute([$totalPaid, $status, $challanId]);
    }
}

$ctrl   = new PaymentController();
$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

AuthMiddleware::user();

match (true) {
    $method === 'POST' && $action === 'manual'  => $ctrl->recordManual(),
    $method === 'POST' && $action === 'webhook' => $ctrl->webhook(),
    $method === 'GET'                           => $ctrl->index(),
    default => Response::error('Endpoint not found.', 404),
};
