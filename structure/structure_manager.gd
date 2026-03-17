extends Node2D


var structure_scene = preload("res://structure/structure.tscn")
var example_resource: StructureResource = preload("res://resources/structures/example.tres")

var structures: Array = []

var placing_build = true

var has_terrain = func(_pos: Vector2): return true # This is specifically to check if there is terrain under a structure
var occupation_checker = func(): return building_occupation() # This can be overriden (eg. to use the terrain_manager occupation checker)

func building_occupation() -> Array[Vector2i]:
	var occupied_cells: Array[Vector2i] = []
	for s in structures:
		occupied_cells += s.get_tiles()
	return occupied_cells

func place_build(pos: Vector2, cell_coordinate_center: Vector2i, structure: StructureResource) -> bool:
	var can_place = true

	var occupied_cells = occupation_checker.call()

	for rect in structure.size:
		var rect_center = cell_coordinate_center + rect.position
		for x in range(ceil(rect_center.x),ceil(rect_center.x+rect.size.x)):
			for y in range(ceil(rect_center.y),ceil(rect_center.y+rect.size.y)):
				if y == rect_center.y + rect.size.y - 1 and not has_terrain.call(Vector2(x, y + 1)): #Solid ground below
					can_place = false
				elif Vector2i(x, y) in occupied_cells:
					can_place = false

				if not can_place:
					break # We don't need to keep checking if it can't be placed
			
			if not can_place:
				break

	if (can_place):
		var struct_scene = structure_scene.instantiate()
		struct_scene.structure = structure
		struct_scene.global_position = pos
		add_child(struct_scene)
		structures.push_back(struct_scene)
	
	return can_place
