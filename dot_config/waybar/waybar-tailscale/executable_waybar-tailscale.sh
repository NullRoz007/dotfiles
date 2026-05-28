#!/usr/bin/env bash

MENU_CMD=(walker --dmenu -p "Select exit node...")

tailscale_status() {
    tailscale status --json | jq -e '.BackendState == "Running"' > /dev/null
}

toggle_status() {
    if tailscale_status; then
        tailscale down
    else
        tailscale up
    fi
    sleep 5
}

select_exit_node() {
    if ! tailscale_status; then
        notify-send "Tailscale" "VPN is not running"
        return 1
    fi

    local nodes
    nodes=$(tailscale status --json | jq -r '
        .Peer[] | select(.ExitNodeOption == true) |
        .DNSName')

    nodes="Disabled"$'\n'"$nodes"

    local selected
    selected=$(echo "$nodes" | "${MENU_CMD[@]}")

    [ -z "$selected" ] || [[ "$selected" == "---"* ]] && return 0  

    if [[ "$selected" == "None"* ]]; then
        tailscale set --exit-node=
        notify-send "Tailscale" "Exit node disabled"
    else
        tailscale set --exit-node="$selected"
        notify-send "Tailscale" "Exit node set to: $selected"
    fi
}

case $1 in
    --status)
        if tailscale_status; then
            I="none"

            for arg in "${@:2}"; do
                arg_lower=$(echo "$arg" | tr '[:upper:]' '[:lower:]' | tr -d '\n')

                case "$arg_lower" in
                    ipv4|ipv6) 
                        I="$arg_lower" 
                        ;;
                esac
            done

            status_json=$(tailscale status --json)

            case "$I" in
                ipv4) ip_index="0" ;;
                ipv6) ip_index="-1" ;;
                *)    ip_index="" ;;
            esac

            if [[ -n "$ip_index" ]]; then
                peers=$(jq -r --arg Index "$ip_index" '
                    .Peer[]? | 
                    (if .Online then "● " else "○ " end) + 
                    (.DNSName | split(".")[0]) + " (" + .TailscaleIPs[$Index|tonumber] + ")"
                ' <<< "$status_json")
            else
                peers=$(jq -r '
                    .Peer[]? | 
                    (if .Online then "● " else "○ " end) + 
                    (.DNSName | split(".")[0])
                ' <<< "$status_json")
            fi

            exitnode=$(jq -r '.Peer[]? | select(.ExitNode == true).DNSName | split(".")[0]' <<< "$status_json")

            jq -nc --arg txt " exit-node: ${exitnode:-none}" --arg tip "$peers" \
                '{"text": $txt, "class": "connected", "alt": "connected", "tooltip": $tip}'
        else
            echo "{\"text\":\"\",\"class\":\"stopped\",\"alt\":\"stopped\", \"tooltip\": \"The VPN is not active.\"}"
        fi
    ;;
    --toggle)
        toggle_status
    ;;
    --select-exit-node)
        select_exit_node
    ;;
esac