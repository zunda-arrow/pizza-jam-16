extends Node2D

var ant = preload("res://ants/Ant.tscn")

@export var is_grid_cell_filled: Callable

var ants: Array[Ant] = []

func _ready() -> void:
	is_grid_cell_filled = default_is_grid_cell_filled

	var loop = get_loop(Vector2i(2, 2), Vector2(0, 1))

	for i in range(len(loop)):
		var m = $Marker.duplicate()
		add_child(m)
		m.show()
		m.position = loop[i][0] * 32 + Vector2i(16, 16)

	spawn_ant()

func spawn_ant():
	var loop = get_loop(Vector2i(2, 3), Vector2(0, 1))
	var random_test_ant: Ant = ant.instantiate()
	%Ants.add_child(random_test_ant)
	var cell = loop.pick_random()
	random_test_ant.grid_position = cell[0]
	random_test_ant.ground_direction = cell[1]
	ants.push_back(random_test_ant)

func get_loop(pos: Vector2i, ground: Vector2i):
	var walkable_cells: Array = []

	while [pos, ground] not in walkable_cells:
		var forward = Vector2i(Vector2(ground).rotated(-PI / 2))

		if is_grid_cell_filled.call(pos + forward) == true:
			# Rotate left
			walkable_cells.push_back([pos, ground])
			ground = forward
			continue

		if is_grid_cell_filled.call(pos + forward) == false and is_grid_cell_filled.call(pos + forward + ground) == false:
			# Rotate left
			walkable_cells.push_back([pos, ground])
			pos = pos + forward + ground
			ground = Vector2i(Vector2(ground).rotated(PI / 2))
			continue

		if is_grid_cell_filled.call(pos + ground) == true:
			walkable_cells.push_back([pos, ground])
			pos += forward

	return walkable_cells

func get_path_to_cell(loop: Array, from: Vector2i, to: Vector2i) -> Array:
	var index_of_from = loop.find_custom(func(x): return x[0] == from)
	var index_of_to = loop.find_custom(func(x): return x[0] == to)
	
	var path: Array
	
	if abs(index_of_to - index_of_from) < len(loop) - index_of_to - index_of_from:
		var i = index_of_from
		while i != index_of_to:
			path.push_back(loop[i])
			i+=+1
			if i >= len(loop):
				i = 0
	else:
		var i = index_of_from
		while i != index_of_to:
			path.push_back(loop[i])
			i-=1
			if i < 0:
				i = len(loop) - 1

	path.push_back(loop[index_of_to])

	return path

func default_is_grid_cell_filled(cell: Vector2) -> bool:
	return $TileMap.get_cell_tile_data(0, cell) != null

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:

		var mouse_cell = floor(get_global_mouse_position() / 32)
		var ant = ants[0]
		
		var ant_loop = get_loop(ant.grid_position, ant.ground_direction)
		if ant_loop.find_custom(func(x): return x[0] == Vector2i(mouse_cell)) == -1:
			print("failed")
			return

		ant.move_to_tile(get_path_to_cell(ant_loop, ant.grid_position, mouse_cell))
