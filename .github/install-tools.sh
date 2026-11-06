#!/usr/bin/env bash
# install-tools.sh - install every game's tool on Ubuntu 24.04 (CI, or a fresh machine).
# The package for each game is listed in INSTALL.md.
set -euo pipefail
sudo=""; (( EUID == 0 )) || sudo=sudo
export DEBIAN_FRONTEND=noninteractive
$sudo apt-get update -q
$sudo apt-get install -y -q --no-install-recommends \
  bash python3 util-linux curl ca-certificates \
  mawk gawk busybox \
  bc dc cmake cpp g++ emacs-nox ghc gnuplot-nox jq m4 make ghostscript sed \
  apache2-bin sendmail-bin sqlite3 texlive-base groff-base vim xsltproc
