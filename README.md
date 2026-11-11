# Assignment 3 – CI/CD with GitHub Actions

A Bash utility (`app/app.sh`) with linting, automated tests, a Docker image and a GitHub Actions pipeline. No cloud deployment.

## Setup
```bash
git clone <your-repository-url>
cd <repository>
chmod +x app/*.sh scripts/*.sh tests/*.sh grade.sh
```
Requirements: Linux, Bash, Docker (for the image checks).

## Usage
```bash
./app/app.sh system-info
./app/app.sh check-host localhost
./app/app.sh check-port localhost 22
./app/app.sh help
```
Exit codes: `0` success · `1` operational failure · `2` invalid command/input.

## Scripts
| Script | Purpose |
|---|---|
| `scripts/lint.sh` | checks required files + `bash -n` (+ ShellCheck if installed) |
| `tests/test.sh` | 12 tests: help, system-info, invalid/missing command, missing/valid/invalid host, missing/non-numeric/0/65536 port, closed port |
| `scripts/build.sh` | builds image `devops-tool` and runs smoke tests (help, system-info, check-host, invalid command) |

## Docker
```bash
docker build -t devops-tool .
docker run --rm devops-tool help
docker run --rm devops-tool system-info
docker compose run --rm app system-info
```

## CI pipeline (`.github/workflows/ci.yml`)
Triggers: `push` and `pull_request`.
```
validate  ->  test  ->  docker
```
`test` uses `needs: validate`; `docker` uses `needs: test`.

## CI failure demonstration
1. Branch `ci-failure-demo` created from `main`.
2. A syntax error was introduced in `app/app.sh` and pushed -> **`validate` failed**, so `test` and `docker` were skipped. (Run link: `<paste URL>`, commit `<hash>`)
3. The error was fixed and pushed -> all three jobs passed. (Run link: `<paste URL>`, commit `<hash>`)
4. The branch was merged into `main`; the final workflow on `main` is green.

## Testing locally
```bash
./scripts/lint.sh && ./tests/test.sh && ./scripts/build.sh
./grade.sh
```

## Assumptions
- `check-host` succeeds when the name resolves; `check-port` uses Bash `/dev/tcp`.
- Docker is installed and running for the build/smoke tests.
- No secrets are committed.
