extends Node2D

var ant = preload("res://ants/Ant.tscn")

@export var is_grid_cell_filled: Callable

func _ready() -> void:
	is_grid_cell_filled = default_is_grid_cell_filled

	var loop = get_loop(Vector2i(0, 3))

	for i in range(len(loop)):
		var m = $Marker.duplicate()
		add_child(m)
		m.show()
		m.text = str(i)
		m.position = loop[i] * 32 + Vector2i(16, 16)

	spawn_ant()

func spawn_ant():
	var loop = get_loop(Vector2i(0, 3))
	var random_test_ant: Ant = ant.instantiate()
	%Ants.add_child(random_test_ant)
	random_test_ant.grid_position = loop.pick_random()
	
	random_test_ant.move_to_tile(get_path_to_cell(loop, random_test_ant.grid_position, loop.pick_random()))

func get_loop(pos: Vector2i) -> Array[Vector2i]:
	var forward = Vector2(1, 0)
	if is_grid_cell_filled.call(pos + Vector2i(1, 0)):
		forward = Vector2(0, -1)
	if is_grid_cell_filled.call(pos + Vector2i(0, -1)):
		forward = Vector2(-1, 0)
	if is_grid_cell_filled.call(pos + Vector2i(-1, 0)):
		forward = Vector2(0, 1)

	var walkable_cells: Array[Vector2i] = []
	
	while pos not in walkable_cells:
		var under = Vector2i(Vector2(forward).rotated(PI / 2))

		if is_grid_cell_filled.call(pos + under) == false:
			forward = under
			pos = pos + under
			continue

		if is_grid_cell_filled.call(pos + Vector2i(forward)) == true:
			forward = Vector2i(Vector2(forward).rotated(-PI / 2))
			walkable_cells.push_back(pos)
			pos += Vector2i(forward)

		if is_grid_cell_filled.call(pos + under) == true:
			walkable_cells.push_back(pos)
			pos += Vector2i(forward)

	return walkable_cells

func get_path_to_cell(loop: Array[Vector2i], from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var index_of_from = loop.find(from)
	var index_of_to = loop.find(to)
	
	var path: Array[Vector2i]
	
	var i = index_of_from
	while i != index_of_to:
		path.push_back(loop[i])
		i+=+1
		if i > len(path):
			
			i = 0
	
	return path

func default_is_grid_cell_filled(cell: Vector2) -> bool:
	return $TileMap.get_cell_tile_data(0, cell) != null
