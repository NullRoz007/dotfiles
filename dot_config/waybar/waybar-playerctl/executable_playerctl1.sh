#!/usr/bin/env bash

PLAYERCTL="playerctl"
STATE_FILE="/tmp/waybar_playerctl_player"

get_player() {
    [[ -f "$STATE_FILE" ]] && cat "$STATE_FILE"
}

set_player() {
    echo "$1" > "$STATE_FILE"
}

list_players() {
    $PLAYERCTL -l
}

select_player() {
    local chosen
    chosen=$(playerctl -l | walker --dmenu "Select player")

    [[ -n "$chosen" ]] && echo "$chosen" > "$STATE_FILE"
}

current_player_arg() {
    local p
    p=$(get_player)
    [[ -n "$p" ]] && echo "--player=$p"
}

status() {
    local player meta status

    player=$(get_player)

    if [[ -n "$player" ]]; then
        meta=$($PLAYERCTL --player="$player" metadata --format "{{artist}} - {{title}}" 2>/dev/null)
        status=$($PLAYERCTL --player="$player" status 2>/dev/null)
    else
        meta=$($PLAYERCTL metadata --format "{{artist}} - {{title}}" 2>/dev/null)
        status=$($PLAYERCTL status 2>/dev/null)
    fi

    [[ -z "$meta" ]] && meta="No media"

    icon="⏸"
    [[ "$status" == "Playing" ]] && icon="▶"

    echo "{\"text\":\"$icon $meta\",\"alt\":\"$status\"}"
}

toggle() {
    player=$(get_player)
    [[ -n "$player" ]] && playerctl --player="$player" play-pause || playerctl play-pause
}

next() {
    player=$(get_player)
    [[ -n "$player" ]] && playerctl --player="$player" next || playerctl next
}

prev() {
    player=$(get_player)
    [[ -n "$player" ]] && playerctl --player="$player" previous || playerctl previous
}
