# Handles terrain generation
extends Node2D

signal chunk_generated(Vector2i)

class DefaultTerrainArea:
	func get_bounding_area() -> Rect2:
		return Rect2(Vector2.ZERO, Vector2(1920, 1080))

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

var region = DefaultTerrainArea.new()
var generated_chunks = {}

var occupation_checks = [get_occupied_tiles]

@onready var tilemap: TileMapLayer = %GroundMap
@onready var healthmap: TileMapLayer = %HealthMap

enum PlacingMethod {
	Dig,
	Build
}

func _ready():
	if initial_seed == 0:
		initial_seed = randi()
	reset_map(initial_seed)
	generate()

func reset_map(new_seed) -> void:
	tilemap.clear()
	noise.seed = new_seed

func generate() -> void:
	var rect = region.get_bounding_area()
	var start_pos = floor(Vector2(tilemap.local_to_map(rect.position)) / chunk_size)
	var size_chunks = ceil(rect.size / tilemap.tile_set.tile_size.x / chunk_size)
	for y in size_chunks.y:
		for x in size_chunks.x:
			generate_chunk(start_pos.x + x, start_pos.y + y)

func generate_chunk(chunk_x: int, chunk_y: int) -> void: # Generate a single chunk of terrain
	if generated_chunks.get(Vector2i(chunk_x, chunk_y), false):
		return
	generated_chunks[Vector2i(chunk_x, chunk_y)] = true
	var dirt_cells = []
	var rock_cells = []
	for y in chunk_size:
		for x in chunk_size:
			var potential_pos = Vector2i(
				chunk_x * chunk_size + x,
				chunk_y * chunk_size + y
			)
			match get_cellv(potential_pos):
				TerrainType.Dirt:
					dirt_cells.append(potential_pos)
				TerrainType.Rock:
					rock_cells.append(potential_pos)
	tilemap.set_cells_terrain_connect(dirt_cells, 0, 0)
	tilemap.set_cells_terrain_connect(rock_cells, 0, 1)
	
	chunk_generated.emit(Vector2i(chunk_x, chunk_y))

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
func destroy(cell_coordinate_center: Vector2i, cells: Array[Rect2i], power: int, X: int) -> bool:
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
		if healthmap.get_cell_source_id(cell) == -1: # Not been damaged before
			var health = tilemap.get_cell_tile_data(cell).get_custom_data("initial_health") - power
			if health <= 0:
				cells_to_remove.append(cell)
				continue
			healthmap.set_cell(cell, 0, Vector2i(health - power, 0))
			continue
		
		if healthmap.get_cell_atlas_coords(cell).x == 0:
			cells_to_remove.append(cell)
			healthmap.set_cell(cell)
		else:
			var health = healthmap.get_cell_atlas_coords(cell).x
			healthmap.set_cell(cell, 0, Vector2i(health - 1, 0))

	tilemap.set_cells_terrain_connect(cells_to_remove, 0, -1)
	tilemap.set_cells_terrain_connect(cells_to_update, 0, 0)

	return true

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

func _process(_delta: float) -> void:
	generate()
