# Handles terrain generation
extends Node2D

signal chunk_generated(Vector2i)
signal money_dug(value: int)
signal card_reward(cards: int)

# The enum value - 1 is used to grab the tileset
enum TerrainType{
	Air,
	Dirt,
	Rock,
	LightDirt,
	ShroomDirt,
	Mystery,
}

@export var initial_seed = 0 # The noise seed on ready. If set to 0, random seed.

@export var terrain_shape_noise: FastNoiseLite # The noise we will use to generate the terrain
@export var light_dirt_noise: FastNoiseLite
@export var rock_noise: FastNoiseLite
@export var gold_ore_noise: FastNoiseLite
@export var mystery_ore_noise: FastNoiseLite

@export var block_threshold: float = 0.5 # Threshold to place a block (less than)
@export var rock_threshold: float = 1.0 # Threshold to place an unbreakable block #TODO: Implement

@export var spawn_radius: float = 6.0

@export var chunk_size: int = 16

var generated_chunks = {}

var occupation_checks = [get_occupied_tiles]

@onready var tilemap: TileMapLayer = %GroundMap
@onready var healthmap: TileMapLayer = %HealthMap

var coin_bonus = 0

enum PlacingMethod {
	Dig,
	Build
}

# The amount of chunks from the left to right of the map
var MAP_CHUNKS = 10
var MAP_SIZE = Rect2i(-MAP_CHUNKS / 2, -MAP_CHUNKS / 2, MAP_CHUNKS, MAP_CHUNKS)

@onready var rng = RandomNumberGenerator.new()

func _ready():
	if initial_seed == 0:
		initial_seed = randi()
	rng.seed = initial_seed
	reset_map(initial_seed)
	generate()

func reset_map(new_seed) -> void:
	tilemap.clear()
	terrain_shape_noise.seed = new_seed
	rock_noise.seed = new_seed
	gold_ore_noise.seed = new_seed
	light_dirt_noise.seed = new_seed
	mystery_ore_noise.seed = new_seed

func generate() -> void:
	var rect = MAP_SIZE
	# We generate the ring of chunks around the camera to make sure an unloaded chunk is never visible
	for y in MAP_SIZE.size.y:
		for x in MAP_SIZE.size.x:
			generate_chunk(MAP_SIZE.position.x + x, MAP_SIZE.position.y + y)

func generate_chunk(chunk_x: int, chunk_y: int) -> void: # Generate a single chunk of terrain
	if generated_chunks.get(Vector2i(chunk_x, chunk_y), false):
		return
	generated_chunks[Vector2i(chunk_x, chunk_y)] = true
	for y in chunk_size:
		for x in chunk_size:
			var potential_pos = Vector2i(
				chunk_x * chunk_size + x,
				chunk_y * chunk_size + y
			)
			
			var my_value = get_cellv(potential_pos)
			
			if my_value == TerrainType.Mystery:
				tilemap.set_cell(potential_pos, TerrainType.ShroomDirt - 1, Vector2i(6, 6))
				continue

			var top_left = get_cellv(potential_pos + Vector2i(-1, -1)) == my_value
			var top_middle = get_cellv(potential_pos + Vector2i(0, -1)) == my_value
			var top_right = get_cellv(potential_pos + Vector2i(1, -1)) == my_value
			var middle_left = get_cellv(potential_pos + Vector2i(-1, 0)) == my_value
			var middle_right = get_cellv(potential_pos + Vector2i(1, 0)) == my_value
			var bottom_left = get_cellv(potential_pos + Vector2i(-1, 1)) == my_value
			var bottom_middle = get_cellv(potential_pos + Vector2i(0, 1)) == my_value
			var bottom_right = get_cellv(potential_pos + Vector2i(1, 1)) == my_value

			var neighbor = find_atlas_chord_from_neighbors(
				top_left,
				top_middle,
				top_right,
				middle_left,
				middle_right,
				bottom_left,
				bottom_middle,
				bottom_right
			)

			tilemap.set_cell(potential_pos, get_cellv(potential_pos) - 1, neighbor)

	chunk_generated.emit(Vector2i(chunk_x, chunk_y))

func get_cell(x: int, y: int) -> TerrainType: # Check if there is a cell here
	if sqrt(x**2 + y**2) <= spawn_radius:
		if y < 4:
			return TerrainType.Air
		else:
			return TerrainType.Dirt
	var point = terrain_shape_noise.get_noise_2d(x, y)
		
	if point > 0.3:
		return TerrainType.Air
		
	var dist_to_origin = Vector2(x, y).distance_to(Vector2(0, 0))

	if mystery_ore_noise.get_noise_2d(x, y) > 0.8 - (dist_to_origin / 1000):
		return TerrainType.Mystery

	if gold_ore_noise.get_noise_2d(x, y) > 0.4 - (dist_to_origin / 500):
		return TerrainType.ShroomDirt

	if rock_noise.get_noise_2d(x, y) > 0.25 - (dist_to_origin / 200):
		return TerrainType.Rock

	if light_dirt_noise.get_noise_2d(x, y) > 0.05:
		return TerrainType.LightDirt

	return TerrainType.Dirt


func get_cellv(vec: Vector2) -> TerrainType:
	return get_cell(vec.x, vec.y)
	
# I am really sorry
var extra_particle_generators: Array[GPUParticles2D] = []
#func destroy_particles():
	#await get_tree().create_timer(1.0).timeout
	#for p in extra_particle_generators:
		#p.queue_free()

# Radius is a square radius
func destroy(cell_coordinate_center: Vector2i, cells: Array[Rect2i], power: int, luck: int) -> bool:
	var area = get_area(cell_coordinate_center, cells)
	var cells_to_damage: Array[Vector2i] = []
	var building_cells: Array[Vector2i] = %Structure.building_occupation()
	
	var grow = 0
	var pots = 0
	for group in %Structure.structure_groups_in_range(area):
		for structure in group:
			if structure.structure.resource.structure_name == "Training Camp":
				grow += 1
			if structure.structure.resource.structure_name == "Mushroom Bar":
				power += 1
			if structure.structure.resource.structure_name == "Campfire":
				coin_bonus += 2
			if structure.structure.resource.structure_name == "Pot":
				pots += 1
	grow_area(area, grow)
	
	for cell in area:
		if tilemap.get_cell_source_id(cell) >= 0:
			if cell in building_cells:
				return false
			cells_to_damage.append(cell)
	
	var value_gained := 0
	var cells_to_remove: Array[Vector2i] = []
	for cell in cells_to_damage:
		var p = $BreakParticles.duplicate()
		add_child(p)
		p.emitting = true
		p.position = $GroundMap.map_to_local(cell)
		extra_particle_generators.append(p)
		p.amount = 4

		var cell_data = tilemap.get_cell_tile_data(cell)
		var initial_health = cell_data.get_custom_data("initial_health")
		if healthmap.get_cell_source_id(cell) == -1: # Not been damaged before
			var health = initial_health - power
			if health <= 0:
				var reward = reward_cell(cell_data)
				value_gained += reward + pots
				cells_to_remove.append(cell)
				%Cracks.set_cell(cell)
				
				for i in range(0,reward):
					var f = $FungusGuy.duplicate()
					f.show()
					f.reset_physics_interpolation()
					f.position = $GroundMap.map_to_local(cell)
					add_child(f)
					f.on_create()
				continue
			healthmap.set_cell(cell, 0, Vector2i(health - power, 0))
			set_cracks_for_cell(cell, health, initial_health)
			continue
		
		if healthmap.get_cell_atlas_coords(cell).x - power < 0:
			value_gained += reward_cell(cell_data) + pots
			cells_to_remove.append(cell)
			%Cracks.set_cell(cell)
			healthmap.set_cell(cell)
		else:
			var health = healthmap.get_cell_atlas_coords(cell).x
			healthmap.set_cell(cell, 0, Vector2i(health - power, 0))
			set_cracks_for_cell(cell, health, initial_health)
			
	tilemap.set_cells_terrain_connect(cells_to_remove, 0, -1)

	money_dug.emit(value_gained)

	#destroy_particles()
	
	$Audio/Explosion.play(0.02)
		

	return true

func reward_cell(cell_data: Variant) -> int:
	var value = cell_data.get_custom_data("value")
	for i in cell_data.get_custom_data("random_value") + coin_bonus:
		value += int(rng.randf() <= 0.01)
	return value

func set_cracks_for_cell(cell: Vector2i, health: int, initial_health: int):
	var crack_number
	if health == initial_health:
		crack_number = 0
	else:
		crack_number = floor(8 - (float(health) / float(initial_health) * 8)) + 1

	%Cracks.set_cell(cell, 2, Vector2i(0, crack_number))

func get_occupied_tiles() -> Array[Vector2i]:
	tilemap.get_used_cells()
	return tilemap.get_used_cells()

func get_occupied_cells() -> Array[Vector2i]:
	var occupied_cells: Array[Vector2i] = []
	for check in occupation_checks:
		occupied_cells += check.call()
	return occupied_cells
					
func show_selector(cell_coordinate_center: Vector2i, cells: Array[Rect2i], placing_method: int, required_ground, touches_path):
	$Selection.clear()
	$Selection.show()
	
	var area: Array[Vector2i] = get_area(cell_coordinate_center, cells)
	
	if placing_method == PlacingMethod.Dig:
		var groups_in_range: Array[Array] = %Structure.structure_groups_in_range(area)
		var building_cells: Array[Vector2i] = %Structure.building_occupation()
		
		var training_camps = 0
		for group in groups_in_range:
			for structure in group:
				if structure == null:
					continue
				if structure.structure.resource.structure_name == "Training Camp":
					training_camps += 1
		grow_area(area, training_camps)
		
		for cell in area:
			if (cell in building_cells and tilemap.get_cell_source_id(cell) >= 0) or !touches_path:
				$Selection.set_cell(cell, 0, Vector2(1,0), 0)
			else:
				$Selection.set_cell(cell, 0, Vector2(0,0), 0)
				
	else:
		var occupied_cells: Array[Vector2i] = get_occupied_cells()
		var has_ground = false
		if required_ground != null:
			for dirt_cell in required_ground:
				var rect_center = cell_coordinate_center + dirt_cell.position
				var section_has_ground = true
				for x in range(ceil(rect_center.x),ceil(rect_center.x+dirt_cell.size.x)):
					for y in range(ceil(rect_center.y),ceil(rect_center.y+dirt_cell.size.y)):
						if %GroundMap.get_cell_tile_data(Vector2(x, y)) == null:
							section_has_ground = false
				if section_has_ground:
					has_ground = true
		
					
		for cell in area:
			if placing_method == PlacingMethod.Build and (cell in occupied_cells or not has_ground or not touches_path):
				$Selection.set_cell(cell, 0, Vector2(1,0), 0)
			#elif cell in occupied_cells:
			#	$Selection.set_cell(cell, 0, Vector2(1,0), 0)
			else:
				$Selection.set_cell(cell, 0, Vector2(0,0), 0)

func get_area(cell_coordinate_center: Vector2i, cells: Array[Rect2i]) -> Array[Vector2i]:
	var area: Array[Vector2i] = []
	for rect in cells:
			var rect_center = cell_coordinate_center + rect.position
			for x in range(ceil(rect_center.x),ceil(rect_center.x+rect.size.x)):
				for y in range(ceil(rect_center.y),ceil(rect_center.y+rect.size.y)):
					area.append(Vector2i(x,y))
					
	return area

func grow_area(area: Array[Vector2i], n: int) -> void:
	for i in range(n):
		area.append_array(border(area))

func border(area: Array[Vector2i]):
	var border: Array[Vector2i] = []
	for cell in area:
		var neighbors: Array[Vector2i] = [
			Vector2i(cell.x+1, cell.y),
			Vector2i(cell.x+1, cell.y+1),
			Vector2i(cell.x, cell.y+1),
			Vector2i(cell.x-1, cell.y+1),
			Vector2i(cell.x-1, cell.y),
			Vector2i(cell.x-1, cell.y-1),
			Vector2i(cell.x, cell.y-1),
			Vector2i(cell.x+1, cell.y-1)
		]
		for neighbor in neighbors:
			if !neighbor in area and !neighbor in border:
				border.append(neighbor)
	
	return border
	
func hide_selector():
	$Selection.hide()

func on_coin_bonus(n: int) -> void:
	coin_bonus += n

func clear_coin_bonus(tick: int) -> void:
	coin_bonus = 0

func find_atlas_chord_from_neighbors(top_left, top_middle, top_right, middle_left, middle_right, bottom_left, bottom_middle, bottom_right) -> Vector2i:
	if (
		top_left == true
		&& top_middle == true
		&& top_right == true
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == true
		&& bottom_middle == true
		&& bottom_right == true
	):
		return Vector2i(1, 0)

	if (
		top_middle == false
		&& middle_left == false
		&& middle_right == true
		&& bottom_middle == true
		&& bottom_right == true
	):
		return Vector2i(2, 0)

	if (
		top_middle == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == true
		&& bottom_middle == true
		&& bottom_right == true
	):
		return Vector2i(3, 0)

	if (
		top_middle == false
		&& middle_left == true
		&& middle_right == false
		&& bottom_middle == true
	):
		return Vector2i(4, 0)

	if (
		top_middle == false
		&& middle_left == false
		&& middle_right == false
		&& bottom_middle == true
	):
		return Vector2i(5, 0)

	if (
		top_left == true
		&& top_middle == true
		&& top_right == true
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == true
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(6, 0)

	if (
		top_left == true
		&& top_middle == true
		&& top_right == true
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == false
		&& bottom_middle == true
		&& bottom_right == true
	):
		return Vector2i(0, 1)

	if (
		top_middle == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == true
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(1, 1)

	if (
		top_middle == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == false
		&& bottom_middle == true
		&& bottom_right == true
	):
		return Vector2i(2, 1)

	if (
		top_middle == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == false
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(3, 1)

	if (
		top_middle == false
		&& middle_left == true
		&& middle_right == false
		&& bottom_left == false
		&& bottom_middle == true
	):
		return Vector2i(4, 1)

	if (
		top_middle == true
		&& top_right == true
		&& middle_left == false
		&& middle_right == true
		&& bottom_middle == true
		&& bottom_right == true
	):
		return Vector2i(5, 1)

	if (
		top_left == true
		&& top_middle == true
		&& middle_left == true
		&& middle_right == false
		&& bottom_left == true
		&& bottom_middle == true
	):
		return Vector2i(6, 1)

	if (
		top_middle == true
		&& middle_left == false
		&& middle_right == false
		&& bottom_middle == true
	):
		return Vector2i(0, 2)

	if (
		top_left == true
		&& top_middle == true
		&& top_right == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == true
		&& bottom_middle == true
		&& bottom_right == true
	):
		return Vector2i(1, 2)

	if (
		top_left == false
		&& top_middle == true
		&& top_right == true
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == true
		&& bottom_middle == true
		&& bottom_right == true
	):
		return Vector2i(2, 2)

	if (
		top_middle == true
		&& middle_left == true
		&& middle_right == false
		&& bottom_left == true
		&& bottom_middle == true
	):
		return Vector2i(3, 2)

	if (
		top_left == true
		&& top_middle == true
		&& middle_left == true
		&& middle_right == false
		&& bottom_left == false
		&& bottom_middle == true
	):
		return Vector2i(4, 2)

	if (
		top_left == false
		&& top_middle == true
		&& top_right == false
		&& middle_left == true
		&& middle_right == false
		&& bottom_left == true
		&& bottom_middle == true
	):
		return Vector2i(5, 2)

	if (
		top_middle == false
		&& middle_left == false
		&& middle_right == true
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(6, 2)

	if (
		top_middle == true
		&& top_right == true
		&& middle_left == false
		&& middle_right == true
		&& bottom_middle == false
	):
		return Vector2i(0, 3)

	if (
		top_left == true
		&& top_middle == true
		&& top_right == true
		&& middle_left == true
		&& middle_right == true
		&& bottom_middle == false
	):
		return Vector2i(1, 3)

	if (
		top_left == true
		&& top_middle == true
		&& middle_left == true
		&& middle_right == false
		&& bottom_middle == false
	):
		return Vector2i(2, 3)

	if (
		top_middle == true
		&& middle_left == false
		&& middle_right == false
		&& bottom_middle == false
	):
		return Vector2i(3, 3)

	if (
		top_left == true
		&& top_middle == true
		&& top_right == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == true
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(4, 3)

	if (
		top_left == true
		&& top_middle == true
		&& top_right == true
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == false
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(5, 3)

	if (
		top_left == true
		&& top_middle == true
		&& top_right == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_middle == false
	):
		return Vector2i(6, 3)

	if (
		top_left == false
		&& top_middle == true
		&& top_right == true
		&& middle_left == true
		&& middle_right == true
		&& bottom_middle == false
	):
		return Vector2i(0, 4)

	if (
		top_left == false
		&& top_middle == true
		&& top_right == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_middle == false
	):
		return Vector2i(1, 4)


	if (
		top_middle == true
		&& top_right == false
		&& middle_left == false
		&& middle_right == true
		&& bottom_middle == false
	):
		return Vector2i(2, 4)

	if (
		top_middle == false
		&& middle_left == false
		&& middle_right == true
		&& bottom_middle == false
	):
		return Vector2i(3, 4)

	if (
		top_middle == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_middle == false
	):
		return Vector2i(4, 4)

	if (
		top_middle == false
		&& middle_left == true
		&& middle_right == false
		&& bottom_middle == false
	):
		return Vector2i(5, 4)

	if (
		top_middle == false
		&& middle_left == false
		&& middle_right == false
		&& bottom_middle == false
	):
		return Vector2i(6, 4)

	if (
		top_left == false
		&& top_middle == true
		&& top_right == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == true
		&& bottom_middle == true
		&& bottom_right	== true
	):
		return Vector2i(0, 5)

	if (
		top_left == false
		&& top_middle == true
		&& top_right == true
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == false
		&& bottom_middle == true
		&& bottom_right	== true
	):
		return Vector2i(1, 5)

	if (
		top_middle == true
		&& top_right == true
		&& middle_left == false
		&& middle_right == true
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(2, 5)

	if (
		top_middle == true
		&& top_right == false
		&& middle_left == false
		&& middle_right == true
		&& bottom_middle == true
		&& bottom_right	== true
	):
		return Vector2i(3, 5)

	if (
		top_middle == true
		&& top_right == false
		&& middle_left == false
		&& middle_right == true
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(4, 5)

	if (
		top_left == false
		&& top_middle == true
		&& middle_left == true
		&& middle_right == false
		&& bottom_middle == false
	):
		return Vector2i(5, 5)

	if (
		top_left == false
		&& top_middle == true
		&& top_right == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == true
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(6, 5)

	if (
		top_left == false
		&& top_middle == true
		&& top_right == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == false
		&& bottom_middle == true
		&& bottom_right == true
	):
		return Vector2i(0, 6)

	if (
		top_left == false
		&& top_middle == true
		&& top_right == true
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == false
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(1, 6)

	if (
		top_left == true
		&& top_middle == true
		&& top_right == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == false
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(2, 6)

	if (
		top_left == false
		&& top_middle == true
		&& top_right == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == false
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(3, 6)

	if (
		top_left == false
		&& top_middle == true
		&& top_right == true
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == true
		&& bottom_middle == true
		&& bottom_right == false
	):
		return Vector2i(4, 6)

	if (
		top_left == true
		&& top_middle == true
		&& top_right == false
		&& middle_left == true
		&& middle_right == true
		&& bottom_left == false
		&& bottom_middle == true
		&& bottom_right == true
	):
		return Vector2i(5, 6)

	return Vector2i(1, 0)
