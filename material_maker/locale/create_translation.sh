#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
cd "$(dirname "${BASH_SOURCE[0]}")"

if [[ "$#" != 1 ]]; then
    echo "Usage: $0 <language code>"
    echo 'The language code should be of the form "fr", "de", ...'
    exit 1
fi

msginit --no-translator --input=material-maker.pot --locale="$1"
