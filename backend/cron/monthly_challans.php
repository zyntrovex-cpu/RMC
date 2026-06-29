#!/usr/bin/env php
<?php
/**
 * CRON: Run on 1st of every month at 00:05
 * Crontab: 5 0 1 * * php /var/www/backend/cron/monthly_challans.php >> /var/log/rmc_cron.log 2>&1
 */
require_once __DIR__ . '/../config/bootstrap.php';

$start = microtime(true);
$month = date('Y-m');

echo "[" . date('Y-m-d H:i:s') . "] Starting monthly challan generation for $month\n";

try {
    $result = ChallanHelper::generateMonthlyBatch(Database::get(), $month, 1);

    $db = Database::get();
    $overdue = $db->prepare(
        "UPDATE challans SET status='overdue'
         WHERE status='unpaid' AND due_date < CURDATE()"
    );
    $overdue->execute();
    $overdueCount = $overdue->rowCount();

    $blacklistStmt = $db->prepare(
        "UPDATE properties p
         SET p.blacklisted=1, p.blacklist_reason='3+ months outstanding dues'
         WHERE p.id IN (
             SELECT property_id FROM challans
             WHERE status IN ('unpaid','overdue')
             GROUP BY property_id
             HAVING COUNT(DISTINCT DATE_FORMAT(issue_date,'%Y-%m')) >= 3
         ) AND p.blacklisted=0"
    );
    $blacklistStmt->execute();
    $blacklisted = $blacklistStmt->rowCount();

    if (SMS_API_KEY) {
        sendDueReminders($db);
    }

    $duration = (int)((microtime(true) - $start) * 1000);
    $db->prepare(
        "INSERT INTO cron_log (job_name, status, details, duration_ms) VALUES ('monthly_challans', 'success', ?, ?)"
    )->execute([json_encode(array_merge($result, ['overdue_marked' => $overdueCount, 'blacklisted' => $blacklisted])), $duration]);

    echo "[" . date('Y-m-d H:i:s') . "] Done — Created: {$result['created']}, Overdue marked: $overdueCount, Blacklisted: $blacklisted\n";

} catch (\Exception $e) {
    Database::get()->prepare(
        "INSERT INTO cron_log (job_name, status, details) VALUES ('monthly_challans', 'failed', ?)"
    )->execute([json_encode(['error' => $e->getMessage()])]);
    echo "[" . date('Y-m-d H:i:s') . "] FAILED: " . $e->getMessage() . "\n";
    exit(1);
}

function sendDueReminders(PDO $db): void {
    $soon = date('Y-m-d', strtotime('+3 days'));
    $stmt = $db->prepare(
        "SELECT c.challan_no, c.total_amount, a.name as account,
                u.mobile, u.full_name
         FROM challans c
         JOIN accounts a ON a.id=c.account_id
         JOIN properties p ON p.id=c.property_id
         JOIN users u ON u.id=p.registered_user_id
         WHERE c.status IN ('unpaid','partial') AND c.due_date=?
           AND u.mobile IS NOT NULL"
    );
    $stmt->execute([$soon]);
    $rows = $stmt->fetchAll();
    foreach ($rows as $r) {
        echo "  SMS reminder → {$r['mobile']}: {$r['account']}\n";
    }
}
