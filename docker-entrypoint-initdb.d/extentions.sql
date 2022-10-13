-- password のハッシュ化
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- slow query の特定
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- 行レベルの統計情報
CREATE EXTENSION IF NOT EXISTS pgstattuple;