#!/usr/bin/env bash
# Rofi menu: Wi‑Fi networks + VPN / WireGuard profiles.
# Entry format: "W✓ SSID (42%)" / "W○ SSID (42%)" / "V✓ name" / "V○ name"

set -euo pipefail
shopt -s extglob

notify() {
    notify-send -a waybar "Netzwerk" "$1" 2>/dev/null || true
}

active_vpns=()
while IFS=: read -r name type; do
    case "$type" in
        vpn|wireguard) active_vpns+=("$name") ;;
    esac
done < <(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null || true)

vpn_active() {
    local c=$1 a
    for a in "${active_vpns[@]+"${active_vpns[@]}"}"; do
        [[ "$a" == "$c" ]] && return 0
    done
    return 1
}

wifi_dev=""
while IFS=: read -r device type state _; do
    if [[ "$type" == "wifi" || "$type" == "802-11-wireless" ]]; then
        wifi_dev=$device
        break
    fi
done < <(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null || true)

entries=()

entries+=("── WLAN ──")
if [[ -n "$wifi_dev" ]]; then
    nmcli device wifi rescan ifname "$wifi_dev" >/dev/null 2>&1 || true
    sleep 0.3

    declare -A seen_ssid=()
    while IFS=: read -r inuse ssid signal _; do
        # nmcli escapes ':' in SSIDs as '\:' — unescape for display/connect
        ssid=${ssid//\\:/:}
        [[ -z "$ssid" ]] && continue
        [[ -n "${seen_ssid[$ssid]+x}" ]] && continue
        seen_ssid[$ssid]=1
        if [[ "$inuse" == "*" ]]; then
            entries+=("W✓ ${ssid} (${signal:-?}%)")
        else
            entries+=("W○ ${ssid} (${signal:-?}%)")
        fi
    done < <(nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list ifname "$wifi_dev" 2>/dev/null || true)

    if ((${#seen_ssid[@]} == 0)); then
        entries+=("(keine Netze gefunden)")
    fi
else
    entries+=("(kein WLAN-Gerät)")
fi

entries+=("── VPN ──")
mapfile -t vpn_conns < <(
    nmcli -t -f NAME,TYPE connection show 2>/dev/null \
        | awk -F: '$2 == "vpn" || $2 == "wireguard" { print $1 }'
)

if ((${#vpn_conns[@]} == 0)); then
    entries+=("(keine VPN-Profile)")
else
    for c in "${vpn_conns[@]}"; do
        if vpn_active "$c"; then
            entries+=("V✓ ${c}")
        else
            entries+=("V○ ${c}")
        fi
    done
fi

choice=$(printf '%s\n' "${entries[@]}" | rofi -dmenu -i -p "Netzwerk" -no-custom) || exit 0
[[ -z "${choice:-}" ]] && exit 0

case "$choice" in
    "──"*|"("*")") exit 0 ;;
esac

if [[ ! "$choice" =~ ^(W|V)(✓|○)[[:space:]]+(.*)$ ]]; then
    exit 0
fi

kind=${BASH_REMATCH[1]}
mark=${BASH_REMATCH[2]}
label=${BASH_REMATCH[3]}

case "$kind" in
    W)
        ssid=${label%% (*}
        if [[ "$mark" == "✓" ]]; then
            nmcli connection down id "$ssid" 2>/dev/null \
                || nmcli device disconnect "$wifi_dev" 2>/dev/null \
                || notify "WLAN trennen fehlgeschlagen: $ssid"
            notify "WLAN getrennt: $ssid"
        else
            if nmcli --wait 30 device wifi connect "$ssid" ifname "$wifi_dev"; then
                notify "Verbunden: $ssid"
            else
                notify "Verbinden fehlgeschlagen: $ssid (ggf. Passwort in nm-connection-editor)"
            fi
        fi
        ;;
    V)
        vpn_name=$label
        if [[ "$mark" == "✓" ]]; then
            nmcli connection down "$vpn_name" && notify "VPN getrennt: $vpn_name" \
                || notify "Trennen fehlgeschlagen: $vpn_name"
        else
            nmcli connection up "$vpn_name" && notify "VPN verbunden: $vpn_name" \
                || notify "Verbinden fehlgeschlagen: $vpn_name"
        fi
        ;;
esac
