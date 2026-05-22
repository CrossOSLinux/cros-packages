#!/bin/bash
set -e

echo "Removing pup..."

if [ ! -f /usr/bin/pup ]; then
  echo "pup is not installed."
  exit 0
fi

sudo rm -f /usr/bin/pup

echo "Done. pup removed."
