#!/bin/bash
# apt.sh — apt helpers with lock waiting and conservative retry defaults.

APT_LOCK_TIMEOUT="${APT_LOCK_TIMEOUT:-180}"
APT_RETRIES="${APT_RETRIES:-3}"
APT_FORCE_IPV4="${APT_FORCE_IPV4:-1}"
APT_LOCKS=(
  /var/lib/dpkg/lock-frontend
  /var/lib/dpkg/lock
  /var/cache/apt/archives/lock
  /var/lib/apt/lists/lock
)

apt_lock_pids() {
  command -v fuser &>/dev/null || return 0
  for lock in "${APT_LOCKS[@]}"; do
    [[ -e "$lock" ]] || continue
    $SUDO fuser "$lock" 2>/dev/null || true
  done | tr ' ' '\n' | sed '/^$/d' | sort -u
}

apt_print_lock_holders() {
  local -a pids
  mapfile -t pids < <(apt_lock_pids)
  [[ "${#pids[@]}" -gt 0 ]] || return 0

  echo "Apt/dpkg lock holder(s):" >&2
  ps -o pid=,ppid=,etime=,command= -p "${pids[@]}" >&2 || true
}

wait_for_apt_locks() {
  local start now
  local -a pids
  start="$(date +%s)"

  while mapfile -t pids < <(apt_lock_pids); [[ "${#pids[@]}" -gt 0 ]]; do
    now="$(date +%s)"
    if (( now - start >= APT_LOCK_TIMEOUT )); then
      echo "Timed out waiting ${APT_LOCK_TIMEOUT}s for apt/dpkg locks." >&2
      apt_print_lock_holders
      return 1
    fi
    echo "Waiting for apt/dpkg lock..." >&2
    apt_print_lock_holders
    sleep 5
  done
}

apt_get() {
  local opts=(
    -o "DPkg::Lock::Timeout=$APT_LOCK_TIMEOUT"
    -o "Acquire::Retries=$APT_RETRIES"
  )
  [[ "$APT_FORCE_IPV4" == "1" ]] && opts+=(-o "Acquire::ForceIPv4=true")

  wait_for_apt_locks
  $SUDO apt-get "${opts[@]}" "$@"
}

apt_update() {
  apt_get update -qq
}

apt_install() {
  apt_get install -y "$@"
}

apt_package_current() {
  local package="$1" installed candidate
  installed="$(dpkg-query -W -f='${Version}' "$package" 2>/dev/null || true)"
  candidate="$(apt-cache policy "$package" 2>/dev/null | awk '/Candidate:/ {print $2}')"
  [[ -n "$installed" && -n "$candidate" && "$installed" == "$candidate" ]]
}
