#!/bin/bash
switchScreen="autorandr --change --force"
outcome=`$switchScreen | cut -f 1 -d " "`

if [ $outcome = 'docked' ]; then
    out=`setxkbmap -option caps:escape`
    out=`setxkbmap fi`
    out=`xmodmap ~/.Xmodmap.apple`
    out=`xset m 1 1`
    synclient TouchpadOff=0
else
    # Mobile, but also default
    out=`setxkbmap -option caps:escape`
    out=`setxkbmap fi`
    #out=`xinput --set-prop "PS/2 Generic Mouse" "Device Accel Constant Deceleration" 1`
    out=`xset m default`
fi

