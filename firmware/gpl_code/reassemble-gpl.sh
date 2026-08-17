#!/usr/bin/env bash
set -euo pipefail
cat gpl_5bigNetwork2.tar.part-* > gpl_5bigNetwork2.tar
sha256sum -c gpl_5bigNetwork2.tar.sha256
