<?php
require_once __DIR__ . '/DatabaseAdapter.php';
require_once __DIR__ . '/Adapters/PostgreSQL.php';
require_once __DIR__ . '/Adapters/MySQL.php';
require_once __DIR__ . '/Adapters/SQLite.php';
require_once __DIR__ . '/Adapters/SQLServer.php';
require_once __DIR__ . '/Adapters/MongoDB.php';

class DatabaseFactory {
    public static function create(): DatabaseAdapter {
        $driver = getenv('DB_DRIVER') ?: 'pgsql';
        return match ($driver) {
            'pgsql' => new PostgreSQL(),
            'mysql' => new MySQL(),
            'sqlite' => new SQLite(),
            'sqlserver', 'mssql' => new SQLServer(),
            'mongodb' => new MongoDB(),
            default => throw new InvalidArgumentException("Unsupported DB driver: $driver"),
        };
    }
}
