#!/usr/bin/env bash
# app.sh - small DevOps utility used for the CI/CD assignment
# Exit codes: 0 success, 1 operational failure, 2 invalid command/input
set -u

usage() {
  cat <<'USAGE'
Usage: app.sh <command> [arguments]

Commands:
  system-info              Display system information
  check-host <host>        Resolve and check a hostname or IP
  check-port <host> <port> Check TCP connectivity (port 1-65535)
  help                     Show this help

Exit codes: 0 success | 1 operational failure | 2 invalid input
USAGE
}

err() { echo "ERROR: $*" >&2; }

valid_host() {
  local h="$1" o
  [[ -n "$h" && ${#h} -le 253 ]] || return 1
  if [[ "$h" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
    local IFS=.
    for o in $h; do (( 10#$o <= 255 )) || return 1; done
    return 0
  fi
  if [[ "$h" == *:* ]]; then [[ "$h" =~ ^[0-9A-Fa-f:.]+$ ]]; return; fi
  [[ "$h" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$ ]]
}

valid_port() { [[ "$1" =~ ^[0-9]{1,5}$ ]] && (( 10#$1 >= 1 && 10#$1 <= 65535 )); }

resolve_host() { getent ahosts "$1" 2>/dev/null | awk 'NR==1 {print $1}'; }

cmd_system_info() {
  local os cpu
  if [[ -r /etc/os-release ]]; then
    # shellcheck source=/dev/null
    os="$( . /etc/os-release; echo "${PRETTY_NAME:-unknown}" )"
  else
    os="$(uname -s)"
  fi
  cpu="$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2- | sed 's/^ *//')"
  echo "=== System Information ==="
  echo "Hostname         : $(hostname 2>/dev/null || uname -n)"
  echo "Current user     : $(id -un 2>/dev/null || echo unknown)"
  echo "Date/Time        : $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "Operating system : $os"
  echo "Kernel           : $(uname -r)"
  echo "Uptime           : $(uptime 2>/dev/null | sed 's/^ *//')"
  echo "CPU              : ${cpu:-unknown} ($(nproc 2>/dev/null || echo '?') core(s))"
}

cmd_check_host() {
  [[ $# -ge 1 ]] || { err "check-host requires a <host> argument"; return 2; }
  [[ $# -eq 1 ]] || { err "check-host takes exactly one argument"; return 2; }
  valid_host "$1" || { err "invalid hostname or IP: '$1'"; return 2; }
  local ip; ip="$(resolve_host "$1")"
  if [[ -z "$ip" ]]; then err "cannot resolve '$1'"; return 1; fi
  echo "Host $1 resolves to $ip"
}

cmd_check_port() {
  [[ $# -ge 1 ]] || { err "check-port requires <host> and <port>"; return 2; }
  [[ $# -ge 2 ]] || { err "check-port requires a <port> argument"; return 2; }
  [[ $# -eq 2 ]] || { err "check-port takes exactly two arguments"; return 2; }
  local host="$1" port="$2"
  valid_port "$port" || { err "port must be an integer from 1 to 65535 (got '$port')"; return 2; }
  valid_host "$host" || { err "invalid hostname or IP: '$host'"; return 2; }
  # shellcheck disable=SC2016
  if timeout 3 bash -c 'exec 3<>"/dev/tcp/$1/$2"' _ "$host" "$port" 2>/dev/null; then
    echo "TCP $host:$port is OPEN"
  else
    echo "TCP $host:$port is CLOSED or unreachable"
    return 1
  fi
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    help|-h|--help) usage; return 0 ;;
    system-info)    shift; [[ $# -eq 0 ]] || { err "system-info takes no arguments"; return 2; }; cmd_system_info ;;
    check-host)     shift; cmd_check_host "$@" ;;
    check-port)     shift; cmd_check_port "$@" ;;
    "")             err "no command given"; usage >&2; return 2 ;;
    *)              err "unknown command: '$cmd'"; usage >&2; return 2 ;;
  esac
}

main "$@"
exit $?
