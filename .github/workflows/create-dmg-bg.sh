#!/bin/bash

# ./create-dmg-bg.sh [IMAGE_PATH] [BG_OUT_PATH]

IMAGE_PATH="$1"
BG_OUT_PATH="$2"
bg_opacity="0.9"

rect_pos_a="158,210"
rect_pos_b="385,210"

rect_opacity="0.7"
arrow_shadow_blur="2" 
rect_shadow_blur="5"   
shadow_opacity="0.4"

roundrect="roundrectangle -60,-11 60,11, 3,3"
arrow="'M247.795861,184.47071 L290.200287,218.009412 C293.232498,220.407661 293.746425,224.809919 291.348175,227.84213 C291.011358,228.267982 290.626139,228.653201 290.200287,228.990018 L247.795497,262.529007 C244.763287,264.927257 240.361029,264.413331 237.962779,261.38112 C236.985055,260.144941 236.453122,258.614978 236.453082,257.038881 L236.452673,245.04637 C236.452575,241.180419 233.318555,238.046509 229.452604,238.046546 L161.141914,238.047178 C157.356462,238.047215 154.272786,235.042462 154.145907,231.287896 L154.141845,231.047178 L154.141845,215.952251 C154.141845,212.086285 157.275948,208.952289 161.141914,208.952251 L229.453446,208.951443 C233.319412,208.951405 236.453377,205.81741 236.453377,201.951443 L236.453446,189.961013 C236.453446,186.095019 239.587453,182.961013 243.453446,182.961013 C245.029604,182.961013 246.559635,183.492948 247.795861,184.47071 Z'"
arrow_pos="180,100"

magick $IMAGE_PATH \
-resize x330 \
-gravity center -crop 540x+0+0 \
-evaluate multiply "$bg_opacity" \
\( -size 540x330 xc:none -fill black -draw "translate $rect_pos_a $roundrect" -blur 0x$rect_shadow_blur -evaluate multiply $shadow_opacity \) -composite \
\( -size 540x330 xc:none -fill black -draw "translate $rect_pos_b $roundrect" -blur 0x$rect_shadow_blur -evaluate multiply $shadow_opacity \) -composite \
-fill white -draw "fill-opacity $rect_opacity translate $rect_pos_a $roundrect" \
-fill white -draw "fill-opacity $rect_opacity translate $rect_pos_b $roundrect" \
\( -size 800x800 xc:none -fill black -draw "translate $arrow_pos path $arrow" -scale 300x -blur 0x$arrow_shadow_blur  \) -composite \
\( -size 800x800 xc:none -fill white -draw "translate $arrow_pos path $arrow" -scale 300x \) -composite $BG_OUT_PATH