<?php
class Validator {
    private array $errors = [];
    private array $data;

    public function __construct(array $data) {
        $this->data = $data;
    }

    public function required(string $field, string $label = ''): static {
        $label = $label ?: $field;
        if (!isset($this->data[$field]) || trim((string)$this->data[$field]) === '') {
            $this->errors[$field] = "$label is required.";
        }
        return $this;
    }

    public function maxLen(string $field, int $max): static {
        if (isset($this->data[$field]) && strlen($this->data[$field]) > $max) {
            $this->errors[$field] = "$field must not exceed $max characters.";
        }
        return $this;
    }

    public function email(string $field): static {
        if (isset($this->data[$field]) && !filter_var($this->data[$field], FILTER_VALIDATE_EMAIL)) {
            $this->errors[$field] = "Invalid email address.";
        }
        return $this;
    }

    public function cnic(string $field): static {
        if (isset($this->data[$field]) && !preg_match('/^\d{5}-\d{7}-\d$/', $this->data[$field])) {
            $this->errors[$field] = "CNIC must be in format 12345-1234567-1.";
        }
        return $this;
    }

    public function numeric(string $field): static {
        if (isset($this->data[$field]) && !is_numeric($this->data[$field])) {
            $this->errors[$field] = "$field must be a number.";
        }
        return $this;
    }

    public function inList(string $field, array $list): static {
        if (isset($this->data[$field]) && !in_array($this->data[$field], $list, true)) {
            $this->errors[$field] = "Invalid value for $field.";
        }
        return $this;
    }

    public function fails(): bool {
        return count($this->errors) > 0;
    }

    public function errors(): array {
        return $this->errors;
    }

    public function get(string $field, mixed $default = null): mixed {
        return $this->data[$field] ?? $default;
    }

    public static function fromRequest(): static {
        $body = json_decode(file_get_contents('php://input'), true) ?? [];
        return new static(array_merge($_GET, $_POST, $body));
    }
}
