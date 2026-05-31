#!/usr/bin/env bash

PLAYERCTL="playerctl"
STATE_FILE="/tmp/waybar_playerctl_player"

# --- truncate helper ---
truncate() {
    local str="$1"
    local max=24

    # length check
    if [[ ${#str} -le $max ]]; then
        echo "$str"
    else
        echo "${str:0:$((max - 3))}..."
    fi
}

get_player() {
    [[ -f "$STATE_FILE" ]] && cat "$STATE_FILE"
}

status() {
    local player meta state display

    player=$(get_player)

    # fallback to any active player
    if [[ -z "$player" ]]; then
        player=$(playerctl -l 2>/dev/null | head -n1)
    fi

    state=$(playerctl --player="$player" status 2>/dev/null)
    meta=$(playerctl --player="$player" metadata --format "{{artist}} - {{title}}" 2>/dev/null)

    [[ -z "$meta" ]] && meta="No media"
    [[ -z "$state" ]] && state="Stopped"

    meta=$(truncate "$meta")

    icon=""
    [[ "$state" == "Playing" ]] && icon=""

    display="$icon $meta"

    echo "{\"text\":\"$display\",\"alt\":\"$state\"}"
}

toggle() {
    local player state

    player=$(get_player)

    # fallback
    if [[ -z "$player" ]]; then
        player=$(playerctl -l 2>/dev/null | head -n1)
    fi

    state=$(playerctl --player="$player" status 2>/dev/null)

    # if playing → just pause current
    if [[ "$state" == "Playing" ]]; then
        playerctl --player="$player" pause
        return
    fi

    # if paused/stopped → pause everything else first
    pause_others "$player"

    # then play selected player
    playerctl --player="$player" play
}

pause_others() {
    local current="$1"
    local p

    for p in $(playerctl -l 2>/dev/null); do
        if [[ "$p" != "$current" ]]; then
            playerctl --player="$p" pause 2>/dev/null
        fi
    done
}

next() {
    player=$(get_player)
    [[ -n "$player" ]] && playerctl --player="$player" next || playerctl next
}

prev() {
    player=$(get_player)
    [[ -n "$player" ]] && playerctl --player="$player" previous || playerctl previous
}

select_player() {
    player=$(playerctl -l | walker --dmenu "Select player")
    [[ -n "$player" ]] && echo "$player" > "$STATE_FILE"
}

menu() {
    local choice

    choice=$(printf "%s\n" \
        "▶ Play/Pause" \
        "⏭  Next" \
        "⏮  Previous" \
        "⏹  Stop" \
        "Select Player" \
        "List Players" \
        | walker --dmenu "Playerctl")

    case "$choice" in
        "▶ Play/Pause") toggle ;;
        "⏭  Next") next ;;
        "⏮  Previous") prev ;;
        "⏹  Stop")
            player=$(get_player)
            [[ -n "$player" ]] && playerctl --player="$player" stop || playerctl stop
            ;;
        "Select Player") select_player ;;
        "List Players") playerctl -l | walker --dmenu "Active Players" ;;
    esac
}

case "$1" in
    status) status ;;
    toggle) toggle ;;
    next) next ;;
    prev) prev ;;
    select_player) select_player ;;
    menu) menu ;;
    *)
        echo "{\"text\":\"no cmd\",\"alt\":\"error\"}"
        ;;
esac
