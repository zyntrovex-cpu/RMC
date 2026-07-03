<?php
class Response {
    public static function success(mixed $data = null, string $message = 'OK', int $code = 200): never {
        http_response_code($code);
        echo json_encode(['success' => true, 'message' => $message, 'data' => $data]);
        exit;
    }

    public static function error(string $message, int $code = 400, mixed $errors = null): never {
        http_response_code($code);
        echo json_encode(['success' => false, 'message' => $message, 'errors' => $errors]);
        exit;
    }

    public static function paginated(array $data, int $total, int $page, int $perPage): never {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'data'    => $data,
            'meta'    => [
                'total'      => $total,
                'page'       => $page,
                'per_page'   => $perPage,
                'last_page'  => (int) ceil($total / $perPage),
            ],
        ]);
        exit;
    }
}
