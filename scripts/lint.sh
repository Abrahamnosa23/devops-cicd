#!/usr/bin/env bash
# lint.sh - checks required files exist and Bash syntax is valid (ShellCheck if installed)
set -u
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

errors=0
REQUIRED=(README.md app/app.sh scripts/lint.sh scripts/build.sh tests/test.sh
          Dockerfile compose.yaml .dockerignore .github/workflows/ci.yml grade.sh)

echo "== Checking required files =="
for f in "${REQUIRED[@]}"; do
  if [[ -f "$f" ]]; then echo "OK   $f"; else echo "MISSING $f"; errors=$((errors+1)); fi
done

echo "== bash -n syntax check =="
shopt -s nullglob
for f in app/*.sh scripts/*.sh tests/*.sh grade.sh; do
  if bash -n "$f"; then echo "OK   $f"; else echo "SYNTAX ERROR $f"; errors=$((errors+1)); fi
done

echo "== ShellCheck (optional) =="
if command -v shellcheck >/dev/null 2>&1; then
  for f in app/*.sh scripts/*.sh tests/*.sh; do
    if shellcheck -S warning "$f"; then echo "OK   $f"; else echo "SHELLCHECK WARNINGS $f"; errors=$((errors+1)); fi
  done
else
  echo "shellcheck not installed - skipped"
fi

if (( errors > 0 )); then echo "Lint FAILED with $errors problem(s)"; exit 1; fi
echo "Lint passed"
