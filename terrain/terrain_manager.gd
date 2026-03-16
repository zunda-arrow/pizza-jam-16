# Handles terrain generation
extends Node2D

class DefaultTerrainArea:
	func get_bounding_area() -> Rect2:
		return Rect2(Vector2.ZERO, Vector2(1920, 1080))

@export var initial_seed = 0 # The noise seed on ready. If set to 0, random seed.

@export var noise: FastNoiseLite # The noise we will use to generate the terrain
@export var block_threshold: float = 0.5 # Threshold to place a block (less than)
@export var unbreakable_threshold: float = 0.0 # Threshold to place an unbreakable block #TODO: Implement

@export var spawn_radius: float = 10.0

@export var chunk_size: int = 16

var structure_scene = preload("res://terrain/structure.tscn")
var example_resource: StructureResource = preload("res://resources/structures/example.tres")

var structures: Array = []

var placing_build = true

var region = DefaultTerrainArea.new()
var generated_chunks = {}

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
	var cells_to_set = []
	for y in chunk_size:
		for x in chunk_size:
			var potential_pos = Vector2i(
				chunk_x * chunk_size + x,
				chunk_y * chunk_size + y
			)
			if get_cellv(potential_pos):
				cells_to_set.append(potential_pos)
	tilemap.set_cells_terrain_connect(cells_to_set, 0, 0)

func get_cell(x: int, y: int) -> bool: # Check if there is a cell here
	return noise.get_noise_2d(x, y) < block_threshold and sqrt(x**2 + y**2) > spawn_radius

func get_cellv(vec: Vector2) -> bool:
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
		
func get_occupied_cells() -> Array[Vector2i]:
	var occupied_cells: Array[Vector2i] = []
	for s in structures:
		occupied_cells += s.get_tiles()
	return occupied_cells
					
func show_selector(cell_coordinate_center: Vector2i, cells: Array[Rect2i], placing_method: int):
	$Selection.clear()
	$Selection.show()	
	
	var occupied_cells: Array[Vector2i] = get_occupied_cells()
	print(occupied_cells)
		
	for rect in cells:
		var rect_center = cell_coordinate_center + rect.position
		for x in range(ceil(rect_center.x),ceil(rect_center.x+rect.size.x)):
			for y in range(ceil(rect_center.y),ceil(rect_center.y+rect.size.y)):
				if placing_method == PlacingMethod.Build and y == rect_center.y+rect.size.y-1 and tilemap.get_cell_source_id(Vector2(x,y+1)) == -1:
					$Selection.set_cell(Vector2(x,y), 0, Vector2(1,0), 0)
				elif Vector2i(x,y) in occupied_cells:
					$Selection.set_cell(Vector2(x,y), 0, Vector2(1,0), 0)
				elif tilemap.get_cell_source_id(Vector2(x,y)) >= 0:
					$Selection.set_cell(Vector2(x,y), 0, Vector2(1,0), 0)
				else:
					$Selection.set_cell(Vector2(x,y), 0, Vector2(0,0), 0)

func hide_selector():
	$Selection.hide()

func place_build(cell_coordinate_center: Vector2i, structure: StructureResource):
	var can_place = true

	for rect in structure.size:
		var rect_center = cell_coordinate_center + rect.position
		for x in range(ceil(rect_center.x),ceil(rect_center.x+rect.size.x)):
			for y in range(ceil(rect_center.y),ceil(rect_center.y+rect.size.y)):
				if y == rect_center.y+rect.size.y-1 and tilemap.get_cell_source_id(Vector2(x,y+1)) == -1:
					can_place = false
				if y == rect_center.y+rect.size.y and tilemap.get_cell_source_id(Vector2(y,y+1)) == 0:
					can_place = false
				if tilemap.get_cell_source_id(Vector2(x,y)) >= 0:
					can_place = false

	if (can_place):
		var struc_scene = structure_scene.instantiate()
		struc_scene.structure = structure
		struc_scene.global_position = $Selection.map_to_local(cell_coordinate_center)
		add_child(struc_scene)
		structures.push_back(struc_scene)

func _process(_delta: float) -> void:
	generate()
