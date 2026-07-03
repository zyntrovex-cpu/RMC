<?php
class AuthMiddleware {
    private static array $ALGO = ['HS256'];

    public static function user(): array {
        $token = self::extractToken();
        return self::decode($token);
    }

    public static function require(string ...$roles): array {
        $payload = self::user();
        if (!empty($roles) && !in_array($payload['role'], $roles, true)) {
            Response::error('Forbidden — insufficient permissions.', 403);
        }
        return $payload;
    }

    private static function extractToken(): string {
        $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
        if (preg_match('/Bearer\s+(.+)/i', $header, $m)) {
            return $m[1];
        }
        Response::error('Unauthorized — token missing.', 401);
    }

    private static function decode(string $token): array {
        [$header64, $payload64, $sig64] = array_pad(explode('.', $token), 3, '');

        $expected = self::sign($header64 . '.' . $payload64);
        if (!hash_equals($expected, $sig64)) {
            Response::error('Unauthorized — invalid token.', 401);
        }

        $payload = json_decode(self::b64Decode($payload64), true);
        if (!$payload || $payload['exp'] < time()) {
            Response::error('Unauthorized — token expired.', 401);
        }
        return $payload;
    }

    public static function generate(array $userData): string {
        $header  = self::b64Encode(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
        $payload = self::b64Encode(json_encode([
            'sub'  => $userData['id'],
            'name' => $userData['full_name'],
            'role' => $userData['role'],
            'iat'  => time(),
            'exp'  => time() + JWT_EXPIRY,
        ]));
        $sig = self::sign($header . '.' . $payload);
        return "$header.$payload.$sig";
    }

    private static function sign(string $data): string {
        return self::b64Encode(hash_hmac('sha256', $data, JWT_SECRET, true));
    }

    private static function b64Encode(string $data): string {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    private static function b64Decode(string $data): string {
        return base64_decode(strtr($data, '-_', '+/'));
    }
}
