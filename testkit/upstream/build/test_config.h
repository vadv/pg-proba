/* Build feature flags of the pgbouncer binary shipped in the harness image
 * (nixpkgs pgbouncer 1.26.1): TLS yes (TLS_server_method present in the
 * binary), LDAP no (no libldap symbols). Consumed only by
 * testkit/upstream/pgbouncer/utils.py at import (get_build_feature);
 * none of the vendored tests gate on these flags. */
#define USUAL_LIBSSL_FOR_TLS 1
