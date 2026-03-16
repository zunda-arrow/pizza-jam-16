extends Node2D

var ant_scene = preload("res://ants/Ant.tscn")

@export var is_grid_cell_filled = null
@export var spawn_position: Vector2i
@export var spawn_ground_direction: Vector2i
@export var number_of_ants: int

var ants: Array[Ant] = []
var _main_loop: Array = []
var _check_for_ant_not_on_loop_timer = 0.

func generate_loop() -> void:
	if is_grid_cell_filled == null:
		is_grid_cell_filled = default_is_grid_cell_filled

	# We only care about the ants that are connected to spawn
	# This position should be a spawn position in the future
	_main_loop = get_loop(spawn_position, spawn_ground_direction)

func spawn_ants():
	for i in range(number_of_ants):
		var random_test_ant: Ant = ant_scene.instantiate()
		%Ants.add_child(random_test_ant)
		random_test_ant.grid_position = spawn_position
		random_test_ant.ground_direction = spawn_ground_direction
		ants.push_back(random_test_ant)
		await get_tree().create_timer(.1).timeout

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

func get_path_to_cell(loop: Array, from: Vector2i, to: Vector2i):
	var index_of_from = loop.find_custom(func(x): return x[0] == from)
	var index_of_to = loop.find_custom(func(x): return x[0] == to)

	if index_of_to == -1 or index_of_from == -1:
		return []

	var path: Array
	
	var direction = "right"

	if abs(index_of_to - index_of_from) < len(loop) - index_of_to - index_of_from:
		var i = index_of_from
		while i != index_of_to:
			path.push_back(loop[i])
			i+=+1
			if i >= len(loop):
				i = 0
	else:
		direction = "left"
		var i = index_of_from
		while i != index_of_to:
			path.push_back(loop[i])
			i-=1
			if i < 0:
				i = len(loop) - 1

	path.push_back(loop[index_of_to])

	return [path, direction]

func default_is_grid_cell_filled(cell: Vector2) -> bool:
	return $TileMap.get_cell_tile_data(0, cell) != null

func is_cell_on_loop(cell: Vector2i, ground = null):
	if _main_loop.find_custom(func(x): return x[0] == cell and (ground == null or x[1] == ground)) != -1:
		return true

func _process(delta: float) -> void:
	_check_for_ant_not_on_loop_timer += delta

	# We only check if the ants ants are not on the loop every .5 seconds to prevent lag
	if _check_for_ant_not_on_loop_timer > .5:
		_check_for_ant_not_on_loop_timer = 0
		for ant in ants:
			if not is_cell_on_loop(ant.grid_position, ant.ground_direction):
				# If the ants get removed from the main loop, put them back at spawn.
				ant.grid_position = spawn_position
				ant.ground_direction = spawn_ground_direction

	for ant in ants:
		if len(ant.following_path) == 0:
			var cell = _main_loop.pick_random()
			var d = get_path_to_cell(_main_loop, ant.grid_position, cell[0])

			if len(d) == 0:
				continue

			ant.move_to_tile(d[0], d[1])
