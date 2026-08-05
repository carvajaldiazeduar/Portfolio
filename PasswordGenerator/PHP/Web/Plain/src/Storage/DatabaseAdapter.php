<?php
interface DatabaseAdapter {
    public function connect(): void;
    public function getAll(string $table): array;
    public function getById(string $table, int|string $id): ?array;
    public function create(string $table, array $data): int|string;
    public function update(string $table, int|string $id, array $data): bool;
    public function delete(string $table, int|string $id): bool;
    public function search(string $table, string $field, string $query): array;
}

