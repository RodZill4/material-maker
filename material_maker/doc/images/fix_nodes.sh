#! /bin/env bash

for f in `git status . |grep png |sed "s/\s*modified:\s*//"`
do
    echo $f
    magick $f \
    \( +clone -gravity center -shave 10x10 -bordercolor none -border 10x10 \) \
    \( -clone 0 -fuzz 1% -transparent "#303236" \) -delete 0 -composite $f
done