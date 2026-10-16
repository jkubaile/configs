#!/usr/bin/env bash
# Combined Wi‑Fi / Ethernet + VPN status and traffic rates for Waybar.

set -euo pipefail

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-network-traffic"

json_escape() {
    local s=$1
    s=${s//\\/\\\\}
    s=${s//\"/\\\"}
    s=${s//$'\n'/\\n}
    printf '%s' "$s"
}

# Format bytes/s as compact rate (B, K, M, G).
human_rate() {
    local bytes=$1
    local abs=$bytes
    ((abs < 0)) && abs=$((-abs))
    if ((abs < 1024)); then
        printf '%dB' "$bytes"
    elif ((abs < 1048576)); then
        printf '%dK' "$((bytes / 1024))"
    elif ((abs < 1073741824)); then
        awk -v b="$bytes" 'BEGIN { printf "%.1fM", b / 1048576 }'
    else
        awk -v b="$bytes" 'BEGIN { printf "%.1fG", b / 1073741824 }'
    fi
}

traffic_text=""
calc_traffic() {
    local iface=$1
    local rx_path="/sys/class/net/${iface}/statistics/rx_bytes"
    local tx_path="/sys/class/net/${iface}/statistics/tx_bytes"
    [[ -r "$rx_path" && -r "$tx_path" ]] || return 0

    local rx tx now
    rx=$(<"$rx_path")
    tx=$(<"$tx_path")
    now=$(date +%s)

    local down_rate=0 up_rate=0
    if [[ -f "$STATE_FILE" ]]; then
        local prev_iface prev_rx prev_tx prev_ts
        IFS=' ' read -r prev_iface prev_rx prev_tx prev_ts <"$STATE_FILE" || true
        if [[ "$prev_iface" == "$iface" && -n "${prev_ts:-}" && "$now" -gt "$prev_ts" ]]; then
            local dt=$((now - prev_ts))
            down_rate=$(( (rx - prev_rx) / dt ))
            up_rate=$(( (tx - prev_tx) / dt ))
            ((down_rate < 0)) && down_rate=0
            ((up_rate < 0)) && up_rate=0
        fi
    fi

    printf '%s %s %s %s\n' "$iface" "$rx" "$tx" "$now" >"$STATE_FILE"
    traffic_text="⇩ $(human_rate "$down_rate") ⇧ $(human_rate "$up_rate")"
}

vpn_names=()
while IFS=: read -r name type; do
    case "$type" in
        vpn|wireguard) vpn_names+=("$name") ;;
    esac
done < <(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null || true)

vpn_text=""
if ((${#vpn_names[@]} > 0)); then
    vpn_text=$(IFS=' + '; echo "${vpn_names[*]}")
fi

net_text=""
net_class="disconnected"
tooltip_lines=()
iface=""
conn=""

while IFS=: read -r device type state connection; do
    [[ -z "$device" ]] && continue
    case "$type" in
        wifi|802-11-wireless)
            if [[ "$state" == "connected" ]]; then
                iface=$device
                conn=$connection
                signal=""
                while IFS=: read -r inuse ssid sig _; do
                    if [[ "$inuse" == "*" ]]; then
                        signal=$sig
                        ssid=${ssid//\\:/:}
                        [[ -n "$ssid" ]] && conn=$ssid
                        break
                    fi
                done < <(nmcli -t -f IN-USE,SSID,SIGNAL device wifi list ifname "$device" 2>/dev/null || true)

                if [[ -n "$signal" ]]; then
                    net_text="  ${conn} (${signal}%)"
                else
                    net_text="  ${conn}"
                fi
                net_class="wifi"
                break
            fi
            ;;
        ethernet)
            if [[ "$state" == "connected" ]]; then
                iface=$device
                conn=${connection:-$device}
                net_text="☍  ${conn}"
                net_class="ethernet"
                break
            fi
            ;;
    esac
done < <(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null || true)

if [[ -z "$net_text" ]]; then
    net_text="⚠  Offline"
    net_class="disconnected"
    rm -f "$STATE_FILE"
fi

if [[ -n "$iface" ]]; then
    calc_traffic "$iface"
    ip4=$(nmcli -t -f IP4.ADDRESS device show "$iface" 2>/dev/null | head -1 | cut -d: -f2- || true)
    tooltip_lines+=("${iface}: ${ip4:-—}")
    [[ -n "$traffic_text" ]] && tooltip_lines+=("Traffic: ${traffic_text}")
fi

text=$net_text
class=$net_class

if [[ -n "$traffic_text" ]]; then
    text="${net_text}  ${traffic_text}"
fi

if [[ -n "$vpn_text" ]]; then
    text="${text}  🔒 ${vpn_text}"
    class="${net_class} vpn"
    tooltip_lines+=("VPN: ${vpn_text}")
else
    tooltip_lines+=("Kein VPN")
fi

tooltip_lines+=("Links: WLAN/VPN wählen")
tooltip_lines+=("Rechts: Verbindungen bearbeiten")

tooltip=$(IFS=$'\n'; echo "${tooltip_lines[*]}")
printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
    "$(json_escape "$text")" \
    "$(json_escape "$tooltip")" \
    "$(json_escape "$class")"
