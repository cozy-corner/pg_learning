-- password のハッシュ化
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- slow query の特定
CREATE EXTENSION pg_stat_statements;