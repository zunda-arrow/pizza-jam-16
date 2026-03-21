extends Node2D


var structure_scene = preload("res://structure/structure.tscn")
var example_resource: StructureResource = preload("res://resources/structures/example.tres")

var structures: Array[Node2D] = []
var links: Array[Array] = [] # Connections between buildings within range, Array[Array[int]] by implementation.
var structure_groups: Array[Array] = [] # Array of array of connected structures.

var placing_build = true

var has_terrain = func(_pos: Vector2): return true # This is specifically to check if there is terrain under a structure
var occupation_checker = func(): return building_occupation() # This can be overriden (eg. to use the terrain_manager occupation checker)

# The "requires contact" cells for a structure resource are what is considered occupied
func building_occupation() -> Array[Vector2i]:
	var occupied_cells: Array[Vector2i] = []
	for s in structures:
		for t in s.get_tiles():
			occupied_cells += [t]
		for r in s.structure.resource.required_ground:
			var pos = s.get_tile_position() + r.position
			for x in range(ceil(pos.x),ceil(pos.x+r.size.x)):
				for y in range(ceil(pos.y),ceil(pos.y+r.size.y)):
					occupied_cells += [Vector2i(x, y)]
	return occupied_cells

func place_build(pos: Vector2, cell_coordinate_center: Vector2i, structure: StructureResource.Structure) -> bool:
	var can_place = true

	var occupied_cells = occupation_checker.call()

	# If any of the requruired ground rects are full, we consides the structure
	# is on ground.
	var has_ground = false
	for dirt_cell in structure.resource.required_ground:
		var rect_center = cell_coordinate_center + dirt_cell.position
		var section_has_ground = true
		for x in range(ceil(rect_center.x),ceil(rect_center.x+dirt_cell.size.x)):
			for y in range(ceil(rect_center.y),ceil(rect_center.y+dirt_cell.size.y)):
				if has_terrain.call(Vector2(x, y)) == false:
					section_has_ground = false
		if section_has_ground:
			has_ground = true

	if not has_ground:
		can_place = false

	for rect in structure.resource.size:
		var rect_center = cell_coordinate_center + rect.position
		for x in range(ceil(rect_center.x),ceil(rect_center.x+rect.size.x)):
			for y in range(ceil(rect_center.y),ceil(rect_center.y+rect.size.y)):
				if Vector2i(x, y) in occupied_cells:
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
			if (dist <= structure.get_visible_radius()):
				links[i].append(structures.size())
				links[structures.size()].append(i)
		structures.push_back(struct_scene)
		determine_groups()
	
		if structure.resource.structure_name != "Home":
			$PlaceDown.play(0.02)
	
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

func structure_groups_in_range(area: Array[Vector2i]) -> Array[Array]:
	var groups_in_range: Array[Array] = []
	
	for group in structure_groups:
		for structure in group:
			var in_range = false
			for cell in area:
				if structure.position.distance_to(cell * 32 + Vector2i(16, 16)) < structure.structure.resource.tiles_radius * 32:
					groups_in_range.append(group)
					in_range = true
					break
			if in_range:
				break
	
	return groups_in_range
