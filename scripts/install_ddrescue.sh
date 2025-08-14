#!/usr/bin/env bash
set -euo pipefail

# Cross-distro installer for GNU ddrescue (a.k.a. gddrescue)
# Usage: sudo ./scripts/install_ddrescue.sh

need_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script needs root privileges. Re-running with sudo..." >&2
    exec sudo -E bash "$0" "$@"
  fi
}

install_apt() {
  apt-get update -y
  # Debian/Ubuntu package name
  apt-get install -y --no-install-recommends gddrescue || \
  apt-get install -y --no-install-recommends ddrescue || true
}

install_dnf() {
  dnf install -y ddrescue || true
}

install_yum() {
  yum install -y ddrescue || true
}

install_pacman() {
  pacman -Sy --noconfirm ddrescue || true
}

install_zypper() {
  # openSUSE naming can vary
  zypper --non-interactive install ddrescue || \
  zypper --non-interactive install gnu_ddrescue || \
  zypper --non-interactive install gddrescue || true
}

install_apk() {
  apk update
  apk add --no-cache ddrescue || true
}

verify_install() {
  local dd_bin
  dd_bin=$(command -v ddrescue || true)
  if [[ -z "${dd_bin}" ]]; then
    # Rarely, some distros use a different binary name
    dd_bin=$(command -v gddrescue || true)
  fi
  if [[ -z "${dd_bin}" ]]; then
    echo "ERROR: ddrescue is not in PATH after installation." >&2
    exit 1
  fi
  echo "ddrescue installed at: ${dd_bin}"
  ${dd_bin} --version || true
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
    echo "ERROR: Unsupported package manager. Please install ddrescue manually." >&2
    exit 1
  fi

  verify_install

  cat <<EOF

GNU ddrescue installation complete.

ARM uses ddrescue automatically as a fallback if MakeMKV fails to rip.
If running in Docker, you can run this script inside the container to add ddrescue.
EOF
}

main "$@"


