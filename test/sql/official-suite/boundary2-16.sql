-- original: boundary2.test
-- credit:   http://www.sqlite.org/src/tree?ci=trunk&name=test

SELECT a FROM t1 WHERE r >= -9.22337303685477580800e+18 ORDER BY x
;SELECT a FROM t1 WHERE r < -9.22337303685477580800e+18 ORDER BY a
;SELECT a FROM t1 WHERE r < -9.22337303685477580800e+18 ORDER BY a DESC
;SELECT a FROM t1 WHERE r < -9.22337303685477580800e+18 ORDER BY r
;SELECT a FROM t1 WHERE r < -9.22337303685477580800e+18 ORDER BY r DESC
;SELECT a FROM t1 WHERE r < -9.22337303685477580800e+18 ORDER BY x
;SELECT a FROM t1 WHERE r <= -9.22337303685477580800e+18 ORDER BY a
;SELECT a FROM t1 WHERE r <= -9.22337303685477580800e+18 ORDER BY a DESC
;SELECT a FROM t1 WHERE r <= -9.22337303685477580800e+18 ORDER BY r
;SELECT a FROM t1 WHERE r <= -9.22337303685477580800e+18 ORDER BY r DESC
;SELECT a FROM t1 WHERE r <= -9.22337303685477580800e+18 ORDER BY x
;DROP INDEX t1i1;
    DROP INDEX t1i2;
    DROP INDEX t1i3
;SELECT * FROM t1 WHERE r=72057594037927935
;SELECT r, a FROM t1 WHERE x='00ffffffffffffff'
;SELECT r, x FROM t1 WHERE a=17
;SELECT a FROM t1 WHERE r > 72057594037927935 ORDER BY a
;SELECT a FROM t1 WHERE r > 72057594037927935 ORDER BY a DESC
;SELECT a FROM t1 WHERE r > 72057594037927935 ORDER BY r
;SELECT a FROM t1 WHERE r > 72057594037927935 ORDER BY r DESC
;SELECT a FROM t1 WHERE r > 72057594037927935 ORDER BY x
;SELECT a FROM t1 WHERE r >= 72057594037927935 ORDER BY a
;SELECT a FROM t1 WHERE r >= 72057594037927935 ORDER BY a DESC
;SELECT a FROM t1 WHERE r >= 72057594037927935 ORDER BY r
;SELECT a FROM t1 WHERE r >= 72057594037927935 ORDER BY r DESC
;SELECT a FROM t1 WHERE r >= 72057594037927935 ORDER BY x
;SELECT a FROM t1 WHERE r < 72057594037927935 ORDER BY a
;SELECT a FROM t1 WHERE r < 72057594037927935 ORDER BY a DESC
;SELECT a FROM t1 WHERE r < 72057594037927935 ORDER BY r
;SELECT a FROM t1 WHERE r < 72057594037927935 ORDER BY r DESC
;SELECT a FROM t1 WHERE r < 72057594037927935 ORDER BY x
;SELECT a FROM t1 WHERE r <= 72057594037927935 ORDER BY a
;SELECT a FROM t1 WHERE r <= 72057594037927935 ORDER BY a DESC
;SELECT a FROM t1 WHERE r <= 72057594037927935 ORDER BY r
;SELECT a FROM t1 WHERE r <= 72057594037927935 ORDER BY r DESC
;SELECT a FROM t1 WHERE r <= 72057594037927935 ORDER BY x
;SELECT * FROM t1 WHERE r=16384
;SELECT r, a FROM t1 WHERE x='0000000000004000'
;SELECT r, x FROM t1 WHERE a=16
;SELECT a FROM t1 WHERE r > 16384 ORDER BY a
;SELECT a FROM t1 WHERE r > 16384 ORDER BY a DESC
;SELECT a FROM t1 WHERE r > 16384 ORDER BY r
;SELECT a FROM t1 WHERE r > 16384 ORDER BY r DESC
;SELECT a FROM t1 WHERE r > 16384 ORDER BY x
;SELECT a FROM t1 WHERE r >= 16384 ORDER BY a
;SELECT a FROM t1 WHERE r >= 16384 ORDER BY a DESC
;SELECT a FROM t1 WHERE r >= 16384 ORDER BY r
;SELECT a FROM t1 WHERE r >= 16384 ORDER BY r DESC
;SELECT a FROM t1 WHERE r >= 16384 ORDER BY x
;SELECT a FROM t1 WHERE r < 16384 ORDER BY a
;SELECT a FROM t1 WHERE r < 16384 ORDER BY a DESC
;SELECT a FROM t1 WHERE r < 16384 ORDER BY r
;SELECT a FROM t1 WHERE r < 16384 ORDER BY r DESC
;SELECT a FROM t1 WHERE r < 16384 ORDER BY x
;SELECT a FROM t1 WHERE r <= 16384 ORDER BY a
;SELECT a FROM t1 WHERE r <= 16384 ORDER BY a DESC
;SELECT a FROM t1 WHERE r <= 16384 ORDER BY r
;SELECT a FROM t1 WHERE r <= 16384 ORDER BY r DESC
;SELECT a FROM t1 WHERE r <= 16384 ORDER BY x
;SELECT * FROM t1 WHERE r=4294967296
;SELECT r, a FROM t1 WHERE x='0000000100000000'
;SELECT r, x FROM t1 WHERE a=36
;SELECT a FROM t1 WHERE r > 4294967296 ORDER BY a
;SELECT a FROM t1 WHERE r > 4294967296 ORDER BY a DESC
;SELECT a FROM t1 WHERE r > 4294967296 ORDER BY r
;SELECT a FROM t1 WHERE r > 4294967296 ORDER BY r DESC
;SELECT a FROM t1 WHERE r > 4294967296 ORDER BY x
;SELECT a FROM t1 WHERE r >= 4294967296 ORDER BY a
;SELECT a FROM t1 WHERE r >= 4294967296 ORDER BY a DESC
;SELECT a FROM t1 WHERE r >= 4294967296 ORDER BY r
;SELECT a FROM t1 WHERE r >= 4294967296 ORDER BY r DESC
;SELECT a FROM t1 WHERE r >= 4294967296 ORDER BY x
;SELECT a FROM t1 WHERE r < 4294967296 ORDER BY a
;SELECT a FROM t1 WHERE r < 4294967296 ORDER BY a DESC
;SELECT a FROM t1 WHERE r < 4294967296 ORDER BY r
;SELECT a FROM t1 WHERE r < 4294967296 ORDER BY r DESC
;SELECT a FROM t1 WHERE r < 4294967296 ORDER BY x
;SELECT a FROM t1 WHERE r <= 4294967296 ORDER BY a
;SELECT a FROM t1 WHERE r <= 4294967296 ORDER BY a DESC
;SELECT a FROM t1 WHERE r <= 4294967296 ORDER BY r
;SELECT a FROM t1 WHERE r <= 4294967296 ORDER BY r DESC
;SELECT a FROM t1 WHERE r <= 4294967296 ORDER BY x
;SELECT * FROM t1 WHERE r=16777216
;SELECT r, a FROM t1 WHERE x='0000000001000000'
;SELECT r, x FROM t1 WHERE a=6
;SELECT a FROM t1 WHERE r > 16777216 ORDER BY a
;SELECT a FROM t1 WHERE r > 16777216 ORDER BY a DESC
;SELECT a FROM t1 WHERE r > 16777216 ORDER BY r
;SELECT a FROM t1 WHERE r > 16777216 ORDER BY r DESC
;SELECT a FROM t1 WHERE r > 16777216 ORDER BY x
;SELECT a FROM t1 WHERE r >= 16777216 ORDER BY a
;SELECT a FROM t1 WHERE r >= 16777216 ORDER BY a DESC
;SELECT a FROM t1 WHERE r >= 16777216 ORDER BY r
;SELECT a FROM t1 WHERE r >= 16777216 ORDER BY r DESC
;SELECT a FROM t1 WHERE r >= 16777216 ORDER BY x
;SELECT a FROM t1 WHERE r < 16777216 ORDER BY a
;SELECT a FROM t1 WHERE r < 16777216 ORDER BY a DESC
;SELECT a FROM t1 WHERE r < 16777216 ORDER BY r
;SELECT a FROM t1 WHERE r < 16777216 ORDER BY r DESC
;SELECT a FROM t1 WHERE r < 16777216 ORDER BY x
;SELECT a FROM t1 WHERE r <= 16777216 ORDER BY a;