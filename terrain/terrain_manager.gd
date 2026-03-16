# Handles terrain generation
extends Node2D

class DefaultTerrainArea:
	func get_bounding_area() -> Rect2:
		return Rect2(Vector2.ZERO, Vector2(1920, 1080))

@export var initial_seed = 0 # The noise seed on ready. If set to 0, random seed.

@export var noise: FastNoiseLite # The noise we will use to generate the terrain
@export var block_threshold: float = 0.5 # Threshold to place a block (less than)
@export var unbreakable_threshold: float = 0.0 # Threshold to place an unbreakable block #TODO: Implement

var structure_scene = preload("res://terrain/structure.tscn")
var example_resource: StructureResource = preload("res://resources/structures/example.tres")

var structures: Array = []

var placing_build = true

var region = DefaultTerrainArea.new()

@onready var tilemap: TileMapLayer = %GroundMap

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
	var set_cells = []
	for y in rect.size.y / tilemap.tile_set.tile_size.y:
		for x in rect.size.x / tilemap.tile_set.tile_size.x:
			#TODO: Can probably do this better.
			var potential_pos = Vector2(
				x + tilemap.local_to_map(rect.position).x,
				y + tilemap.local_to_map(rect.position).y,
			)
			if get_cellv(potential_pos):
				set_cells.append(potential_pos)
	tilemap.set_cells_terrain_connect(set_cells, 0, 0)

func get_cell(x: int, y: int) -> bool: # Check if there is a cell here
	return noise.get_noise_2d(x, y) < block_threshold

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
				
func show_selector(cell_coordinate_center: Vector2i, cells: Array[Rect2i]):
	$Selection.clear()
	$Selection.show()

	for rect in cells:
		var rect_center = cell_coordinate_center + rect.position
		for x in range(ceil(rect_center.x),ceil(rect_center.x+rect.size.x)):
			for y in range(ceil(rect_center.y),ceil(rect_center.y+rect.size.y)):
				if tilemap.get_cell_source_id(Vector2(x,y)) >= 0:
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
				if tilemap.get_cell_source_id(Vector2(x,y)) >= 0:
					can_place = false

	if (can_place):
		var struc_scene = structure_scene.instantiate()
		struc_scene.structure = structure
		struc_scene.global_position = $Selection.map_to_local(cell_coordinate_center)
		add_child(struc_scene)
		structures.push_back(struc_scene)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		generate()

#func _input(event):
	#if event is InputEventMouse:
		#show_selector(event.position, example_resource.size)
	#if event is InputEventMouseButton:
		#if event.button_mask == 1:
			#destroy(to_local(event.position),3)
		#if event.button_index == 2:
			#place_build(event.position, example_resource)
