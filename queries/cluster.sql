DROP TABLE  IF EXISTS hoge;
CREATE TABLE hoge (a int, b int, c int);

INSERT INTO hoge VALUES (generate_series(1,9), (random() * 9)::int, generate_series(9,1,-1));

-- ctid 物理的な位置情報を保持しているカラム
SELECT ctid, * FROM hoge;
-- ctid,a,b,c
-- "(0,1)",1,8,9
-- "(0,2)",2,6,8
-- "(0,3)",3,3,7
-- "(0,4)",4,1,6
-- "(0,5)",5,4,5
-- "(0,6)",6,2,4
-- "(0,7)",7,2,3
-- "(0,8)",8,5,2
-- "(0,9)",9,7,1

ANALYZE hoge;

SELECT tablename, attname, correlation FROM pg_stats WHERE tablename = 'hoge';
-- 1 は昇順
-- -1 は降順
-- tablename,attname,correlation
-- hoge,a,1
-- hoge,b,-0.13333334
-- hoge,c,-1

CREATE INDEX ON hoge (a);
CREATE INDEX ON hoge (b);
CREATE INDEX ON hoge (c);

-- b で並べ替える
CLUSTER hoge USING hoge_b_idx;

SELECT ctid, * FROM hoge;
-- ctid,a,b,c
-- "(0,1)",4,1,6
-- "(0,2)",6,2,4
-- "(0,3)",7,2,3
-- "(0,4)",3,3,7
-- "(0,5)",5,4,5
-- "(0,6)",8,5,2
-- "(0,7)",2,6,8
-- "(0,8)",9,7,1
-- "(0,9)",1,8,9

CLUSTER hoge USING hoge_b_idx;
SELECT ctid, * FROM hoge;

-- b で並べ替えられている
-- ctid,a,b,c
-- "(0,1)",4,1,6
-- "(0,2)",6,2,4
-- "(0,3)",7,2,3
-- "(0,4)",3,3,7
-- "(0,5)",5,4,5
-- "(0,6)",8,5,2
-- "(0,7)",2,6,8
-- "(0,8)",9,7,1
-- "(0,9)",1,8,9

SELECT tablename, attname, correlation FROM pg_stats WHERE tablename = 'hoge';
-- 統計情報は ANALYZEしないと変わらない
-- tablename,attname,correlation
-- hoge,a,1
-- hoge,b,-0.13333334
-- hoge,c,-1

ANALYZE;

SELECT tablename, attname, correlation FROM pg_stats WHERE tablename = 'hoge';
-- tablename,attname,correlation
-- hoge,a,-0.13333334
-- hoge,b,1
-- hoge,c,0.13333334

drop table hoge;
commit;

-- チューニング
-------
CREATE TABLE fuga (a int, b text);

INSERT INTO fuga SELECT (random() * 100)::int, md5(clock_timestamp()::text) FROM generate_series(1,3000000);
CREATE INDEX ON fuga (a);

-- 検証用にサンプリング量を固定
ALTER TABLE fuga ALTER COLUMN a SET STATISTICS 10000;

ANALYZE fuga;

SELECT tablename, attname, correlation FROM pg_stats WHERE tablename = 'fuga' AND attname = 'a';

-- tablename,attname,correlation
-- fuga,a,0.010565036

SELECT * FROM fuga LIMIT 5;
-- a,b
-- 7,8c7bdd11c7715a29802bf60c0545a936
-- 22,0b36a385da5221319621dac19ab94397
-- 59,b75f9f99e8267e7516d86e5029df15c5
-- 31,f1d2cff1ae80784088ef0d3d65f470f3
-- 45,ed0f66f75a8d37d00794414052eafaec

EXPLAIN (ANALYZE, VERBOSE, BUFFERS) SELECT * FROM fuga WHERE a = 1;

-- 77~90ms
QUERY PLAN
Bitmap Heap Scan on public.fuga  (cost=564.16..27220.01 rows=29901 width=37) (actual time=17.840..76.645 rows=29901 loops=1)
"  Output: a, b"
  Recheck Cond: (fuga.a = 1)
  Heap Blocks: exact=17415
  Buffers: shared hit=6880 read=10620 written=1
  ->  Bitmap Index Scan on fuga_a_idx  (cost=0.00..556.69 rows=29901 width=0) (actual time=14.419..14.419 rows=29901 loops=1)
        Index Cond: (fuga.a = 1)
        Buffers: shared hit=85
Planning Time: 0.147 ms
Execution Time: 77.952 ms

QUERY PLAN
Bitmap Heap Scan on public.fuga  (cost=564.16..27220.01 rows=29901 width=37) (actual time=16.962..85.027 rows=29901 loops=1)
"  Output: a, b"
  Recheck Cond: (fuga.a = 1)
  Heap Blocks: exact=17415
  Buffers: shared hit=4620 read=12880
  ->  Bitmap Index Scan on fuga_a_idx  (cost=0.00..556.69 rows=29901 width=0) (actual time=11.475..11.475 rows=29901 loops=1)
        Index Cond: (fuga.a = 1)
        Buffers: shared hit=85
Planning Time: 0.094 ms
Execution Time: 86.348 ms

QUERY PLAN
Bitmap Heap Scan on public.fuga  (cost=564.16..27220.01 rows=29901 width=37) (actual time=12.469..93.578 rows=29901 loops=1)
"  Output: a, b"
  Recheck Cond: (fuga.a = 1)
  Heap Blocks: exact=17415 -- 読み込んだページ数
  Buffers: shared hit=1835 read=15665 written=1
  ->  Bitmap Index Scan on fuga_a_idx  (cost=0.00..556.69 rows=29901 width=0) (actual time=5.706..5.706 rows=29901 loops=1)
        Index Cond: (fuga.a = 1)
        Buffers: shared hit=85
Planning Time: 0.661 ms
Execution Time: 95.125 ms

-- ブロックIDが1~24999 の間に a = 1 のレコードが散らばっている
SELECT ctid, * FROM fuga WHERE a = 1 order by ctid asc LIMIT 5;
-- ctid,a,b
-- "(1,46)",1,3c2e2805b3005e839fb7a8114f9cdc93
-- "(3,15)",1,dfcb28afd232ca454c89a428bacf9e58
-- "(4,97)",1,c065b0c0ec73b37055a0042f9d9f0079
-- "(4,99)",1,64cac081996e8825700b174430d7dd65
-- "(4,115)",1,7ebf53a6e475e323d4e9ff002002ff3c

SELECT ctid, * FROM fuga WHERE a = 1 order by ctid desc LIMIT 5;
-- ctid,a,b
-- "(24999,84)",1,b4af90142311c40ab16ddd70285d92b9
-- "(24999,66)",1,e693e60e79dab2ca079fcc3c59e5a988
-- "(24999,39)",1,2a85f3a9c4b4f7779ac9b7509795aa36
-- "(24998,59)",1,605be2d44f5729b12b0ccd483868a4bf
-- "(24997,13)",1,0ee327b139673b899caab43b76bccdc2

SELECT relname, relpages FROM pg_class WHERE relname = 'fuga';
-- relname,relpages
-- fuga,25000

-- テーブル全体に満遍なく散らばっている
SELECT count(a) FROM fuga WHERE a = 1;
-- 29901

-- 17415ページに分散して格納されている
-- Heap Blocks: exact=17415

CLUSTER fuga USING fuga_a_idx;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS) SELECT * FROM fuga WHERE a = 1;

QUERY PLAN
Bitmap Heap Scan on public.fuga  (cost=564.16..27220.01 rows=29901 width=37) (actual time=2.269..11.610 rows=29901 loops=1)
"  Output: a, b"
  Recheck Cond: (fuga.a = 1)
  Heap Blocks: exact=250
  Buffers: shared hit=90 read=245
  ->  Bitmap Index Scan on fuga_a_idx  (cost=0.00..556.69 rows=29901 width=0) (actual time=2.224..2.224 rows=29901 loops=1)
        Index Cond: (fuga.a = 1)
        Buffers: shared hit=85
Planning Time: 0.094 ms
Execution Time: 13.555 ms

QUERY PLAN
Bitmap Heap Scan on public.fuga  (cost=564.16..27220.01 rows=29901 width=37) (actual time=7.356..11.744 rows=29901 loops=1)
"  Output: a, b"
  Recheck Cond: (fuga.a = 1)
  Heap Blocks: exact=250
  Buffers: shared hit=335
  ->  Bitmap Index Scan on fuga_a_idx  (cost=0.00..556.69 rows=29901 width=0) (actual time=7.314..7.314 rows=29901 loops=1)
        Index Cond: (fuga.a = 1)
        Buffers: shared hit=85
Planning Time: 0.086 ms
Execution Time: 14.666 ms

QUERY PLAN
Bitmap Heap Scan on public.fuga  (cost=564.16..27220.01 rows=29901 width=37) (actual time=1.686..5.956 rows=29901 loops=1)
"  Output: a, b"
  Recheck Cond: (fuga.a = 1)
  Heap Blocks: exact=250
  Buffers: shared hit=335
  ->  Bitmap Index Scan on fuga_a_idx  (cost=0.00..556.69 rows=29901 width=0) (actual time=1.645..1.645 rows=29901 loops=1)
        Index Cond: (fuga.a = 1)
        Buffers: shared hit=85
Planning Time: 0.094 ms
Execution Time: 8.575 ms

-- 8~15ms
-- 読み込むページ数が大きく減った
--   Heap Blocks: exact=250

-- 127~376の範囲に a = 1 が格納されている
-- 376-127-1=250
SELECT ctid, * FROM fuga WHERE a = 1 order by ctid asc LIMIT 5;
-- ctid,a,b
-- "(127,6)",1,3c2e2805b3005e839fb7a8114f9cdc93
-- "(127,7)",1,dfcb28afd232ca454c89a428bacf9e58
-- "(127,8)",1,c065b0c0ec73b37055a0042f9d9f0079
-- "(127,9)",1,64cac081996e8825700b174430d7dd65
-- "(127,10)",1,7ebf53a6e475e323d4e9ff002002ff3c

SELECT ctid, * FROM fuga WHERE a = 1 order by ctid desc LIMIT 5;
-- ctid,a,b
-- "(376,26)",1,b4af90142311c40ab16ddd70285d92b9
-- "(376,25)",1,e693e60e79dab2ca079fcc3c59e5a988
-- "(376,24)",1,2a85f3a9c4b4f7779ac9b7509795aa36
-- "(376,23)",1,605be2d44f5729b12b0ccd483868a4bf
-- "(376,22)",1,0ee327b139673b899caab43b76bccdc2
