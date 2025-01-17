#!/usr/bin/env bash

set -Eeuo pipefail

install_python2() {
  local FULL_VERSION

  ## Update cache
  apt-env.sh apt-get update -qq

  ## Search python2 version on repository if received version is approximately
  FULL_VERSION=$(apt-cache show python2 \
    | grep -E '^Version:' \
    | grep "2" \
    | sort -rV \
    | head -n1 \
    | awk '{print $2}' || echo '')

  ## Return 0 for Astra 1.8.x
  [[ -n ${FULL_VERSION} ]] || {
    echo "[WARNING]: Could not find python2 version matching '2'" >&2
    return 0
  }

  ## Install python2 with deps
  apt-install.sh \
    "python2=${FULL_VERSION}"

  ## Clean cache
  apt-clean.sh
}

install_python2

exit 0
