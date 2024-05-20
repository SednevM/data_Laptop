drop schema lab05 cascade;

CREATE SCHEMA if not exists lab05;
set search_path = 'lab05';
CREATE TABLE if not exists fn
(
x float,
y float
);
INSERT INTO fn (x) SELECT random() * 10 FROM generate_series (1, 10000);
UPDATE fn SET y = sin(x);

--CREATE VIEW "check" AS SELECT * FROM fn ORDER BY x LIMIT 10;

ALTER TABLE fn ADD CONSTRAINT pk_x PRIMARY KEY (x);

CREATE VIEW roots AS SELECT round(x::numeric, 2 ) AS x FROM fn WHERE abs (y) < 0.0013 ORDER BY x;

CREATE VIEW positive AS SELECT x , y FROM fn WHERE y > 0.0;
--SELECT * FROM positive;

CREATE TABLE IF NOT EXISTS fn_backup AS SELECT * FROM fn;
--SELECT * FROM fn_backup ORDER BY x LIMIT 10;

CREATE RULE prevent_update AS ON UPDATE TO fn_backup DO INSTEAD NOTHING;
--SELECT * FROM pg_rules;

update positive set y = -y WHERE y < 0.5;
update fn SET y = sin(x);


--UPDATE fn_backup SET y = 0;
--SELECT * FROM fn_backup LIMIT 10;

DELETE FROM positive WHERE x > 2.0 AND x < 8.0;

DELETE FROM fn;
INSERT INTO fn SELECT * FROM fn_backup;

INSERT INTO positive (x) SELECT 10 + random() * 10 FROM generate_series(1, 10000);
UPDATE fn SET y = sin(x);
--SELECT * FROM positive;

CREATE EXTENSION file_fdw;
--SELECT * FROM pg_extension;

CREATE SERVER file_server FOREIGN DATA WRAPPER file_fdw;
CREATE FOREIGN TABLE fn_file(x float, y float) SERVER file_server
OPTIONS (filename 'C:\Program Files\sine.csv', format 'csv');
--DROP FOREIGN TABLE fn_file CASCADE;

EXPLAIN ANALYZE SELECT * FROM fn_file WHERE x > 10.0;
EXPLAIN ANALYZE SELECT * FROM fn WHERE x > 10.0;

CREATE MATERIALIZED VIEW fn_views AS SELECT * FROM fn_file WHERE x > 10 WITH NO DATA;

REFRESH MATERIALIZED VIEW fn_views;
SELECT * FROM fn_views;

--EXPLAIN ANALYZE SELECT * FROM fn_view;

--CREATE MATERIALIZED VIEW fn_all AS SELECT * FROM fn_file WITH DATA;
--SELECT count(*), 'file' FROM fn_file UNION SELECT count(*), 'mat. view' FROM fn_all;

--CREATE UNIQUE INDEX isx_coord ON fn_all USING btree(x);
--REFREsh MATERIALIZED VIEW CONCURRENTLY fn_all;

--CREATE SCHEMA lab05_view;
--ALTER TABLE fn SET SCHEMA lab05_view;
--ALTER MATERIALIZED VIEW fn_all SET SCHEMA lab05_view;
--ALTER TABLE fn_backup SET SCHEMA lab05_view;
--ALTER FOREIGN TABLE fn_file SET SCHEMA lab05_view;
--ALTER MATERIALIZED VIEW fn_view SET SCHEMA lab05_view;
--ALTER VIEW positive SET SCHEMA lab05_view;
--ALTER VIEW roots SET SCHEMA lab05_view;