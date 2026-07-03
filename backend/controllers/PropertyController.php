<?php
require_once __DIR__ . '/../config/bootstrap.php';

class PropertyController {
    private PDO $db;

    public function __construct() {
        $this->db = Database::get();
    }

    public function index(): void {
        $page    = max(1, (int)($_GET['page'] ?? 1));
        $perPage = min(100, (int)($_GET['per_page'] ?? 25));
        $offset  = ($page - 1) * $perPage;

        $where  = ['1=1'];
        $params = [];

        if (!empty($_GET['sector_id'])) {
            $where[] = 'p.sector_id = ?'; $params[] = $_GET['sector_id'];
        }
        if (!empty($_GET['street_id'])) {
            $where[] = 'p.street_id = ?'; $params[] = $_GET['street_id'];
        }
        if (!empty($_GET['occupancy'])) {
            $where[] = 'p.occupancy = ?'; $params[] = $_GET['occupancy'];
        }
        if (!empty($_GET['property_type'])) {
            $where[] = 'p.property_type = ?'; $params[] = $_GET['property_type'];
        }
        if (!empty($_GET['search'])) {
            $where[] = '(p.plot_no LIKE ? OR p.old_plot_no LIKE ? OR u.full_name LIKE ?)';
            $s = '%' . $_GET['search'] . '%';
            $params = array_merge($params, [$s, $s, $s]);
        }

        $whereStr = implode(' AND ', $where);

        $countStmt = $this->db->prepare(
            "SELECT COUNT(*) FROM properties p
             LEFT JOIN ownership_records ow ON ow.property_id=p.id AND ow.is_current=1
             LEFT JOIN owners o ON o.id = ow.owner_id
             LEFT JOIN users u ON u.id = o.user_id
             WHERE $whereStr"
        );
        $countStmt->execute($params);
        $total = (int) $countStmt->fetchColumn();

        $stmt = $this->db->prepare(
            "SELECT p.*,
                s.code as sector_code, s.name as sector_name,
                st.street_no,
                pc.code as category_code, pc.label as category_label,
                u.full_name as owner_name, u.mobile as owner_mobile
             FROM properties p
             LEFT JOIN sectors s ON s.id = p.sector_id
             LEFT JOIN streets st ON st.id = p.street_id
             LEFT JOIN property_categories pc ON pc.id = p.category_id
             LEFT JOIN ownership_records ow ON ow.property_id=p.id AND ow.is_current=1
             LEFT JOIN owners o ON o.id = ow.owner_id
             LEFT JOIN users u ON u.id = o.user_id
             WHERE $whereStr
             ORDER BY s.code, CAST(p.plot_no AS UNSIGNED), p.plot_no
             LIMIT $perPage OFFSET $offset"
        );
        $stmt->execute($params);
        Response::paginated($stmt->fetchAll(), $total, $page, $perPage);
    }

    public function show(int $id): void {
        $stmt = $this->db->prepare(
            "SELECT p.*,
                s.code as sector_code, s.name as sector_name,
                st.street_no,
                pc.code as category_code, pc.label as category_label
             FROM properties p
             LEFT JOIN sectors s ON s.id = p.sector_id
             LEFT JOIN streets st ON st.id = p.street_id
             LEFT JOIN property_categories pc ON pc.id = p.category_id
             WHERE p.id = ?"
        );
        $stmt->execute([$id]);
        $property = $stmt->fetch();
        if (!$property) Response::error('Property not found.', 404);

        $ownerStmt = $this->db->prepare(
            "SELECT u.full_name, u.cnic, u.mobile, u.email, o.ownership_doc_ref, o.noc_cleared, ow.transfer_date
             FROM ownership_records ow
             JOIN owners o ON o.id = ow.owner_id
             JOIN users u ON u.id = o.user_id
             WHERE ow.property_id = ? AND ow.is_current = 1"
        );
        $ownerStmt->execute([$id]);
        $property['current_owner'] = $ownerStmt->fetch() ?: null;

        $tenantStmt = $this->db->prepare(
            "SELECT u.full_name, u.cnic, u.mobile, t.emergency_contact, tr.start_date, tr.agreement_ref, tr.challan_to
             FROM tenancy_records tr
             JOIN tenants t ON t.id = tr.tenant_id
             JOIN users u ON u.id = t.user_id
             WHERE tr.property_id = ? AND tr.status = 'active'"
        );
        $tenantStmt->execute([$id]);
        $property['current_tenant'] = $tenantStmt->fetch() ?: null;

        $duesStmt = $this->db->prepare(
            "SELECT a.name as account, SUM(d.total_due - d.amount_paid) as outstanding
             FROM dues d JOIN accounts a ON a.id = d.account_id
             WHERE d.property_id = ? AND d.status IN ('unpaid','partial')
             GROUP BY d.account_id"
        );
        $duesStmt->execute([$id]);
        $property['outstanding_dues'] = $duesStmt->fetchAll();

        Response::success($property);
    }

    public function store(): void {
        AuthMiddleware::require('super_admin', 'rmc_admin');
        $v = Validator::fromRequest();
        $v->required('sector_id')->required('plot_no')->required('category_id');
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $this->db->prepare(
            "INSERT INTO properties
                (sector_id, street_id, plot_no, old_plot_no, category_id, property_type,
                 occupancy, is_corner, is_canal_facing, facility_type, remarks)
             VALUES (?,?,?,?,?,?,?,?,?,?,?)"
        )->execute([
            $v->get('sector_id'), $v->get('street_id'), $v->get('plot_no'),
            $v->get('old_plot_no'), $v->get('category_id'),
            $v->get('property_type', 'residential'),
            $v->get('occupancy', 'vacant'),
            $v->get('is_corner', 0),
            $v->get('is_canal_facing', 0),
            $v->get('facility_type', 'none'),
            $v->get('remarks'),
        ]);

        $id = (int) $this->db->lastInsertId();
        $this->db->prepare(
            "INSERT INTO audit_log (user_id, action, entity_type, entity_id, new_value)
             VALUES (?, 'property.create', 'property', ?, ?)"
        )->execute([AuthMiddleware::user()['sub'], $id, json_encode(['plot_no' => $v->get('plot_no')])]);

        $this->show($id);
    }

    public function update(int $id): void {
        AuthMiddleware::require('super_admin', 'rmc_admin');
        $v = Validator::fromRequest();

        $fields = ['sector_id','street_id','plot_no','old_plot_no','category_id',
                   'property_type','occupancy','is_corner','is_canal_facing','facility_type','remarks','is_active'];
        $body = json_decode(file_get_contents('php://input'), true) ?? [];
        $set = []; $params = [];
        foreach ($fields as $f) {
            if (array_key_exists($f, $body)) {
                $set[] = "$f = ?";
                $params[] = $body[$f];
            }
        }
        if (empty($set)) Response::error('No fields to update.', 400);

        $params[] = $id;
        $this->db->prepare("UPDATE properties SET " . implode(', ', $set) . " WHERE id = ?")->execute($params);
        $this->show($id);
    }

    public function ownershipHistory(int $id): void {
        $stmt = $this->db->prepare(
            "SELECT ow.*, u.full_name, u.cnic, u.mobile
             FROM ownership_records ow
             JOIN owners o ON o.id = ow.owner_id
             JOIN users u ON u.id = o.user_id
             WHERE ow.property_id = ?
             ORDER BY ow.transfer_date DESC"
        );
        $stmt->execute([$id]);
        Response::success($stmt->fetchAll());
    }

    public function transferOwner(int $propertyId): void {
        AuthMiddleware::require('super_admin', 'rmc_admin');
        $v = Validator::fromRequest();
        $v->required('owner_id')->required('transfer_date');
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $this->db->beginTransaction();
        try {
            $this->db->prepare(
                "UPDATE ownership_records SET is_current=0 WHERE property_id=?"
            )->execute([$propertyId]);

            $this->db->prepare(
                "INSERT INTO ownership_records (property_id, owner_id, transfer_date, transfer_doc, is_current, created_by)
                 VALUES (?,?,?,?,1,?)"
            )->execute([
                $propertyId, $v->get('owner_id'), $v->get('transfer_date'),
                $v->get('transfer_doc'), AuthMiddleware::user()['sub']
            ]);

            $this->db->commit();
            Response::success(null, 'Ownership transferred successfully.');
        } catch (\Exception $e) {
            $this->db->rollBack();
            Response::error('Transfer failed: ' . $e->getMessage(), 500);
        }
    }
}

$ctrl   = new PropertyController();
$method = $_SERVER['REQUEST_METHOD'];
$id     = isset($_GET['id']) ? (int)$_GET['id'] : null;
$action = $_GET['action'] ?? '';

AuthMiddleware::require('super_admin', 'rmc_admin', 'data_entry');

match (true) {
    $method === 'GET'  && $id && $action === 'history'  => $ctrl->ownershipHistory($id),
    $method === 'POST' && $id && $action === 'transfer' => $ctrl->transferOwner($id),
    $method === 'GET'  && $id                           => $ctrl->show($id),
    $method === 'GET'                                   => $ctrl->index(),
    $method === 'POST' && !$id                          => $ctrl->store(),
    $method === 'PUT'  && $id                           => $ctrl->update($id),
    default => Response::error('Endpoint not found.', 404),
};
