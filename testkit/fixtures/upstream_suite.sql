-- Подготовка PG для вендоренного upstream-сьюта pgbouncer
-- (testkit/upstream/pgbouncer/). Зеркалирует pg-fixture из upstream
-- conftest.py @ pgbouncer_1_26_1 — только то, что нужно 7 файлам.

create database p0;
create database p1;

\c p0
grant all on schema public to public;
create table test_copy(i int);
grant all on table test_copy to public;

\c postgres
create user bouncer;
create user pswcheck with superuser createdb password 'pgbouncer-check';
create user someuser with password 'anypasswd';
set password_encryption to md5;
create user puser1 password 'foo';
create user puser2 password 'wrong';
create user muser1 password 'foo';
create user muser2 password 'wrong';
set password_encryption to 'scram-sha-256';
create user scramuser1 password 'foo';
create user scramuser2 password 'wrong';
create user scramuser3 password 'foo';
