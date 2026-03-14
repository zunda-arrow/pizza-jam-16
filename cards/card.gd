@tool
extends Node2D

signal on_mouse_entered
signal on_mouse_exited
signal on_clicked

var hovered = false

func _on_panel_mouse_entered() -> void:
	hovered = true
	on_mouse_entered.emit()

func _on_panel_mouse_exited() -> void:
	hovered = false
	on_mouse_exited.emit()

func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			on_clicked.emit()
