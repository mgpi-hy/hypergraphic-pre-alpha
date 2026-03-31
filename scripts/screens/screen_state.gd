class_name ScreenState
extends Control

signal finished(next_screen: String, data: Dictionary)


func _ready() -> void:
	# All screens get void background by default
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = ThemeManager.COLOR_VOID
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)  # Background goes behind everything


func enter(_previous: String, _data: Dictionary = {}) -> void:
	show()


func exit() -> void:
	hide()
