class_name DescriptionHover
extends Control
const UiSkin := preload("res://src/presentation/ui/game_ui_skin.gd")


static func attach(target: Control, text: String, stop_mouse := false) -> DescriptionHover:
	var region := DescriptionHover.new()
	region.tooltip_text = text
	region.mouse_filter = Control.MOUSE_FILTER_STOP if stop_mouse else Control.MOUSE_FILTER_PASS
	target.add_child(region)
	region.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return region


func _make_custom_tooltip(for_text: String) -> Object:
	var panel := PanelContainer.new()
	UiSkin.apply(panel)
	panel.add_theme_stylebox_override("panel", UiSkin.frame(false, 14))
	# Texto com BBCode (dicas de item do inventário) usa RichText: cores por raridade e afixo.
	if for_text.contains("[color="):
		var rich := RichTextLabel.new()
		rich.bbcode_enabled = true
		rich.fit_content = true
		rich.scroll_active = false
		rich.text = for_text
		rich.custom_minimum_size.x = minf(320.0, maxf(120.0, get_viewport_rect().size.x - 48.0))
		rich.add_theme_color_override("default_color", Color("f2e6c9"))
		panel.add_child(rich)
		return panel
	var label := Label.new()
	label.text = for_text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = minf(360.0, maxf(120.0, get_viewport_rect().size.x - 48.0))
	label.add_theme_color_override("font_color", Color("f2e6c9"))
	panel.add_child(label)
	return panel
