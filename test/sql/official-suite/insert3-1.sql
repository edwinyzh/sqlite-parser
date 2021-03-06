-- original: insert3.test
-- credit:   http://www.sqlite.org/src/tree?ci=trunk&name=test

CREATE TABLE t1(a,b);
    CREATE TABLE log(x UNIQUE, y);
    CREATE TRIGGER r1 AFTER INSERT ON t1 BEGIN
      UPDATE log SET y=y+1 WHERE x=new.a;
      INSERT OR IGNORE INTO log VALUES(new.a, 1);
    END;
    INSERT INTO t1 VALUES('hello','world');
    INSERT INTO t1 VALUES(5,10);
    SELECT * FROM log ORDER BY x
;INSERT INTO t1 SELECT a, b+10 FROM t1;
    SELECT * FROM log ORDER BY x
;CREATE TABLE log2(x PRIMARY KEY,y);
    CREATE TRIGGER r2 BEFORE INSERT ON t1 BEGIN
      UPDATE log2 SET y=y+1 WHERE x=new.b;
      INSERT OR IGNORE INTO log2 VALUES(new.b,1);
    END;
    INSERT INTO t1 VALUES(453,'hi');
    SELECT * FROM log ORDER BY x
;SELECT * FROM log2 ORDER BY x
;INSERT INTO t1 SELECT * FROM t1;
      SELECT 'a:', x, y FROM log UNION ALL 
          SELECT 'b:', x, y FROM log2 ORDER BY x
;SELECT 'a:', x, y FROM log UNION ALL 
          SELECT 'b:', x, y FROM log2 ORDER BY x, y
;INSERT INTO t1(a) VALUES('xyz');
      SELECT * FROM log ORDER BY x
;CREATE TABLE t2(
      a INTEGER PRIMARY KEY,
      b DEFAULT 'b',
      c DEFAULT 'c'
    );
    CREATE TABLE t2dup(a,b,c);
    CREATE TRIGGER t2r1 BEFORE INSERT ON t2 BEGIN
      INSERT INTO t2dup(a,b,c) VALUES(new.a,new.b,new.c);
    END;
    INSERT INTO t2(a) VALUES(123);
    INSERT INTO t2(b) VALUES(234);
    INSERT INTO t2(c) VALUES(345);
    SELECT * FROM t2dup
;DELETE FROM t2dup;
    INSERT INTO t2(a) SELECT 1 FROM t1 LIMIT 1;
    INSERT INTO t2(b) SELECT 987 FROM t1 LIMIT 1;
    INSERT INTO t2(c) SELECT 876 FROM t1 LIMIT 1;
    SELECT * FROM t2dup
;CREATE TABLE t3(a,b,c);
    CREATE TRIGGER t3r1 BEFORE INSERT on t3 WHEN nosuchcol BEGIN
      SELECT 'illegal WHEN clause';
    END
;CREATE TABLE t4(a,b,c);
    CREATE TRIGGER t4r1 AFTER INSERT on t4 WHEN nosuchcol BEGIN
      SELECT 'illegal WHEN clause';
    END
;CREATE TABLE t5(
      a INTEGER PRIMARY KEY,
      b DEFAULT 'xyz'
    );
    INSERT INTO t5 DEFAULT VALUES;
    SELECT * FROM t5
;INSERT INTO t5 DEFAULT VALUES;
    SELECT * FROM t5
;CREATE TABLE t6(x,y DEFAULT 4.3, z DEFAULT x'6869');
      INSERT INTO t6 DEFAULT VALUES;
      SELECT * FROM t6
;SELECT name FROM sqlite_master WHERE type = 'table'
;DROP TABLE sub_tab
;CREATE TABLE t1(a, b, c);
    CREATE INDEX i1 ON t1(a, b);
    BEGIN;
    INSERT INTO t1 VALUES(randstr(10,400),randstr(10,400),randstr(10,400))
;INSERT INTO t1 SELECT sub_r, sub_r, sub_r FROM t1
;COMMIT
;PRAGMA cache_size = 10;
    BEGIN;
      UPDATE t1 SET a = randstr(10,10) WHERE (rowid%4)==0;
      DELETE FROM t1 WHERE rowid%2;
      INSERT INTO t1 SELECT randstr(10,400), randstr(10,400), c FROM t1;
    COMMIT;