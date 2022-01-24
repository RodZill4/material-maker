#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
cd "$(dirname "${BASH_SOURCE[0]}")"

for po in *.po; do
	echo -e "\nMerging $po..."
	msgmerge -w 79 -C "$po" "$po" material-maker.pot > "$po".new
	mv -f "$po".new "$po"
done
