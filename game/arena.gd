extends Node2D

var DEFAULT_HAND = 6

var hand: Array[CardResource.Card] = []
var deck: Array[CardResource.Card] = []
var draw_pile: Array[CardResource.Card] = []
var discard_pile: Array[CardResource.Card] = []

var HomeStructure = preload("res://resources/structures/home.tres")

var _energy: int
var energy: int:
	set(val):
		_energy = val
		%EnergyLabel.text = "Energy: " + str(_energy)
	get():
		return _energy

var _ants: int
var ants: int:
	set(val):
		_ants = val
		%AntsLabel.text = "Ants: " + str(_ants)
		%Army.number_of_ants = val
	get():
		return _ants

var eff: int

var player_position: Vector2i:
	set(pos):
		%Player.position = pos * 32
	get():
		return %Player.position / 32

func _ready():
	%Terrain.occupation_checks.append(%Structure.building_occupation)
	%Structure.occupation_checker = %Terrain.get_occupied_cells
	%Structure.has_terrain = _is_cell_filled
	%Army.get_cell_to_walk_to = _get_ant_pathfindable_cell

	var cards: Array[CardResource.Card] = [
		load("res://resources/cards/fungus_bar.tres").new(),
		load("res://resources/cards/fungus_bar.tres").new(),
		load("res://resources/cards/fungus_bar.tres").new(),
		load("res://resources/cards/breakfast.tres").new(),
		load("res://resources/cards/beam_drill.tres").new(),
		load("res://resources/cards/dirt_nap.tres").new(),
		load("res://resources/cards/super_drill.tres").new(),
		load("res://resources/cards/drill.tres").new(),
		load("res://resources/cards/drill.tres").new(),
		load("res://resources/cards/drill.tres").new(),
		load("res://resources/cards/drill.tres").new(),
		load("res://resources/cards/drill.tres").new(),
		load("res://resources/cards/big_drill.tres").new(),
		load("res://resources/cards/super_buff.tres").new(),
		load("res://resources/cards/bulldozer.tres").new(),
		load("res://resources/cards/brainstorm.tres").new(),
		load("res://resources/cards/bridge.tres").new(),
		load("res://resources/cards/bridge.tres").new(),
		load("res://resources/cards/bridge.tres").new(),
		load("res://resources/cards/bridge.tres").new(),
		load("res://resources/cards/bridge.tres").new(),
		]

	deck.append_array(cards)
	draw_pile.append_array(cards)
	draw_pile.shuffle()
	draw(DEFAULT_HAND)
	
	energy = 3
	ants = 30
	eff = 0

	# The home is always visible
	%Structure.place_build(%Terrain.tilemap.map_to_local(Vector2i(0, 2)), Vector2i(0, 2), HomeStructure.new())
	_on_terrain_update()


func _on_terrain_update():
	%Army.is_grid_cell_filled = _is_cell_filled
	%Army.cell_in_structure_range = _cell_in_structure_range
	%Army.spawn_position = Vector2(0, 3)
	%Army.spawn_ground_direction = Vector2(0, 1)
	%Army.generate_loop()

	for structure in %Structure.structures:
		for c in structure.structure.resource.path_finding_points:
			
			print(c, %Army.is_cell_on_loop(c + (Vector2i(structure.position) / 32)))
			if %Army.is_cell_on_loop(c + (Vector2i(structure.position) / 32)):
				structure.set_connected_to_loop(true)
				break


func draw(n: int):
	for i in range(n):
		if len(draw_pile) == 0:
			# When the draw pile is empty, we put the discard pile back
			# into the draw pile.
			draw_pile = discard_pile
			discard_pile = []
		if !draw_pile.is_empty():
			var card = draw_pile.pop_at(randi() % len(draw_pile))
			hand.append(card)
			%PlayCards.draw_card(card)
		else:
			break

func discard(i: int):
	%PlayCards.discard_card(i)
	discard_pile.append(hand[i])
	hand.pop_at(i)
	

func _is_cell_filled(pos: Vector2i):
	for structure in %Structure.structures:
		if structure.structure.resource.structure_name == "Bridge":
			if pos in structure.get_tiles():
				return true

	return %Terrain.tilemap.get_cell_tile_data(pos) != null
	
func _validate_structure_at(card: CardResource.Card, at: Vector2):
		var structures_nodes: Array[Node2D] = %Structure.structures
		var in_range = false
		for node in structures_nodes:
			if (node.global_position / 32 - at).length() < card.structure.tiles_radius + 1.5:
				in_range = true
				break
		return in_range

func _cell_in_structure_range(cell: Vector2i):
	for structure in %Structure.structures:
		if structure.position.distance_to(cell * 32 + Vector2i(16, 16)) < structure.structure.resource.tiles_radius * 32:
			return true
	
	return false

func _get_ant_pathfindable_cell():
	var point = null

	var structures: Array = %Structure.structures

	var structure = structures.pick_random()
	for p in structure.structure.resource.path_finding_points:
		var cell = Vector2i(p) + (Vector2i(structure.position) / 32)
		if %Army.is_cell_on_loop(cell):
			point = Vector2i(cell)

	if point:
		return %Army.find_close_tiles(point, 4)
	else:
		return %Army.find_close_tiles(%Army.spawn_position, 3)


func _on_play_cards_card_used(card: CardResource.Card, at: Vector2, index: int) -> void:
	var success = false
	var x = 0
	print("Using card: ", card, at)
	if card.energy_cost > energy or card.ant_cost > ants:
		print("Card Too Expensive")
		return

	if card.get_type() == CardResource.CardType.Build:
		var in_range = _validate_structure_at(card, at)
		if in_range == false:
			print("Cannot Play Structure out of Range")
			%Terrain.hide_selector()
			return
	
	if card.energy_cost < 0:
		x += energy
		energy = 0
	elif card.ant_cost < 0:
		x += ants / 10
		ants = 0

	if card.get_type() == CardResource.CardType.Dig:
		success = %Terrain.destroy(at, card.get_area(), card.power() + eff, x)
		if success:
			%Camera.shake(Vector2(3,0), 0.95)
	if card.get_type() == CardResource.CardType.Move:
		player_position = at
		success = true
	if card.get_type() == CardResource.CardType.Build:
		success = %Structure.place_build(%Terrain.tilemap.map_to_local(at), at, card.structure.new())
		%Camera.shake(Vector2(0,1), 0.9)
	if card.get_type() == CardResource.CardType.Utility:
		success = %Utility.utilize(card.utility, x)

	%Terrain.hide_selector()
	_on_terrain_update()
	
	if (success):
		if energy > 0:
			energy -= card.energy_cost
		if ants > 0:
			ants -= card.ant_cost
		discard(index)

func _on_play_cards_aiming_card(card: CardResource.Card, at: Vector2, i: int) -> void:
	var x = 0
	if card.energy_cost > energy or card.ant_cost > ants:
		return
		
	if card.energy_cost < 0:
		x += energy
	elif card.ant_cost < 0:
		x += ants / 10
	
	%PlayCards.show_target_arrow(i)
	if card.get_type() == CardResource.CardType.Dig:
		%Terrain.show_selector(at, card.get_area(), %Terrain.PlacingMethod.Dig, x)
	if card.get_type() == CardResource.CardType.Build:
		%Terrain.show_selector(at, card.structure.size, %Terrain.PlacingMethod.Build, x, card.structure.requires_contact)
		var s_position = %Terrain/GroundMap.to_global(%Terrain/GroundMap.map_to_local(at)) - $%Camera.position
		var valid = _validate_structure_at(card, at)
		%Camera/Visibility.material.set_shader_parameter("valid_placement", valid)
		%Camera/Visibility.material.set_shader_parameter("interactable_pos", Vector2(s_position.x / 1080., s_position.y / 1080.))
		%Camera/Visibility.material.set_shader_parameter("interactable_size", card.structure.tiles_radius * 32. / 1080.)

func _on_play_cards_cancel_aiming_card() -> void:
	%Terrain.hide_selector()

func _on_end_turn_button_button_down() -> void:
	# At the end of the turn, we want to draw cards

	%EndTurnButton.disabled = true

	while len(hand) > 0:
		discard(0)
		# Give a litte animation
		await get_tree().create_timer(.05).timeout

	draw(DEFAULT_HAND)

	# Reset energy to maximum
	energy = 3
	ants += 10
	eff = 0
	
	%Utility.turn_resources()

	%EndTurnButton.disabled = false

func _on_terrain_chunk_generated(Vector2i: Variant) -> void:
	_on_terrain_update()
	
func _on_utility_energy_gain(n: int) -> void:
	energy += n
	
func _on_utility_ants_gain(n: int) -> void:
	ants += n

func _on_utility_draw_gain(n: int) -> void:
	draw(n)
	
func _on_utility_eff_gain(n: int) -> void:
	eff += n


func _on_clock_day_start(day: int) -> void:
	%DayLabel.text = "Day " + str(day)
	%TurnLabel.text = "Turn 0"
	
	ants = 0
	
	for s in %Structure.structures:
		if s.lifetime == 0:
			%Structure.structures.erase(s)
			s.queue_free()
		elif s.lifetime > 0:
			s.lifetime -= 1

func _on_clock_day_tick(tick: int) -> void:
	%TurnLabel.text = "Turn " + str(tick)

func _process(delta: float) -> void:
	var structure_pos: Array[Vector3] = []
	for s in %Structure.structures:
		structure_pos.append(Vector3((s.global_position.x - $Camera.position.x) / 1080., (s.global_position.y - $Camera.position.y) / 1080., 1))
	%Camera/Visibility.material.set_shader_parameter("discoveries", structure_pos)
	%Camera/Visibility.material.set_shader_parameter("interactable_pos", Vector2(-1,-1))
