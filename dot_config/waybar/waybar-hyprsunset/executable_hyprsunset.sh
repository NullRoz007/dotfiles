#!/bin/bash
if [ "$1" = "toggle" ]; then
  if pgrep -x hyprsunset >/dev/null; then
    pkill -x hyprsunset
    notify-send "Hyprsunset" "Disabled"
  else
    hyprsunset &
    notify-send "Hyprsunset" "Enabled"
  fi

  sleep 0.1
  pkill -RTMIN+10 waybar
fi

if pgrep -x hyprsunset > /dev/null; then
    echo '󰖔'
else
    echo '󰖙'
fi