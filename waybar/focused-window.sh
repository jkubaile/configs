#!/usr/bin/env bash
# Focused window title + short foreign-toplevel id (matches share-chooser hash).
set -euo pipefail

swaymsg -t get_tree | jq -c '
	first(.. | objects | select(.focused == true and (.type? == "con" or .type? == "floating_con")))
	| . as $w
	| (if $w.foreign_toplevel_identifier
		then $w.foreign_toplevel_identifier[0:8]
		else empty end) as $id
	| {
		text: (
			if ($w.name != null and $w.name != "") and ($id != null) then
				"\($w.name) [\($id)]"
			elif ($w.name != null and $w.name != "") then
				$w.name
			elif $id != null then
				"[\($id)]"
			else
				""
			end
		),
		tooltip: (
			[
				($w.app_id // empty),
				($w.foreign_toplevel_identifier // empty),
				(if $w.shell then "shell: \($w.shell)" else empty end)
			] | map(select(. != null and . != "")) | join("\n")
		),
		class: ($w.app_id // "window")
	}
' 2>/dev/null || printf '%s\n' '{"text":""}'
