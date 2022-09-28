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