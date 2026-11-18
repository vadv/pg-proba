import psycopg
import pytest


def assert_missing_user(bouncer, dbname, user="postgres", password="asdasd"):
    # A working control login rules out an unavailable or misconfigured route.
    bouncer.test(dbname=dbname, user=user, password=password)
    with pytest.raises(
        psycopg.OperationalError,
        match=r"(?i)authentication failed|no .*user|not configured|not found|not allowed|invalid user",
    ):
        bouncer.test(dbname=dbname, user="nosuchuser", password="whatever")
    bouncer.test(dbname=dbname, user=user, password=password)

# Several tests that check the behavior when connecting with a
# nonexistent user under various authentication types.  Database p1
# has a forced user, p2 does not; these exercise slightly different
# code paths.


def test_no_user_trust(bouncer):
    assert_missing_user(bouncer, "p2")

def test_no_user_trust_forced_user(bouncer):
    assert_missing_user(bouncer, "p1")

def test_no_user_password(bouncer):
    assert_missing_user(bouncer, "p2")


def test_no_user_password_forced_user(bouncer):
    assert_missing_user(bouncer, "p1")


def test_no_user_md5(bouncer):
    assert_missing_user(bouncer, "p2")

def test_no_user_md5_forced_user(bouncer):
    assert_missing_user(bouncer, "p1")

def test_no_user_scram(bouncer):
    assert_missing_user(bouncer, "p2")

def test_no_user_scram_forced_user(bouncer):
    assert_missing_user(bouncer, "p1")

def test_no_user_auth_user(bouncer):
    assert_missing_user(bouncer, "authdb", "someuser", "anypasswd")


def test_no_user_auth_user_null_row(bouncer):
    """
    An auth_query that reports a missing user as a null value rather
    than with no rows must be treated the same as one returning no
    rows.  The user_lookup() example in the documentation behaves this
    way.
    """
    assert_missing_user(bouncer, "authdb", "someuser", "anypasswd")
