#!/usr/bin/env bash
# tests/test.sh - tests for app/app.sh
set -u
APP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/app/app.sh"
PASS=0; FAIL=0

# check <name> <expected-rc> <expected-output-regex or -> <args...>
check() {
  local name="$1" want="$2" pattern="$3"; shift 3
  local out rc
  out="$("$APP" "$@" 2>&1)"; rc=$?
  if [[ $rc -ne $want ]]; then
    echo "FAIL: $name (exit $rc, expected $want)"; FAIL=$((FAIL+1)); return
  fi
  if [[ "$pattern" != "-" ]] && ! grep -Eqi "$pattern" <<<"$out"; then
    echo "FAIL: $name (output did not match /$pattern/)"; FAIL=$((FAIL+1)); return
  fi
  echo "PASS: $name"; PASS=$((PASS+1))
}

check "help shows usage"                    0 "usage"            help
check "system-info shows kernel"            0 "kernel"           system-info
check "no command returns 2"                2 "no command"
check "unknown command returns 2"           2 "unknown command"  bogus
check "check-host without host returns 2"   2 "requires"         check-host
check "check-host localhost succeeds"       0 "resolves"         check-host localhost
check "check-host invalid host returns 2"   2 "invalid"          check-host 'bad host!'
check "check-port without port returns 2"   2 "port"             check-port localhost
check "check-port non-numeric port -> 2"    2 "port"             check-port localhost abc
check "check-port port 0 -> 2"              2 "port"             check-port localhost 0
check "check-port port 65536 -> 2"          2 "port"             check-port localhost 65536
check "check-port closed port -> 1"         1 "closed"           check-port localhost 1

echo
echo "Passed: $PASS  Failed: $FAIL"
[[ $FAIL -eq 0 ]]
