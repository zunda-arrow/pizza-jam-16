@tool
extends Node2D

var lifetime = 0

var structure: StructureResource.Structure:
	set(structure_):
		structure = structure_
		$Sprite2D.texture = structure.resource.texture
		lifetime = structure.resource.lifetime
	get():
		return structure

func set_connected_to_loop(is_connected_: bool):
	if is_connected_:
		$Label.show()
	else:
		$Label.hide()

func get_tile_position():
	return Vector2i((position - Vector2(16, 16)) / 32) 

func get_tiles() -> Array[Vector2i]:
	var rects: Array[Rect2i] = structure.resource.size
	var pos = Vector2i((position - Vector2(16, 16)) / 32)
	var out: Array[Vector2i] = []

	for r in rects:
		for x in r.size.x:
			for y in r.size.y:
				out += [pos + Vector2i(x,y) + r.position]
	return out
