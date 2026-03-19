extends Node2D

signal end_turn

var DEFAULT_HAND = 6

var hand: Array[CardResource.Card] = []
var draw_pile: Array[CardResource.Card] = []
var discard_pile: Array[CardResource.Card] = []

var HomeStructure = preload("res://resources/structures/home.tres")

var energy: int:
	set(val):
		energy = val
		%EnergyLabel.text = "Energy: " + str(energy)

var ants: int = 0 :
	set(val):
		ants = val
		%AntsLabel.text = "Ants: " + str(ants)
		%Army.number_of_ants = val

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
	_on_terrain_update()
	
	%Army.number_of_ants = 10
	%Army.get_cell_to_walk_to = _get_ant_pathfindable_cell
	
	# The home is always placed
	%Structure.place_build(%Terrain.tilemap.map_to_local(Vector2i(0, 2)), Vector2i(0, 2), HomeStructure.new())

func _on_terrain_update():
	%Army.is_grid_cell_filled = _is_cell_filled
	%Army.spawn_position = Vector2(0, 3)
	%Army.spawn_ground_direction = Vector2(0, 1)
	%Army.generate_loop()

	for structure in %Structure.structures:
		var cells = structure.get_tiles()

		for c in cells:
			# We use Vector2i(0, 1) because structures can only be placed
			# vertically right now.
			# In the future this should be the direction of the floor.
			if %Army.is_cell_on_loop(c, Vector2i(0, 1)):
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
	return %Terrain.tilemap.get_cell_tile_data(pos) != null
	
func _validate_structure_at(card: CardResource.Card, at: Vector2):
		var structures_nodes: Array[Node2D] = %Structure.structures
		var in_range = false
		for node in structures_nodes:
			if (node.global_position / 32 - at).length() < card.structure.tiles_radius + 1.5:
				in_range = true
				break
		return in_range

func _get_ant_pathfindable_cell():
	var point = null

	var structures: Array = %Structure.structures

	var i = 0

	while point == null and i < 5:
		i+=1
		var structure = structures.pick_random()
		for tile in structure.get_tiles():
			if %Army.is_cell_on_loop(tile):
				point = tile
	
	return %Army.find_close_tiles(point, 4)


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
		%Terrain.show_selector(at, card.get_area(), %Terrain.PlacingMethod.Build, x)
		var s_position = %Terrain/GroundMap.to_global(%Terrain/GroundMap.map_to_local(at)) - $%Camera.position
		var valid = _validate_structure_at(card, at)
		%Camera/Visibility.material.set_shader_parameter("valid_placement", valid)
		%Camera/Visibility.material.set_shader_parameter("interactable_pos", Vector2(s_position.x / 1080., s_position.y / 1080.))
		%Camera/Visibility.material.set_shader_parameter("interactable_size", card.structure.tiles_radius * 32. / 1080.)

func _on_play_cards_cancel_aiming_card() -> void:
	%Terrain.hide_selector()

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

func on_turn_end() -> void:
	end_turn.emit()
	%EndTurnButton.disabled = true

	while len(hand) > 0:
		discard(0)
		# Give a litte animation
		await get_tree().create_timer(.05).timeout

func start_turn() -> void:
	%Camera.make_active()
	draw(DEFAULT_HAND)

	# Reset energy to maximum
	energy = 3
	ants += 10
	eff = 0

	%Utility.turn_resources()

	%EndTurnButton.disabled = false

func start_day(deck: Array[CardResource.Card]) -> void:
	energy = 3
	ants = 0
	eff = 0
	
	draw_pile = deck.duplicate()
	draw_pile.shuffle()

func _process(delta: float) -> void:
	var structure_pos: Array[Vector3] = []
	for s in %Structure.structures:
		structure_pos.append(Vector3((s.global_position.x - %Camera.position.x) / 1080., (s.global_position.y - %Camera.position.y) / 1080., 1))
	%Camera/Visibility.material.set_shader_parameter("discoveries", structure_pos)
	%Camera/Visibility.material.set_shader_parameter("interactable_pos", Vector2(-1,-1))
