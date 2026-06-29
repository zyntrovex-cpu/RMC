<?php
class ChallanHelper {
    public static function generateNumber(string $accountCode, string $month, int $sequence): string {
        $year = substr($month, 0, 4);
        $mon  = substr($month, 5, 2);
        return sprintf('PNWHS-%s-%s-%s-%05d', $year, $mon, strtoupper($accountCode), $sequence);
    }

    public static function generateReceipt(int $sequence): string {
        return sprintf('RCP-%s-%06d', date('Ymd'), $sequence);
    }

    public static function nextSequence(PDO $db, string $accountCode, string $month): int {
        $year = substr($month, 0, 4);
        $mon  = substr($month, 5, 2);
        $prefix = sprintf('PNWHS-%s-%s-%s-', $year, $mon, strtoupper($accountCode));

        $stmt = $db->prepare(
            "SELECT MAX(CAST(SUBSTRING(challan_no, LENGTH(:prefix)+1) AS UNSIGNED))
             FROM challans WHERE challan_no LIKE :like"
        );
        $stmt->execute([':prefix' => $prefix, ':like' => $prefix . '%']);
        return ((int) $stmt->fetchColumn()) + 1;
    }

    public static function generateMonthlyBatch(PDO $db, string $month, int $adminId): array {
        $dueDate = date('Y-m-d', strtotime($month . ' +25 days'));

        $accounts = $db->query("SELECT * FROM accounts WHERE is_active = 1")->fetchAll();
        $properties = $db->query(
            "SELECT p.id, p.sector_id
             FROM properties p
             WHERE p.is_active = 1 AND p.facility_type = 'none'"
        )->fetchAll();

        $created = 0;
        $skipped = 0;

        foreach ($accounts as $account) {
            $seq = self::nextSequence($db, $account['code'], $month);

            foreach ($properties as $property) {
                $check = $db->prepare(
                    "SELECT id FROM dues WHERE property_id=? AND account_id=? AND due_month=?"
                );
                $check->execute([$property['id'], $account['id'], $month . '-01']);
                if ($check->fetchColumn()) { $skipped++; continue; }

                $arrStmt = $db->prepare(
                    "SELECT COALESCE(SUM(total_due - amount_paid), 0)
                     FROM dues
                     WHERE property_id=? AND account_id=? AND status IN ('unpaid','partial')"
                );
                $arrStmt->execute([$property['id'], $account['id']]);
                $arrears = (float) $arrStmt->fetchColumn();

                $amount = (float) $account['monthly_amount'];

                $db->prepare(
                    "INSERT INTO dues (property_id, account_id, due_month, amount, arrears, status)
                     VALUES (?, ?, ?, ?, ?, 'unpaid')"
                )->execute([$property['id'], $account['id'], $month . '-01', $amount, $arrears]);

                $dueId = (int) $db->lastInsertId();

                $challanNo = self::generateNumber($account['code'], $month, $seq);
                $db->prepare(
                    "INSERT INTO challans
                        (challan_no, due_id, property_id, account_id, issue_date, due_date, amount, arrears, total_amount, status, created_by)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'unpaid', ?)"
                )->execute([
                    $challanNo, $dueId, $property['id'], $account['id'],
                    date('Y-m-d'), $dueDate,
                    $amount, $arrears, $amount + $arrears,
                    $adminId
                ]);

                $db->prepare(
                    "INSERT INTO audit_log (user_id, action, entity_type, entity_id, new_value)
                     VALUES (?, 'challan.generate', 'challan', ?, ?)"
                )->execute([$adminId, $db->lastInsertId(), json_encode(['challan_no' => $challanNo])]);

                $seq++;
                $created++;
            }
        }

        return ['created' => $created, 'skipped' => $skipped, 'month' => $month];
    }
}
