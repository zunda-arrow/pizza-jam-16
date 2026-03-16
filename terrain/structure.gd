@tool
extends Node2D

@export var structure: StructureResource

func _ready() -> void:
	if structure == null:
		return
	$Sprite2D.texture = structure.texture

func set_connected_to_loop(is_connected_: bool):
	if is_connected_:
		$Label.show()
	else:
		$Label.hide()

func get_tiles():
	var rect = $Sprite2D.get_rect()

	var out = []

	for x in range(rect.position.x / 32, rect.end.x / 32):
		for y in range(rect.position.x / 32, rect.end.y / 32):
			out += [Vector2i(Vector2(x, y) + position / 32)]

	return out
