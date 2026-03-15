# Handles terrain generation
extends Node2D

@export var initial_seed = 0 # The noise seed on ready. If set to 0, random seed.

@export var noise: FastNoiseLite # The noise we will use to generate the terrain
@export var block_threshold: float = 0.5 # Threshold to place a block (less than)
@export var unbreakable_threshold: float = 0.0 # Threshold to place an unbreakable block #TODO: Implement

var structure_scene = preload("res://terrain/structure.tscn")
var example_resource: StructureResource = preload("res://resources/structures/example.tres")

var placing_build = true

@onready var tilemap: TileMapLayer = %GroundMap

func _ready():
	if initial_seed == 0:
		initial_seed = randi()
	generate(initial_seed)

func generate(new_seed) -> void:
	tilemap.clear()
	noise.seed = new_seed

	await get_tree().process_frame

	var set_cells = []
	for y in 100:
		for x in 100:
			#TODO: Can probably do this better.
			if get_cell(x, y):
				set_cells.append(Vector2i(x, y))
	tilemap.set_cells_terrain_connect(set_cells, 0, 0)

func get_cell(x: int, y: int) -> bool: # Check if there is a cell here
	return absf(noise.get_noise_2d(x, y)) > block_threshold

# Radius is a square radius
func destroy(cell_coordinate_center: Vector2i, diameter: int):
	var radius = diameter / 2.
	var cells_to_remove: Array[Vector2i] = []
	var cells_to_update: Array[Vector2i] = []
	for x in range(ceil(cell_coordinate_center.x-radius-1),ceil(cell_coordinate_center.x+radius+1)):
		for y in range(ceil(cell_coordinate_center.y-radius-1),ceil(cell_coordinate_center.y+radius+1)):
			if tilemap.get_cell_source_id(Vector2(x,y)) >= 0:
				if (x < cell_coordinate_center.x-radius or x > cell_coordinate_center.x+radius or y < cell_coordinate_center.y-radius or y > cell_coordinate_center.y+radius):
					cells_to_update.append(Vector2(x,y))
				else:
					cells_to_remove.append(Vector2(x,y))
	tilemap.set_cells_terrain_connect(cells_to_remove, 0, -1)
	tilemap.set_cells_terrain_connect(cells_to_update, 0, 0)
				
func show_selector(cell_coordinate_center: Vector2i, size: Array[Rect2i]):
	$Selection.clear()
	$Selection.show()
	
	for rect in size:
		for x in range(ceil(cell_coordinate_center.x+rect.position.x-rect.size.x),ceil(cell_coordinate_center.x+rect.position.x++1+rect.size.x)):
			for y in range(ceil(cell_coordinate_center.y+rect.position.y-rect.size.y),ceil(cell_coordinate_center.y+rect.position.y+1+rect.size.y)):
				if tilemap.get_cell_source_id(Vector2(x,y)) >= 0:
					$Selection.set_cell(Vector2(x,y), 0, Vector2(1,0), 0)
				else:
					$Selection.set_cell(Vector2(x,y), 0, Vector2(0,0), 0)
					
func hide_selector():
	$Selection.hide()

func place_build(cell_coordinate_center: Vector2i, structure: StructureResource):
	var can_place = true
	
	for rect in structure.size:
		for x in range(ceil(cell_coordinate_center.x+rect.position.x-rect.size.x),ceil(cell_coordinate_center.x+rect.position.x++1+rect.size.x)):
			for y in range(ceil(cell_coordinate_center.y+rect.position.y-rect.size.y),ceil(cell_coordinate_center.y+rect.position.y+1+rect.size.y)):
				if tilemap.get_cell_source_id(Vector2(x,y)) >= 0:
					can_place = false
					
	if (can_place):
		var struc_scene = structure_scene.instantiate()
		struc_scene.structure = structure
		struc_scene.global_position = $Selection.map_to_local(cell_coordinate_center)
		add_child(struc_scene)

#func _input(event):
	#if event is InputEventMouse:
		#show_selector(event.position, example_resource.size)
	#if event is InputEventMouseButton:
		#if event.button_mask == 1:
			#destroy(to_local(event.position),3)
		#if event.button_index == 2:
			#place_build(event.position, example_resource)
