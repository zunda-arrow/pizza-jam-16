extends Node2D

var ant_scene = preload("res://ants/Ant.tscn")

@export var is_grid_cell_filled = null
@export var get_cell_to_walk_to = null

@export var spawn_position: Vector2i
@export var spawn_ground_direction: Vector2i
@export var home_position: Vector2i

var number_of_ants: int:
	set(val):
		if number_of_ants > val:
			send_ants_home(number_of_ants - val)
		if number_of_ants < val:
			spawn_ants(val - number_of_ants)
		number_of_ants = val
	get():
		return number_of_ants


var ants: Array[Ant] = []
var _main_loop: Array = []

var _markers = []


func generate_loop() -> void:
	if is_grid_cell_filled == null:
		is_grid_cell_filled = default_is_grid_cell_filled

	# We only care about the ants that are connected to spawn
	# This position should be a spawn position in the future
	_main_loop = get_loop(spawn_position, spawn_ground_direction)

	for l in _markers:
		l.queue_free()
	_markers = []

	for i in _main_loop:
		var l = $Loop.duplicate()
		l.show()
		add_child(l)
		l.position = i[0] * 32 + Vector2i(16, 16)
		_markers.push_back(l)

func spawn_ants(n):
	for i in range(n):
		var a: Ant = ant_scene.instantiate()
		a.grid_position = spawn_position
		a.ground_direction = spawn_ground_direction
		a.position = spawn_position * 32 + Vector2i(16, 16)
		add_child(a)
		ants.push_back(a)
		a.thinking_time = 10000
		await get_tree().create_timer(.05).timeout

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

	var path_right: Array
	var path_left: Array
	
	var i = index_of_from
	while i != index_of_to:
		path_right.push_back(loop[i])
		i+=+1
		if i >= len(loop):
			i = 0

	i = index_of_from
	while i != index_of_to:
		path_left.push_back(loop[i])
		i-=1
		if i < 0:
			i = len(loop) - 1

	path_left.push_back(loop[index_of_to])
	path_right.push_back(loop[index_of_to])

	if len(path_left) < len(path_right):
		return [path_left, "left"]

	return [path_right, "right"]

func default_is_grid_cell_filled(cell: Vector2) -> bool:
	return $TileMap.get_cell_tile_data(0, cell) != null

func is_cell_on_loop(cell: Vector2i, ground = null):
	if _main_loop.find_custom(func(x): return x[0] == cell and (ground == null or x[1] == ground)) != -1:
		return true

func find_close_tiles(cell: Vector2i, range: int):
	var index = _main_loop.find_custom(func(x): return x[0] == cell)
	var c = randi_range(0, range * 2)
	
	var index2 = (index + c - range)
	if index2 >= len(_main_loop):
		index2 -= len(_main_loop)
	if index2 < 0:
		index += len(_main_loop)

	return _main_loop[index2][0]

func send_ants_home(n: int):
	for i in range(n):
		var ant_to_send_home = ants.filter(func(x): return x != null and not x.going_home).pick_random()
		
		if (ant_to_send_home == null):
			print("Cound not find an ant to send home.")
			return
	
		ant_to_send_home.going_home = true
		var d = get_path_to_cell(_main_loop, ant_to_send_home.grid_position, home_position)
		if len(d) == 0:
			print("Can not send ant home due to broken path.")
			ant_to_send_home.queue_free()
			return

		ant_to_send_home.move_to_tile(d[0], d[1])

func _process(delta: float) -> void:
	if not get_cell_to_walk_to:
		return

	ants = ants.filter(func(x): return x != null)

	for ant in ants:
		if ant.is_thinking():
			continue

		if len(ant.following_path) != 0:
			continue

		var cell = get_cell_to_walk_to.call()
		if cell == null:
			continue
		var d = get_path_to_cell(_main_loop, ant.grid_position, cell)
		if len(d) == 0:
			continue

		ant.move_to_tile(d[0], d[1])
