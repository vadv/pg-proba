#!/usr/bin/env bash
# Classify one feature's complete output; unavailable targets are never PASS.
set -eu
awk -v code="${1:?test exit code}" '
  /^UPSTREAM_NA / { unavailable=1 }
  /^UPSTREAM_UNADAPTED / { unadapted=1 }
  /[1-9][0-9]* scenarios? \(/ { executed=1 }
  END {
    if (code != 0) print "FAIL"
    else if (unadapted) print "UNADAPTED"
    else if (unavailable) print "N/A"
    else if (executed) print "PASS"
    else print "FAIL"
  }
'
