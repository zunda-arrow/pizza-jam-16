# Handles terrain generation
extends Node2D

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

func get_cell(x: int, y: int) -> TerrainType: # Check if there is a cell here
	if sqrt(x**2 + y**2) <= spawn_radius:
		return TerrainType.Air
	var point = noise.get_noise_2d(x, y)
	if point < rock_threshold:
		return TerrainType.Rock
	elif point < block_threshold:
		return TerrainType.Dirt
	return TerrainType.Air

func get_cellv(vec: Vector2) -> TerrainType:
	return get_cell(vec.x, vec.y)

# Radius is a square radius
func destroy(cell_coordinate_center: Vector2i, cells: Array[Rect2i]):
	var cells_to_remove: Array[Vector2i] = []
	var cells_to_update: Array[Vector2i] = []

	for rect in cells:
		var rect_center = cell_coordinate_center + rect.position
		for x in range(ceil(rect_center.x),ceil(rect_center.x+rect.size.x)):
			for y in range(ceil(rect_center.y),ceil(rect_center.y+rect.size.y)):
				if tilemap.get_cell_source_id(Vector2(x,y)) >= 0:
					if (x < rect_center.x-rect.size.x or x > rect_center.x+rect.size.x or y < rect_center.y-rect.size.y or y > rect_center.y+rect.size.y):
						cells_to_update.append(Vector2(x,y))
					else:
						cells_to_remove.append(Vector2(x,y))

	tilemap.set_cells_terrain_connect(cells_to_remove, 0, -1)
	tilemap.set_cells_terrain_connect(cells_to_update, 0, 0)

func get_occupied_tiles() -> Array[Vector2i]:
	tilemap.get_used_cells()
	return tilemap.get_used_cells()

func get_occupied_cells() -> Array[Vector2i]:
	var occupied_cells: Array[Vector2i] = []
	for check in occupation_checks:
		occupied_cells += check.call()
	return occupied_cells
					
func show_selector(cell_coordinate_center: Vector2i, cells: Array[Rect2i], placing_method: int):
	$Selection.clear()
	$Selection.show()
	
	var occupied_cells: Array[Vector2i] = get_occupied_cells()

	for rect in cells:
		var rect_center = cell_coordinate_center + rect.position
		for x in range(ceil(rect_center.x),ceil(rect_center.x+rect.size.x)):
			for y in range(ceil(rect_center.y),ceil(rect_center.y+rect.size.y)):
				if placing_method == PlacingMethod.Build and y == rect_center.y+rect.size.y-1 and tilemap.get_cell_source_id(Vector2(x,y+1)) == -1:
					$Selection.set_cell(Vector2(x,y), 0, Vector2(1,0), 0)
				elif Vector2i(x,y) in occupied_cells:
					$Selection.set_cell(Vector2(x,y), 0, Vector2(1,0), 0)
				else:
					$Selection.set_cell(Vector2(x,y), 0, Vector2(0,0), 0)

func hide_selector():
	$Selection.hide()

func _process(_delta: float) -> void:
	generate()
