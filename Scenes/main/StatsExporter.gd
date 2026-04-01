## StatsExporter.gd
## Autoload singleton. Listens for Globals.gameEnded and writes an XML file
## to user:// capturing session outcome and cursor interaction metrics.
## File name: td_stats_<map>_<timestamp>.xml

extends Node

func _ready() -> void:
	Globals.gameEnded.connect(_on_game_ended)

func _on_game_ended(won: bool, stats: Dictionary) -> void:
	var timestamp := Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var map_id: String = stats.get("map", "unknown")
	var filename := "user://td_stats_%s_%s.xml" % [map_id, timestamp]

	var xml := _build_xml(won, stats, timestamp)

	var file := FileAccess.open(filename, FileAccess.WRITE)
	if file == null:
		push_error("StatsExporter: could not open '%s' for writing (err %d)" \
			% [filename, FileAccess.get_open_error()])
		return
	file.store_string(xml)
	file.close()
	print("StatsExporter: saved → ", ProjectSettings.globalize_path(filename))

func _build_xml(won: bool, stats: Dictionary, timestamp: String) -> String:
	var lines: PackedStringArray = []
	lines.append('<?xml version="1.0" encoding="UTF-8"?>')
	lines.append('<session>')
	lines.append('\t<timestamp>%s</timestamp>' % timestamp)
	lines.append('\t<map>%s</map>' % _esc(stats.get("map", "")))
	lines.append('\t<result>%s</result>' % ("victory" if won else "defeat"))
	lines.append('\t<waves_completed>%d</waves_completed>' % stats.get("display_waves_completed", 0))
	lines.append('\t<total_waves>%d</total_waves>'         % stats.get("total_waves", 10))
	lines.append('\t<gold_remaining>%d</gold_remaining>'   % stats.get("gold_remaining", 0))
	lines.append('\t<base_hp_remaining>%.2f</base_hp_remaining>' % stats.get("base_hp_remaining", 0.0))

	var bc_on: bool = stats.get("bubble_cursor_enabled", false)
	lines.append('\t<bubble_cursor_enabled>%s</bubble_cursor_enabled>' % str(bc_on).to_lower())

	if bc_on:
		# ── Bubble cursor metrics ──────────────────────────────────
		if is_instance_valid(Globals.bubble_cursor):
			var m: Dictionary = Globals.bubble_cursor.get_metrics()
			lines.append('\t<cursor_metrics type="bubble">')
			lines.append('\t\t<travel_px>%.1f</travel_px>'   % m.get("travel_px", 0.0))
			lines.append('\t\t<misclicks>%d</misclicks>'     % m.get("misclicks", 0))
			lines.append('\t</cursor_metrics>')
	else:
		# ── Normal cursor metrics ──────────────────────────────────
		if is_instance_valid(Globals.normal_cursor_tracker):
			var m: Dictionary = Globals.normal_cursor_tracker.get_metrics()
			lines.append('\t<cursor_metrics type="normal">')
			lines.append('\t\t<travel_px>%.1f</travel_px>'              % m.get("travel_px", 0.0))
			lines.append('\t\t<misclicks>%d</misclicks>'                % m.get("misclicks", 0))
			lines.append('\t\t<hits>%d</hits>'                          % m.get("hits", 0))
			lines.append('\t\t<total_clicks>%d</total_clicks>'          % m.get("total_clicks", 0))
			lines.append('\t\t<avg_dist_to_nearest_px>%.1f</avg_dist_to_nearest_px>' \
				% m.get("avg_dist_to_nearest_px", 0.0))
			lines.append('\t\t<max_dist_to_nearest_px>%.1f</max_dist_to_nearest_px>' \
				% m.get("max_dist_to_nearest_px", 0.0))
			lines.append('\t</cursor_metrics>')

	lines.append('</session>')
	return "\n".join(lines) + "\n"

func _esc(s: String) -> String:
	return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;")
