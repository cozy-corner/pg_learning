set schema 'public';

drop table if exists testa;
create table testa (
  id numeric,
  txt varchar(10)
);

-- indexの肥大化
insert into testa(id, txt) select i, '0123456789' from generate_series(1, 5000000) as i;
create unique index idx_testa01 on testa(id);

select relname, relpages from pg_class where relname in ('testa', 'idx_testa01');
-- relname,relpages
-- testa,31838
-- idx_testa01,13713

delete from testa where id between 1 and 4000000;

--------------------
-- vacuum full
-- vacuum full testa;
-- select relname, relpages from pg_class where relname in ('testa', 'idx_testa01');
-- vaccum full はインデックスも回収される?
-- relname,relpages
-- testa,6370
-- idx_testa01,2745
--------------------
-- vacuum
-- vacuum testa;
-- select relname, relpages from pg_class where relname in ('testa', 'idx_testa01');
-- relname,relpages
-- testa,31838
-- idx_testa01,13713
--------------------

-- 以下
vacuum analyze testa;
select relname, relpages from pg_class where relname in ('testa', 'idx_testa01');
-- relname,relpages
-- testa,31838
-- idx_testa01,13713

-- postgres 12 以降 明示的に indexの再改修を offにする
-- vacuum ("index_cleanup" true, analyze, verbose) testa;

insert into testa(id, txt) select i, '0123456789' from generate_series(5000001, 10000000) as i;
select relname, relpages from pg_class where relname in ('testa', 'idx_testa01');
-- relname,relpages
-- testa,31838
-- idx_testa01,13713

delete from testa where id between 5000001 and 9000000;
select relname, relpages from pg_class where relname in ('testa', 'idx_testa01');
-- インデックスが増えるはずが増えない
-- relname,relpages
-- testa,31838
-- idx_testa01,13713


reindex index idx_testa01;
select relname, relpages from pg_class where relname in ('testa', 'idx_testa01');
-- indexが減少した
-- relname,relpages
-- testa,38218
-- idx_testa01,5487


