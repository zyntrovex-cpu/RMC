<?php
require_once __DIR__ . '/../config/bootstrap.php';

class ReportController {
    private PDO $db;

    public function __construct() {
        $this->db = Database::get();
    }

    public function monthly(): void {
        $month = $_GET['month'] ?? date('Y-m');
        $rows  = $this->db->prepare(
            "SELECT
                s.code as sector, p.plot_no,
                u.full_name as owner, u.mobile,
                a.name as account,
                c.challan_no, c.total_amount, c.status,
                py.amount as paid_amount, py.payment_method, py.payment_date, py.receipt_no
             FROM challans c
             JOIN properties p ON p.id = c.property_id
             JOIN sectors s ON s.id = p.sector_id
             JOIN accounts a ON a.id = c.account_id
             LEFT JOIN ownership_records ow ON ow.property_id=p.id AND ow.is_current=1
             LEFT JOIN owners o ON o.id = ow.owner_id
             LEFT JOIN users u ON u.id = o.user_id
             LEFT JOIN payments py ON py.challan_id = c.id
             WHERE DATE_FORMAT(c.issue_date,'%Y-%m') = ?
             ORDER BY s.code, p.plot_no, a.sort_order"
        );
        $rows->execute([$month]);
        Response::success(['month' => $month, 'rows' => $rows->fetchAll()]);
    }

    public function sectorWise(): void {
        $month = $_GET['month'] ?? date('Y-m');
        $rows  = $this->db->prepare(
            "SELECT
                s.code, s.name,
                COUNT(DISTINCT p.id) as total_properties,
                COUNT(c.id) as total_challans,
                SUM(c.total_amount) as total_billed,
                SUM(CASE WHEN c.status='paid' THEN c.total_amount ELSE 0 END) as collected,
                SUM(CASE WHEN c.status IN ('unpaid','overdue','partial') THEN c.total_amount ELSE 0 END) as outstanding,
                SUM(CASE WHEN c.status='paid' THEN 1 ELSE 0 END) as paid_count,
                SUM(CASE WHEN c.status IN ('unpaid','overdue') THEN 1 ELSE 0 END) as unpaid_count
             FROM sectors s
             LEFT JOIN properties p ON p.sector_id=s.id AND p.is_active=1 AND p.facility_type='none'
             LEFT JOIN challans c ON c.property_id=p.id AND DATE_FORMAT(c.issue_date,'%Y-%m')=?
             GROUP BY s.id
             ORDER BY s.code"
        );
        $rows->execute([$month]);
        Response::success(['month' => $month, 'rows' => $rows->fetchAll()]);
    }

    public function houseWise(): void {
        $propertyId = (int)($_GET['property_id'] ?? 0);
        if (!$propertyId) Response::error('property_id required.', 400);

        $rows = $this->db->prepare(
            "SELECT
                c.challan_no, DATE_FORMAT(c.issue_date,'%Y-%m') as month,
                a.name as account, c.amount, c.arrears, c.total_amount,
                c.status, py.amount as paid_amount,
                py.payment_method, py.payment_date, py.receipt_no
             FROM challans c
             JOIN accounts a ON a.id = c.account_id
             LEFT JOIN payments py ON py.challan_id = c.id
             WHERE c.property_id = ?
             ORDER BY c.issue_date DESC, a.sort_order"
        );
        $rows->execute([$propertyId]);
        Response::success($rows->fetchAll());
    }

    public function defaulters(): void {
        $rows = $this->db->prepare(
            "SELECT
                s.code as sector, p.plot_no,
                u.full_name as owner, u.mobile, u.cnic,
                COUNT(c.id) as unpaid_challans,
                SUM(c.total_amount) as total_outstanding,
                GROUP_CONCAT(DISTINCT a.name ORDER BY a.sort_order SEPARATOR ', ') as accounts_due,
                MIN(c.due_date) as oldest_overdue,
                p.blacklisted
             FROM challans c
             JOIN properties p ON p.id = c.property_id
             JOIN sectors s ON s.id = p.sector_id
             JOIN accounts a ON a.id = c.account_id
             LEFT JOIN ownership_records ow ON ow.property_id=p.id AND ow.is_current=1
             LEFT JOIN owners o ON o.id = ow.owner_id
             LEFT JOIN users u ON u.id = o.user_id
             WHERE c.status IN ('unpaid','overdue','partial')
             GROUP BY c.property_id
             ORDER BY total_outstanding DESC"
        );
        $rows->execute();
        Response::success($rows->fetchAll());
    }

    public function arrears(): void {
        $rows = $this->db->prepare(
            "SELECT
                a.name as account,
                SUM(d.total_due - d.amount_paid) as total_arrears,
                COUNT(DISTINCT d.property_id) as properties_with_arrears
             FROM dues d
             JOIN accounts a ON a.id = d.account_id
             WHERE d.status IN ('unpaid','partial')
             GROUP BY d.account_id
             ORDER BY total_arrears DESC"
        );
        $rows->execute();
        Response::success($rows->fetchAll());
    }

    public function annual(): void {
        $year = (int)($_GET['year'] ?? date('Y'));
        $rows = $this->db->prepare(
            "SELECT
                DATE_FORMAT(c.issue_date,'%Y-%m') as month,
                a.name as account,
                SUM(c.total_amount) as billed,
                SUM(CASE WHEN c.status='paid' THEN c.total_amount ELSE 0 END) as collected,
                SUM(CASE WHEN c.status IN ('unpaid','overdue','partial') THEN c.total_amount ELSE 0 END) as outstanding,
                COUNT(c.id) as total_challans,
                SUM(CASE WHEN c.status='paid' THEN 1 ELSE 0 END) as paid_count
             FROM challans c
             JOIN accounts a ON a.id = c.account_id
             WHERE YEAR(c.issue_date) = ?
             GROUP BY DATE_FORMAT(c.issue_date,'%Y-%m'), c.account_id
             ORDER BY month, a.sort_order"
        );
        $rows->execute([$year]);
        Response::success(['year' => $year, 'rows' => $rows->fetchAll()]);
    }
}

$ctrl   = new ReportController();
$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? 'monthly';

AuthMiddleware::require('super_admin', 'rmc_admin');

match ($action) {
    'monthly'    => $ctrl->monthly(),
    'sector'     => $ctrl->sectorWise(),
    'house'      => $ctrl->houseWise(),
    'defaulters' => $ctrl->defaulters(),
    'arrears'    => $ctrl->arrears(),
    'annual'     => $ctrl->annual(),
    default      => Response::error('Report type not found.', 404),
};
