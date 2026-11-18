-- PG fixtures for the vendored upstream pgbouncer suite
-- (testkit/upstream/pgbouncer/). Mirrors the pg-fixture from upstream
-- conftest.py @ pgbouncer_1_26_1, trimmed to what the seven vendored
-- test files actually use (no p2..p7, no longpass/LDAP users).
CREATE ROLE bouncer LOGIN;
CREATE ROLE pswcheck LOGIN SUPERUSER CREATEDB PASSWORD 'pgbouncer-check';
CREATE ROLE someuser LOGIN PASSWORD 'anypasswd';
CREATE ROLE test_error_message_user LOGIN;
SET password_encryption = 'md5';
CREATE ROLE muser1 LOGIN PASSWORD 'foo';
CREATE ROLE muser2 LOGIN PASSWORD 'wrong';
CREATE ROLE puser1 LOGIN PASSWORD 'foo';
CREATE ROLE puser2 LOGIN PASSWORD 'wrong';
SET password_encryption = 'scram-sha-256';
CREATE ROLE scramuser1 LOGIN PASSWORD 'SCRAM-SHA-256$4096:D76gvGUVj9Z4DNiGoabOBg==$RukL0Xo3Ql/2F9FsD7mcQ3GATG2fD3PA71qY1JagGDs=:BhKUwyyivFm7Tq2jDJVXSVRbRDgTWyBilZKgg6DDuYU=';
CREATE DATABASE p0;
CREATE DATABASE p1;
\connect p0
GRANT ALL ON SCHEMA public TO PUBLIC;
CREATE TABLE test_copy(i int);
GRANT ALL ON TABLE test_copy TO PUBLIC;
