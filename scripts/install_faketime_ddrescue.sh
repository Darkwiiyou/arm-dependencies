#!/bin/bash

# Install dependencies for faketime and ddrescue used by ARM's MakeMKV fallback/wrapping

set -euo pipefail

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo -e "${GREEN}Updating apt metadata${NC}"
apt-get update -yq

echo -e "${GREEN}Installing faketime (libfaketime) and ddrescue (gddrescue)${NC}"
# Prefer Debian/Ubuntu package names
PACKAGES=(libfaketime gddrescue)
apt-get install -yq --no-install-recommends "${PACKAGES[@]}" || true

# Fallback try: some distros may use alternative names
if ! command -v faketime >/dev/null 2>&1; then
  echo -e "${YELLOW}faketime not found after install; attempting to install 'faketime' package name${NC}"
  apt-get install -yq --no-install-recommends faketime || true
fi

if ! command -v ddrescue >/dev/null 2>&1 && ! command -v gddrescue >/dev/null 2>&1; then
  echo -e "${YELLOW}ddrescue not found after install; attempting to install 'ddrescue' package name${NC}"
  apt-get install -yq --no-install-recommends ddrescue || true
fi

# Verify installation
if command -v faketime >/dev/null 2>&1; then
  echo -e "${GREEN}faketime available: $(command -v faketime)${NC}"
else
  echo -e "${RED}faketime not available. libfaketime may still be present via LD_PRELOAD at /usr/lib*/faketime/libfaketime.so.1${NC}"
fi

if command -v ddrescue >/dev/null 2>&1; then
  echo -e "${GREEN}ddrescue available: $(command -v ddrescue)${NC}"
elif command -v gddrescue >/dev/null 2>&1; then
  echo -e "${GREEN}gddrescue available: $(command -v gddrescue)${NC}"
else
  echo -e "${RED}Neither ddrescue nor gddrescue found after installation.${NC}"
fi

echo -e "${GREEN}Cleaning up apt cache${NC}"
apt-get autoremove -yq || true
apt-get clean -yq || true
rm -rf /var/lib/apt/lists/* || true

echo -e "${GREEN}Dependency installation complete${NC}"


