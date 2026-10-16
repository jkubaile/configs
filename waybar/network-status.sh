#!/usr/bin/env bash
# Combined Wi‑Fi / Ethernet + VPN status for Waybar.

set -euo pipefail

json_escape() {
    local s=$1
    s=${s//\\/\\\\}
    s=${s//\"/\\\"}
    s=${s//$'\n'/\\n}
    printf '%s' "$s"
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
                # Current AP: IN-USE is "*" 
                while IFS=: read -r inuse ssid sig _; do
                    if [[ "$inuse" == "*" ]]; then
                        signal=$sig
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
fi

if [[ -n "$iface" ]]; then
    ip4=$(nmcli -t -f IP4.ADDRESS device show "$iface" 2>/dev/null | head -1 | cut -d: -f2- || true)
    tooltip_lines+=("${iface}: ${ip4:-—}")
fi

text=$net_text
class=$net_class

if [[ -n "$vpn_text" ]]; then
    text="${net_text}  🔒 ${vpn_text}"
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
