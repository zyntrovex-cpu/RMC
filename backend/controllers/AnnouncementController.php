<?php
require_once __DIR__ . '/../config/bootstrap.php';

class AnnouncementController {
    private PDO $db;

    public function __construct() {
        $this->db = Database::get();
    }

    public function index(): void {
        $sectorId = $_GET['sector_id'] ?? null;
        $stmt = $this->db->prepare(
            "SELECT a.*, u.full_name as posted_by, s.name as sector_name
             FROM announcements a
             JOIN users u ON u.id=a.created_by
             LEFT JOIN sectors s ON s.id=a.sector_id
             WHERE (a.sector_id IS NULL OR a.sector_id=? OR ? IS NULL)
               AND (a.expires_at IS NULL OR a.expires_at >= CURDATE())
             ORDER BY a.is_pinned DESC, a.created_at DESC
             LIMIT 50"
        );
        $stmt->execute([$sectorId, $sectorId]);
        Response::success($stmt->fetchAll());
    }

    public function store(): void {
        $me = AuthMiddleware::require('super_admin','rmc_admin');
        $v  = Validator::fromRequest();
        $v->required('title')->required('body');
        if ($v->fails()) Response::error('Validation failed.', 422, $v->errors());

        $this->db->prepare(
            "INSERT INTO announcements (title, body, sector_id, is_pinned, expires_at, created_by)
             VALUES (?,?,?,?,?,?)"
        )->execute([
            $v->get('title'), $v->get('body'),
            $v->get('sector_id') ?: null,
            $v->get('is_pinned', 0),
            $v->get('expires_at') ?: null,
            $me['sub'],
        ]);
        $id = (int)$this->db->lastInsertId();

        $this->pushToResidents($id, $v->get('sector_id'), $v->get('title'), $v->get('body'));

        $stmt = $this->db->prepare("SELECT * FROM announcements WHERE id=?");
        $stmt->execute([$id]);
        Response::success($stmt->fetch(), 'Announcement posted.', 201);
    }

    public function delete(int $id): void {
        AuthMiddleware::require('super_admin','rmc_admin');
        $this->db->prepare("DELETE FROM announcements WHERE id=?")->execute([$id]);
        Response::success(null, 'Announcement deleted.');
    }

    private function pushToResidents(int $announcementId, ?string $sectorId, string $title, string $body): void {
        $where  = $sectorId ? "AND p.sector_id=?" : "";
        $params = $sectorId ? [$sectorId] : [];

        $stmt = $this->db->prepare(
            "SELECT u.id FROM users u
             JOIN properties p ON p.registered_user_id=u.id
             WHERE u.status='active' $where"
        );
        $stmt->execute($params);
        $residents = $stmt->fetchAll();

        foreach ($residents as $r) {
            $this->db->prepare(
                "INSERT INTO notifications (user_id, title, body, type)
                 VALUES (?,?,?,'announcement')"
            )->execute([$r['id'], $title, $body]);
        }

        $this->db->prepare("UPDATE announcements SET push_sent=1 WHERE id=?")->execute([$announcementId]);
    }
}

$ctrl   = new AnnouncementController();
$method = $_SERVER['REQUEST_METHOD'];
$id     = isset($_GET['id']) ? (int)$_GET['id'] : null;

AuthMiddleware::user();

match (true) {
    $method === 'GET'               => $ctrl->index(),
    $method === 'POST'              => $ctrl->store(),
    $method === 'DELETE' && $id     => $ctrl->delete($id),
    default => Response::error('Not found.', 404),
};
