#!/usr/bin/python3
import json
import requests

WEATHER_ICONS = {
    # ☀️ SONNE / KLAR
    "113": "☀️",

    # ☁️ WOLKEN
    "116": "☁️", "119": "☁️", "122": "☁️", "143": "☁️", "248": "☁️", "260": "☁️",

    # 🌧️ REGEN
    "176": "🌧️", "200": "🌧️", "263": "🌧️", "266": "🌧️", "293": "🌧️", "296": "🌧️",
    "299": "🌧️", "302": "🌧️", "305": "🌧️", "308": "🌧️", "353": "🌧️", "356": "🌧️",
    "359": "🌧️", "386": "🌧️", "389": "🌧️",

    # ❄️ SCHNEE
    "182": "❄️", "227": "❄️", "230": "❄️", "281": "❄️", "311": "❄️", "323": "❄️",
    "326": "❄️", "332": "❄️", "338": "❄️", "350": "❄️", "362": "❄️", "365": "❄️",
    "368": "❄️", "371": "❄️", "392": "❄️", "395": "❄️"
}

def get_icon(code):
    return WEATHER_ICONS.get(str(code), "☁️")

try:
    # URL korrigiert: wttr.is mit Karlsruhe, format=j1 und lang=de
    response = requests.get("https://wttr.is/Karlsruhe?format=j1&lang=de", timeout=10)
    data = response.json()

    # current_condition ist eine Liste, wir nehmen das erste Element [0]
    current = data['current_condition'][0]
    temp = current['temp_C']
    code = current['weatherCode']

    # Deutsche Beschreibung extrahieren
    desc = current.get('lang_de', [{}])[0].get('value', current['weatherDesc'][0]['value'])
    current_icon = get_icon(code)

    tooltip = f"<b>Karlsruhe: {desc} ({temp}°C)</b>\n\n"

    for day in data['weather']:
        date = day['date']
        max_t = day['maxtempC']
        min_t = day['mintempC']

        # hourly ist eine Liste. Index 4 entspricht ca. 12:00 Uhr mittags
        noon_forecast = day['hourly'][4]
        day_code = noon_forecast['weatherCode']
        day_icon = get_icon(day_code)
        day_desc = noon_forecast.get('lang_de', [{}])[0].get('value', noon_forecast['weatherDesc'][0]['value'])

        tooltip += f"{day_icon}  <b>{date}</b>: {min_t}°C bis {max_t}°C | {day_desc}\n"

    out = {
        "text": f"{current_icon} {temp}°C",
        "tooltip": tooltip
    }
    print(json.dumps(out))

except Exception as e:
    print(json.dumps({"text": "☁️ N/A", "tooltip": f"Fehler: {str(e)}"}))
