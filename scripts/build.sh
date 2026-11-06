#!/usr/bin/env bash
# build.sh - build the Docker image and run smoke tests
set -u
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

IMAGE="${IMAGE:-devops-tool}"
command -v docker >/dev/null 2>&1 || { echo "ERROR: docker is required"; exit 1; }

echo "== Building image: $IMAGE =="
docker build -t "$IMAGE" . || { echo "Build FAILED"; exit 1; }

failures=0
smoke() { # smoke <name> <expected-rc> <args...>
  local name="$1" want="$2"; shift 2
  docker run --rm "$IMAGE" "$@" >/dev/null 2>&1; local rc=$?
  if [[ $rc -eq $want ]]; then echo "PASS: $name"; else echo "FAIL: $name (exit $rc, expected $want)"; failures=$((failures+1)); fi
}

echo "== Smoke tests =="
smoke "help"                    0 help
smoke "system-info"             0 system-info
smoke "check-host localhost"    0 check-host localhost
smoke "invalid command -> 2"    2 invalid-command

if (( failures > 0 )); then echo "Smoke tests FAILED ($failures)"; exit 1; fi
echo "All smoke tests passed"
