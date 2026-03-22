@tool
extends Label

func _ready():
	if not Engine.is_editor_hint():
		queue_free()
		return
	
	if get_tree().root == self:
		return
	if get_tree().root == get_parent():
		return
	
	queue_free()
