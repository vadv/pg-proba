/* Minimal stub of pgbouncer's include/bouncer.h for the vendored test suite.
 * Upstream's test/utils.py reads this file at import time to learn the
 * compiled-in MAX_PASSWORD (real header: include/bouncer.h of the tag under
 * test). PKT_BUF_SIZE and friends are hardcoded in utils.py itself. */
#define MAX_PASSWORD 65531
