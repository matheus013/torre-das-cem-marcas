class_name DescriptionHover
extends Control


static func attach(target: Control, text: String, stop_mouse := false) -> DescriptionHover:
	var region := DescriptionHover.new()
	region.tooltip_text = text
	region.mouse_filter = Control.MOUSE_FILTER_STOP if stop_mouse else Control.MOUSE_FILTER_PASS
	target.add_child(region)
	region.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return region


func _make_custom_tooltip(for_text: String) -> Object:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b1a1ff5")
	style.border_color = Color("8f7a6a")
	style.set_border_width_all(1)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = for_text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = minf(360.0, maxf(120.0, get_viewport_rect().size.x - 48.0))
	label.add_theme_color_override("font_color", Color("f2e6c9"))
	panel.add_child(label)
	return panel
