extends Node2D

var structure_scene = preload("res://terrain/structure.tscn")
var example_resource: StructureResource = preload("res://resources/structures/example.tres")

@export var placing_build = true

# Radius is a square radius
func destroy(cell_coordinate_center: Vector2i, diameter: int):
	var radius = diameter / 2.	
	for x in range(ceil(cell_coordinate_center.x-radius),ceil(cell_coordinate_center.x+radius)):
		for y in range(ceil(cell_coordinate_center.y-radius),ceil(cell_coordinate_center.y+radius)):
			if $TileMapLayer.get_cell_source_id(Vector2(x,y)) >= 0:
				$TileMapLayer.erase_cell(Vector2(x,y))

func show_selector(cell_coordinate_center: Vector2i, size: Array[Rect2i]):
	$Selection.clear()
	$Selection.show()
	for rect in size:
		for x in range(ceil(cell_coordinate_center.x+rect.position.x-rect.size.x),ceil(cell_coordinate_center.x+rect.position.x++1+rect.size.x)):
			for y in range(ceil(cell_coordinate_center.y+rect.position.y-rect.size.y),ceil(cell_coordinate_center.y+rect.position.y+1+rect.size.y)):
				if $TileMapLayer.get_cell_source_id(Vector2(x,y)) >= 0:
					$Selection.set_cell(Vector2(x,y), 0, Vector2(1,0), 0)
				else:
					$Selection.set_cell(Vector2(x,y), 0, Vector2(0,0), 0)

func hide_selector():
	$Selection.hide()

func place_build(position: Vector2i, structure: StructureResource):
	var cell_coordinate_center = $Selection.local_to_map(Vector2i(position.x,position.y+40))
	var can_place = true
	
	for rect in structure.size:
		for x in range(ceil(cell_coordinate_center.x+rect.position.x-rect.size.x),ceil(cell_coordinate_center.x+rect.position.x++1+rect.size.x)):
			for y in range(ceil(cell_coordinate_center.y+rect.position.y-rect.size.y),ceil(cell_coordinate_center.y+rect.position.y+1+rect.size.y)):
				if $TileMapLayer.get_cell_source_id(Vector2(x,y)) >= 0:
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
