extends Node2D


var structure_scene = preload("res://structure/structure.tscn")
var example_resource: StructureResource = preload("res://resources/structures/example.tres")

var LINK_DISTANCE = 128

var structures: Array = []
var links: Array[Array] = [] # Connections between buildings within range, Array[Array[int]] by implementation.
var structure_groups: Array[Array] = [] # Array of array of connected structures.
var structure_membership: Dictionary = {} # Maps Structures to their groups (includes itself).

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
		links.append([])
		for i in range(structures.size()):
			var dist = pos.distance_to(structures[i].global_position)
			if (dist <= LINK_DISTANCE):
				links[i].append(structures.size())
				links[structures.size()].append(i)
		structures.push_back(struct_scene)
		determine_groups()
	
	return can_place

func determine_groups():
	var unvisited: Array[bool] = []
	var to_visit: Array[int] = [0]
	var group_index: int = 0
	var unfinished: bool = true
	for i in range(structures.size()):
		unvisited.append(true)
	
	structure_groups = []
	
	while unfinished:
		structure_groups.append([])
		while !to_visit.is_empty():
			var index = to_visit.pop_back()
			unvisited[index] = false
			if !links[index].is_empty():
				for link in links[index]:
					if unvisited[link]:
						to_visit.append(link)
			structure_groups[group_index].append(structures[index])
			
		var i = 0
		while i < unvisited.size() and !unvisited[i]:
			i += 1
		if i < structures.size():
			to_visit.append(i)
		else:
			unfinished = false
	
	for group in structure_groups:
		for structure in group:
			structure_membership.set(structure, group)
