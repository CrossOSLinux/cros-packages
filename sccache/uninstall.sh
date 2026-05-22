#!/bin/bash
set -e

echo "Removing sccache..."

if [ ! -f /usr/bin/sccache ]; then
  echo "sccache is not installed."
  exit 0
fi

sudo rm -f /usr/bin/sccache

echo "Done. sccache removed."
