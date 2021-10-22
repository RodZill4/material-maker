#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$DIR/.."

pybabel extract \
	-F locale/babelrc \
	-k text \
	-k LineEdit/placeholder_text \
	-k tr \
	-o locale/material-maker.pot \
	.
