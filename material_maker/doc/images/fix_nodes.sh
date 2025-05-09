#! /bin/env bash

for f in `git status . |grep png |sed "s/\s*modified:\s*//"`
do
    echo $f
    magick $f -alpha off -background transparent -fuzz 0.1% -transparent "#303236" $f
done