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

var current_rotation: int = 0:
	get:
		return current_rotation
	set(new):
		if new == -1:
			current_rotation = 3
			return
		current_rotation = (new % 4)

var region = DefaultTerrainArea.new()

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
					
func show_selector(cell_coordinate_center: Vector2i, cells: Array[Rect2i], placing_method: int):
	$Selection.clear()
	$Selection.show()
	var new_cells: Array[Rect2i] = []
	
	for rect in cells:
		rect.size = Vector2i(abs(Vector2(rect.size).rotated(current_rotation * PI / 2)))
		new_cells.append(rect)
		
	for rect in new_cells:
		var rect_center = cell_coordinate_center + rect.position
		for x in range(ceil(rect_center.x),ceil(rect_center.x+rect.size.x)):
			for y in range(ceil(rect_center.y),ceil(rect_center.y+rect.size.y)):
				if placing_method == PlacingMethod.Build and y == rect_center.y+rect.size.y-1 and tilemap.get_cell_source_id(Vector2(x,y+1)) == -1:
					$Selection.set_cell(Vector2(x,y), 0, Vector2(1,0), 0)
				elif tilemap.get_cell_source_id(Vector2(x,y)) >= 0:
					$Selection.set_cell(Vector2(x,y), 0, Vector2(1,0), 0)
				else:
					$Selection.set_cell(Vector2(x,y), 0, Vector2(0,0), 0)

func hide_selector():
	$Selection.hide()

func place_build(cell_coordinate_center: Vector2i, structure: StructureResource):
	var can_place = true
	
	var new_rects = structure.size
	for rect in new_rects:
		rect.size.x = rect.size.x * sin(current_rotation * PI) + rect.size.y * cos(current_rotation * PI)
		rect.size.y = rect.size.y * cos(current_rotation * PI) + rect.size.y * -sin(current_rotation * PI)
	
	for rect in new_rects:
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

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		generate()
	if Input.is_action_just_pressed("rotate_left"):
		current_rotation -= 1
	if Input.is_action_just_pressed("rotate_right"):
		current_rotation += 1
