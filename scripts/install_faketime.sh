#!/usr/bin/env bash
set -euo pipefail

# Simple cross-distro installer for libfaketime/faketime
# Usage: sudo ./scripts/install_faketime.sh

need_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script needs root privileges. Re-running with sudo..." >&2
    exec sudo -E bash "$0" "$@"
  fi
}

install_apt() {
  apt-get update -y
  # Try to install both packages if available; libfaketime usually provides /usr/bin/faketime
  apt-get install -y --no-install-recommends libfaketime faketime || \
  apt-get install -y --no-install-recommends libfaketime
}

install_dnf() {
  dnf install -y libfaketime || dnf install -y faketime || true
}

install_yum() {
  yum install -y libfaketime || yum install -y faketime || true
}

install_pacman() {
  pacman -Sy --noconfirm libfaketime || pacman -Sy --noconfirm faketime
}

install_zypper() {
  zypper --non-interactive install libfaketime || zypper --non-interactive install faketime || true
}

install_apk() {
  apk update
  apk add --no-cache libfaketime || true
}

verify_install() {
  local found_bin=false
  local found_lib=false

  if command -v faketime >/dev/null 2>&1; then
    found_bin=true
    echo "faketime wrapper installed at: $(command -v faketime)"
  else
    echo "faketime wrapper not found in PATH; checking for libfaketime shared library..."
  fi

  for candidate in \
    /usr/lib/x86_64-linux-gnu/faketime/libfaketime.so.1 \
    /usr/lib/faketime/libfaketime.so.1 \
    /usr/lib64/faketime/libfaketime.so.1 \
    /lib/x86_64-linux-gnu/faketime/libfaketime.so.1 \
    /lib64/faketime/libfaketime.so.1; do
    if [[ -e "$candidate" ]]; then
      echo "Found libfaketime at: $candidate"
      found_lib=true
      break
    fi
  done

  if [[ "$found_bin" == false && "$found_lib" == false ]]; then
    echo "ERROR: Could not find 'faketime' wrapper or libfaketime library after installation." >&2
    echo "Please check your distribution repositories or install libfaketime manually." >&2
    exit 1
  fi

  # Smoke test the wrapper if available (will print a shifted date)
  if [[ "$found_bin" == true ]]; then
    echo "Running a quick faketime smoke test:"
    faketime '2000-01-01 00:00:00' date || true
  fi

  cat <<EOF

libfaketime installation complete.

To enable faketime for MakeMKV in ARM, you can either:
- Set environment variable MAKEMKV_FAKETIME (e.g. \"2025-07-10 12:00:00\"), or
- In ARM config, set MAKEMKV_TIMEFAKE_ENABLED: true and set MAKEMKV_TIMEFAKE_VALUE.

ARM will automatically prefix MakeMKV calls with faketime if available.
EOF
}

main() {
  need_root "$@"

  if command -v apt-get >/dev/null 2>&1; then
    install_apt
  elif command -v dnf >/dev/null 2>&1; then
    install_dnf
  elif command -v yum >/dev/null 2>&1; then
    install_yum
  elif command -v pacman >/dev/null 2>&1; then
    install_pacman
  elif command -v zypper >/dev/null 2>&1; then
    install_zypper
  elif command -v apk >/dev/null 2>&1; then
    install_apk
  else
    echo "ERROR: Unsupported package manager. Please install libfaketime/faketime manually." >&2
    exit 1
  fi

  verify_install
}

main "$@"


