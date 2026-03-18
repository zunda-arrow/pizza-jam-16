# Handles terrain generation
extends Node2D

signal chunk_generated(Vector2i)

enum TerrainType{
	Air,
	Dirt,
	Rock
}

@export var initial_seed = 0 # The noise seed on ready. If set to 0, random seed.

@export var noise: FastNoiseLite # The noise we will use to generate the terrain
@export var block_threshold: float = 0.5 # Threshold to place a block (less than)
@export var rock_threshold: float = 1.0 # Threshold to place an unbreakable block #TODO: Implement

@export var spawn_radius: float = 10.0

@export var chunk_size: int = 16

var generated_chunks = {}

var occupation_checks = [get_occupied_tiles]

@onready var tilemap: TileMapLayer = %GroundMap
@onready var healthmap: TileMapLayer = %HealthMap

enum PlacingMethod {
	Dig,
	Build
}

# The amount of chunks from the left to right of the map
var MAP_CHUNKS = 10
var MAP_SIZE = Rect2i(-MAP_CHUNKS / 2, -MAP_CHUNKS / 2, MAP_CHUNKS, MAP_CHUNKS)

func _ready():
	if initial_seed == 0:
		initial_seed = randi()
	reset_map(initial_seed)
	generate()

func reset_map(new_seed) -> void:
	tilemap.clear()
	noise.seed = new_seed

func generate() -> void:
	var rect = MAP_SIZE
	# We generate the ring of chunks around the camera to make sure an unloaded chunk is never visible
	for y in MAP_SIZE.size.y:
		for x in MAP_SIZE.size.x:
			generate_chunk(MAP_SIZE.position.x + x, MAP_SIZE.position.y + y)

func generate_chunk(chunk_x: int, chunk_y: int) -> void: # Generate a single chunk of terrain
	if generated_chunks.get(Vector2i(chunk_x, chunk_y), false):
		return
	generated_chunks[Vector2i(chunk_x, chunk_y)] = true
	for y in chunk_size:
		for x in chunk_size:
			var potential_pos = Vector2i(
				chunk_x * chunk_size + x,
				chunk_y * chunk_size + y
			)
			
			var my_value = get_cellv(potential_pos)

			var top_left = get_cellv(potential_pos + Vector2i(-1, -1)) == my_value
			var top_middle = get_cellv(potential_pos + Vector2i(0, -1)) == my_value
			var top_right = get_cellv(potential_pos + Vector2i(1, -1)) == my_value
			var middle_left = get_cellv(potential_pos + Vector2i(-1, 0)) == my_value
			var middle_right = get_cellv(potential_pos + Vector2i(1, 0)) == my_value
			var bottom_left = get_cellv(potential_pos + Vector2i(-1, 1)) == my_value
			var bottom_middle = get_cellv(potential_pos + Vector2i(0, 1)) == my_value
			var bottom_right = get_cellv(potential_pos + Vector2i(1, 1)) == my_value

			var neighbor = find_atlas_chord_from_neighbors(
				top_left,
				top_middle,
				top_right,
				middle_left,
				middle_right,
				bottom_left,
				bottom_middle,
				bottom_right
			)

			match get_cellv(potential_pos):
				TerrainType.Dirt:
					tilemap.set_cell(potential_pos, 0, neighbor)
				TerrainType.Rock:
					tilemap.set_cell(potential_pos, 1, neighbor)

	chunk_generated.emit(Vector2i(chunk_x, chunk_y))

func find_atlas_chord_from_neighbors(top_left, top_middle, top_right, middle_left, middle_right, bottom_left, bottom_middle, bottom_right) -> Vector2i:
	if (
		top_left == true
		&& top_middle == true
		&& top_right == true
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == true
		&& bottom_middle == true
		&& bottom_right == true
	):
		return Vector2i(1, 0)

	if (
		top_middle == false
		&& middle_left == false
		&& middle_right == true
		&& bottom_middle == true
		&& bottom_right == true
	):
		return Vector2i(2, 0)

	if (
		top_middle == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == true
		&& bottom_middle == true
		&& bottom_right == true
	):
		return Vector2i(3, 0)

	if (
		top_middle == false
		&& middle_left == true
		&& middle_right == false
		&& bottom_middle == true
	):
		return Vector2i(4, 0)

	if (
		top_middle == false
		&& middle_left == false
		&& middle_right == false
		&& bottom_middle == true
	):
		return Vector2i(5, 0)

	if (
		top_left == true
		&& top_middle == true
		&& top_right == true
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == true
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(6, 0)

	if (
		top_left == true
		&& top_middle == true
		&& top_right == true
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == false
		&& bottom_middle == true
		&& bottom_right == true
	):
		return Vector2i(0, 1)

	if (
		top_middle == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == true
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(1, 1)

	if (
		top_middle == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == false
		&& bottom_middle == true
		&& bottom_right == true
	):
		return Vector2i(2, 1)

	if (
		top_middle == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == false
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(3, 1)

	if (
		top_middle == false
		&& middle_left == true
		&& middle_right == false
		&& bottom_left == false
		&& bottom_middle == true
	):
		return Vector2i(4, 1)

	if (
		top_middle == true
		&& top_right == true
		&& middle_left == false
		&& middle_right == true
		&& bottom_middle == true
		&& bottom_right == true
	):
		return Vector2i(5, 1)

	if (
		top_left == true
		&& top_middle == true
		&& middle_left == true
		&& middle_right == false
		&& bottom_left == true
		&& bottom_middle == true
	):
		return Vector2i(6, 1)

	if (
		top_middle == true
		&& middle_left == false
		&& middle_right == false
		&& bottom_middle == true
	):
		return Vector2i(0, 2)

	if (
		top_left == true
		&& top_middle == true
		&& top_right == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == true
		&& bottom_middle == true
		&& bottom_right == true
	):
		return Vector2i(1, 2)

	if (
		top_left == false
		&& top_middle == true
		&& top_right == true
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == true
		&& bottom_middle == true
		&& bottom_right == true
	):
		return Vector2i(2, 2)

	if (
		top_middle == true
		&& middle_left == true
		&& middle_right == false
		&& bottom_left == true
		&& bottom_middle == true
	):
		return Vector2i(3, 2)

	if (
		top_left == true
		&& top_middle == true
		&& middle_left == true
		&& middle_right == false
		&& bottom_left == false
		&& bottom_middle == true
	):
		return Vector2i(4, 2)

	if (
		top_left == false
		&& top_middle == true
		&& top_right == false
		&& middle_left == true
		&& middle_right == false
		&& bottom_left == true
		&& bottom_middle == true
	):
		return Vector2i(5, 2)

	if (
		top_middle == false
		&& middle_left == false
		&& middle_right == true
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(6, 2)

	if (
		top_middle == true
		&& top_right == true
		&& middle_left == false
		&& middle_right == true
		&& bottom_middle == false
	):
		return Vector2i(0, 3)

	if (
		top_left == true
		&& top_middle == true
		&& top_right == true
		&& middle_left == true
		&& middle_right == true
		&& bottom_middle == false
	):
		return Vector2i(1, 3)

	if (
		top_left == true
		&& top_middle == true
		&& middle_left == true
		&& middle_right == false
		&& bottom_middle == false
	):
		return Vector2i(2, 3)

	if (
		top_middle == true
		&& middle_left == false
		&& middle_right == false
		&& bottom_middle == false
	):
		return Vector2i(3, 3)

	if (
		top_left == true
		&& top_middle == true
		&& top_right == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == true
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(4, 3)

	if (
		top_left == true
		&& top_middle == true
		&& top_right == true
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == false
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(5, 3)

	if (
		top_left == true
		&& top_middle == true
		&& top_right == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_middle == false
	):
		return Vector2i(6, 3)

	if (
		top_left == false
		&& top_middle == true
		&& top_right == true
		&& middle_left == true
		&& middle_right == true
		&& bottom_middle == false
	):
		return Vector2i(0, 4)

	if (
		top_left == false
		&& top_middle == true
		&& top_right == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_middle == false
	):
		return Vector2i(1, 4)


	if (
		top_middle == true
		&& top_right == false
		&& middle_left == false
		&& middle_right == true
		&& bottom_middle == false
	):
		return Vector2i(2, 4)

	if (
		top_middle == false
		&& middle_left == false
		&& middle_right == true
		&& bottom_middle == false
	):
		return Vector2i(3, 4)

	if (
		top_middle == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_middle == false
	):
		return Vector2i(4, 4)

	if (
		top_middle == false
		&& middle_left == true
		&& middle_right == false
		&& bottom_middle == false
	):
		return Vector2i(5, 4)

	if (
		top_middle == false
		&& middle_left == false
		&& middle_right == false
		&& bottom_middle == false
	):
		return Vector2i(6, 4)

	if (
		top_left == false
		&& top_middle == true
		&& top_right == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == true
		&& bottom_middle == true
		&& bottom_right	== true
	):
		return Vector2i(0, 5)

	if (
		top_left == false
		&& top_middle == true
		&& top_right == true
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == false
		&& bottom_middle == true
		&& bottom_right	== true
	):
		return Vector2i(1, 5)

	if (
		top_middle == true
		&& top_right == true
		&& middle_left == false
		&& middle_right == true
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(2, 5)

	if (
		top_middle == true
		&& top_right == false
		&& middle_left == false
		&& middle_right == true
		&& bottom_middle == true
		&& bottom_right	== true
	):
		return Vector2i(3, 5)

	if (
		top_middle == true
		&& top_right == false
		&& middle_left == false
		&& middle_right == true
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(4, 5)

	if (
		top_left == false
		&& top_middle == true
		&& middle_left == true
		&& middle_right == false
		&& bottom_middle == false
	):
		return Vector2i(5, 5)

	if (
		top_left == false
		&& top_middle == true
		&& top_right == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == true
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(6, 5)

	if (
		top_left == false
		&& top_middle == true
		&& top_right == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == false
		&& bottom_middle == true
		&& bottom_right == true
	):
		return Vector2i(0, 6)

	if (
		top_left == false
		&& top_middle == true
		&& top_right == true
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == false
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(1, 6)

	if (
		top_left == true
		&& top_middle == true
		&& top_right == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == false
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(2, 6)

	if (
		top_left == false
		&& top_middle == true
		&& top_right == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == false
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(3, 6)

	if (
		top_left == false
		&& top_middle == true
		&& top_right == true
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == true
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(4, 6)

	if (
		top_left == true
		&& top_middle == true
		&& top_right == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == false
		&& bottom_middle == true
		&& bottom_right == true
	):
		return Vector2i(5, 6)

	return Vector2i(1, 0)

func get_cell(x: int, y: int) -> TerrainType: # Check if there is a cell here
	if sqrt(x**2 + y**2) <= spawn_radius:
		if y < 4:
			return TerrainType.Air
		else:
			return TerrainType.Dirt
	var point = noise.get_noise_2d(x, y)
	if point < rock_threshold:
		return TerrainType.Rock
	elif point < block_threshold:
		return TerrainType.Dirt
	return TerrainType.Air

func get_cellv(vec: Vector2) -> TerrainType:
	return get_cell(vec.x, vec.y)

# Radius is a square radius
func destroy(cell_coordinate_center: Vector2i, cells: Array[Rect2i], power: int, X: int = 0) -> bool:
	var cells_to_damage: Array[Vector2i] = []
	var cells_to_update: Array[Vector2i] = []
	var building_cells: Array[Vector2i] = %Structure.building_occupation()
	var area: Array[Rect2i] = x_area(cells, X)
	
	if power < 0:
		power *= -X

	for rect in area:
		var rect_center = cell_coordinate_center + rect.position
		for x in range(ceil(rect_center.x),ceil(rect_center.x+rect.size.x)):
			for y in range(ceil(rect_center.y),ceil(rect_center.y+rect.size.y)):
				if tilemap.get_cell_source_id(Vector2i(x,y)) >= 0:
					if (x < rect_center.x-rect.size.x or x > rect_center.x+rect.size.x or y < rect_center.y-rect.size.y or y > rect_center.y+rect.size.y):
						cells_to_update.append(Vector2i(x,y))
					elif Vector2i(x,y-1) in building_cells:
						return false
					else:
						cells_to_damage.append(Vector2i(x,y))
	
	var cells_to_remove: Array[Vector2i] = []
	for cell in cells_to_damage:
		var initial_health = tilemap.get_cell_tile_data(cell).get_custom_data("initial_health")
		if healthmap.get_cell_source_id(cell) == -1: # Not been damaged before
			var health = initial_health - power
			if health <= 0:
				cells_to_remove.append(cell)
				%Cracks.set_cell(cell)
				continue
			healthmap.set_cell(cell, 0, Vector2i(health - power, 0))
			set_cracks_for_cell(cell, health, initial_health)
			continue
		
		if healthmap.get_cell_atlas_coords(cell).x == 0:
			cells_to_remove.append(cell)
			%Cracks.set_cell(cell)
			healthmap.set_cell(cell)
		else:
			var health = healthmap.get_cell_atlas_coords(cell).x
			healthmap.set_cell(cell, 0, Vector2i(health - 1, 0))
			set_cracks_for_cell(cell, health, initial_health)

	tilemap.set_cells_terrain_connect(cells_to_remove, 0, -1)
	tilemap.set_cells_terrain_connect(cells_to_update, 0, 0)

	return true

func set_cracks_for_cell(cell: Vector2i, health: int, initial_health: int):
	var crack_number
	if health == initial_health:
		crack_number = 0
	else:
		crack_number = floor(8 - (float(health) / float(initial_health) * 8)) + 1

	%Cracks.set_cell(cell, 2, Vector2i(0, crack_number))

func get_occupied_tiles() -> Array[Vector2i]:
	tilemap.get_used_cells()
	return tilemap.get_used_cells()

func get_occupied_cells() -> Array[Vector2i]:
	var occupied_cells: Array[Vector2i] = []
	for check in occupation_checks:
		occupied_cells += check.call()
	return occupied_cells
					
func show_selector(cell_coordinate_center: Vector2i, cells: Array[Rect2i], placing_method: int, X: int):
	$Selection.clear()
	$Selection.show()
	
	var occupied_cells: Array[Vector2i] = get_occupied_cells()
	var building_cells: Array[Vector2i] = %Structure.building_occupation()
	var area = x_area(cells, X)

	for rect in area:
		var rect_center = cell_coordinate_center + rect.position
		for x in range(ceil(rect_center.x),ceil(rect_center.x+rect.size.x)):
			for y in range(ceil(rect_center.y),ceil(rect_center.y+rect.size.y)):
				if placing_method == PlacingMethod.Build and ((y == rect_center.y+rect.size.y-1 and tilemap.get_cell_source_id(Vector2(x,y+1)) == -1) or Vector2i(x,y) in occupied_cells):
					$Selection.set_cell(Vector2(x,y), 0, Vector2(1,0), 0)
				elif placing_method == PlacingMethod.Dig and Vector2i(x,y-1) in building_cells and !(Vector2i(x,y) in building_cells):
					$Selection.set_cell(Vector2(x,y), 0, Vector2(1,0), 0)
				#elif Vector2i(x,y) in occupied_cells:
				#	$Selection.set_cell(Vector2(x,y), 0, Vector2(1,0), 0)
				else:
					$Selection.set_cell(Vector2(x,y), 0, Vector2(0,0), 0)

func x_area(cells: Array[Rect2i], X: int) -> Array[Rect2i]:
	var area = cells.duplicate()
	
	for i in area.size():
		if area[i].size.x < 0:
			area[i] = Rect2i((area[i].size.x * X)/2, area[i].position.y, -area[i].size.x * X, area[i].size.y)
		if cells[i].size.y < 0:
			area[i] = Rect2i(area[i].position.x, (area[i].size.y * X)/2, area[i].size.x, -area[i].size.y * X)
	
	return area
	
func hide_selector():
	$Selection.hide()
