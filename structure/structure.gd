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

func get_tiles() -> Array[Vector2i]:
	var rects: Array[Rect2i] = structure.size
	var pos = Vector2i(position / 32)
	var out: Array[Vector2i] = []
	for r in rects:
		for x in r.size.x:
			for y in r.size.y:
				out += [pos + Vector2i(x,y) - Vector2i(1,1)]
	return out
				
