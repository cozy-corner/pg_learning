SELECT * FROM pg_available_extensions WHERE name = 'pg_stat_statements';

-- docker-entrypoint-init.d 配下が反映されない
CREATE EXTENSION pg_stat_statements;

SELECT query, calls, total_time, rows
     FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;

--------------------------

query,calls,total_time,rows
"CREATE DATABASE ""sandbox""",1,245.366375,0
"select name, is_dst from pg_catalog.pg_timezone_names
union distinct
select abbrev as name, is_dst from pg_catalog.pg_timezone_abbrevs",1,49.111667,786
CREATE EXTENSION pg_stat_statements,1,13.960167,0
select * from pg_stat_statements,1,7.559375999999999,133
CREATE EXTENSION IF NOT EXISTS pgcrypto,1,6.462833,0
CREATE EXTENSION pg_stat_statements,1,2.849708,0
"/* contrib/pg_stat_statements/pg_stat_statements--1.4.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION


-- Register functions.
CREATE FUNCTION pg_stat_statements_reset()
RETURNS void
AS '$libdir/pg_stat_statements'
LANGUAGE C PARALLEL SAFE",1,2.107083,0
"-- Register a view on the function for ease of use.
CREATE VIEW pg_stat_statements AS
  SELECT * FROM pg_stat_statements(true)",1,2.091708,0
"SELECT query, calls, total_time, rows
     FROM pg_stat_statements ORDER BY total_time DESC LIMIT $1",2,1.749085,6
"-- Register a view on the function for ease of use.
CREATE VIEW pg_stat_statements AS
  SELECT * FROM pg_stat_statements(true)",1,1.525916,0
