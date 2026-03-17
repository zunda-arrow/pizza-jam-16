@tool
extends Node2D

var structure: StructureResource.Structure:
	set(structure_):
		structure = structure_
		$Sprite2D.texture = structure.resource.texture
	get():
		return structure

func set_connected_to_loop(is_connected_: bool):
	if is_connected_:
		$Label.show()
	else:
		$Label.hide()

func get_tiles() -> Array[Vector2i]:
	var rects: Array[Rect2i] = structure.resource.size
	var pos = Vector2i(position / 32)
	var out: Array[Vector2i] = []
	
	if position[0] < 0:
		pos += Vector2i(-1,0)
	if position[1] > 0:
		pos += Vector2i(0,1)
		
	for r in rects:
		for x in r.size.x:
			for y in r.size.y:
				out += [pos + Vector2i(x,y) - Vector2i(1,2)]
	return out
				
