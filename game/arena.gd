extends Node2D

signal day_end
signal money_earned(money: int)
signal card_earned(card: CardResource)
signal ant_count_changed(ant_count: int)
signal energy_count_changed(energy: int)
signal on_turn_changed(n: int)
signal card_played(card: CardResource.Card)
signal destroy_card(card: CardResource.Card)

@export var game: Game

var allow_end_turn = true

const DEFAULT_HAND = 6

var hand: Array[CardResource.Card] = []
var draw_pile: Array[CardResource.Card] = []
var discard_pile: Array[CardResource.Card] = []
var exhaust_pile: Array[CardResource.Card] = []

var HomeStructure = preload("res://resources/structures/home.tres")

var energy: int:
	set(val):
		energy = val
		%EnergyLabel.text = "Energy: " + str(energy)
		energy_count_changed.emit(energy)

var ants: int = 0 :
	set(val):
		ants = val
		%AntsLabel.text = "Ants: " + str(ants)
		%Army.number_of_ants = val
		ant_count_changed.emit(ants)

var eff: int

var player_position: Vector2i:
	set(pos):
		%Player.position = pos * 32
	get():
		return %Player.position / 32

@onready var rng = RandomNumberGenerator.new()

func _ready():
	%Terrain.occupation_checks.append(%Structure.building_occupation)
	%Terrain.has_terrain = _is_cell_filled
	%Structure.occupation_checker = %Terrain.get_occupied_cells
	%Structure.has_terrain = _is_cell_filled
	_on_terrain_update()
	
	%Army.number_of_ants = 0
	%Army.get_cell_to_walk_to = _get_ant_pathfindable_cell
	
	# The home is always placed
	%Structure.place_build(%Terrain.tilemap.map_to_local(Vector2i(0, 2)), Vector2i(0, 2), HomeStructure.new(), 0)
	_on_terrain_update()

func _on_terrain_update():
	%Army.is_grid_cell_filled = _is_cell_filled
	%Army.cell_in_structure_range = _cell_in_structure_range
	%Army.spawn_position = Vector2(0, 3)
	%Army.spawn_ground_direction = Vector2(0, 1)
	%Army.generate_loop()

	for structure in %Structure.structures:
		for c in structure.structure.resource.path_finding_points:
			if %Army.is_cell_on_loop(c + structure.get_tile_position()):
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
			var card = draw_pile.pop_at(rng.randi() % len(draw_pile))
			hand.append(card)
			%PlayCards.draw_card(card)
		else:
			break

func discard(i: int):
	%PlayCards.discard_card(i)
	discard_pile.append(hand[i])
	hand.pop_at(i)

func exhaust(i: int):
	%PlayCards.discard_card(i)
	exhaust_pile.append(hand[i])
	hand.pop_at(i)

func destroy(i: int):
	%PlayCards.discard_card(i)
	var card = hand.pop_at(i)
	destroy_card.emit(card)

func _is_cell_filled(pos: Vector2i):
	for structure in %Structure.structures:
		if structure.structure.resource.structure_name in ["Bridge", "Ladder"]:
			if pos in structure.get_tiles():
				return true

	return %Terrain.tilemap.get_cell_tile_data(pos) != null
	
func _validate_structure_at(card: CardResource.Card, at: Vector2i):
	var nodes = card.structure.path_finding_points.duplicate()
	if nodes.is_empty:
		nodes = %Terrain.get_area(at, card.structure.size)
	for node in nodes:
		node += at
	%Terrain.grow_area(nodes, 1)
	
	for node in nodes:
		if %Army.is_cell_on_loop(node):
			return true
	
	return false
	
func _cell_in_structure_range(cell: Vector2i):
	for structure in %Structure.structures:
		if structure.position.distance_to(cell * 32 + Vector2i(16, 16)) < structure.structure.resource.tiles_radius * 32:
			return true
	
	return false

func _get_ant_pathfindable_cell():
	var point = null

	var structures: Array = %Structure.structures

	var structure = structures[len(structures) - 1]
	for p in structure.structure.resource.path_finding_points:
		var cell = Vector2i(p) + (Vector2i(structure.position) / 32)
		if %Army.is_cell_on_loop(cell):
			point = Vector2i(cell)

	if point:
		return %Army.find_close_tiles(point, 4)
	else:
		return %Army.find_close_tiles(%Army.spawn_position, 3)


func dig_area_touches_path(dig_area: Array[Rect2i], center: Vector2i) -> bool:
	var cells = dig_area.duplicate()
	var grow = 1
	
	for group in %Structure.structure_groups_in_range(%Terrain.get_area(center, cells)):
		for structure in group:
			if structure == null: continue
			if structure.structure.resource.structure_name == "Training Camp":
				grow += 1
	
	for rect in cells:
		rect = rect.grow(grow)
		var rect_center = center + rect.position
		for x in range(rect_center.x,rect_center.x+rect.size.x):
			for y in range(rect_center.y,rect_center.y+rect.size.y):
				if (x == rect_center.x or x == rect_center.x+rect.size.x - 1) and (y == rect_center.y or y == rect_center.y+rect.size.y - 1):
					# I dont want to allow corners
					continue
				if %Army.is_cell_on_loop(Vector2i(x, y)):
					return true

	return false


func x_area(cells: Array[Rect2i], X: int) -> Array[Rect2i]:
	var area = cells.duplicate()
	
	for i in area.size():
		if area[i].size.x < 0:
			area[i] = Rect2i((area[i].size.x * X)/2, area[i].position.y, -area[i].size.x * X, area[i].size.y)
		if cells[i].size.y < 0:
			area[i] = Rect2i(area[i].position.x, (area[i].size.y * X)/2, area[i].size.x, -area[i].size.y * X)
	
	return area

func _on_play_cards_card_used(card: CardResource.Card, at: Vector2, index: int) -> void:
	var playable = true
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
	elif card.ant_cost < 0:
		x += ants / 10
	
	if card.utility != null:
		if card.utility.discard.size() > 0 and card.utility.discard[0] >= hand.size():
			playable = false
		if playable:
			success = success or %Utility.utilize(card.utility, x, index)
	if playable:
		if card.get_type() == CardResource.CardType.Dig:
			var area = card.get_area()
			if x > 0:
				area = x_area(area, x)
			var power = card.power()
			if power < 0:
				power = x
			power += eff
			if dig_area_touches_path(area, at):
				success = %Terrain.destroy(at, area, power, x)
			else:
				success = false
			if success:
				%Camera.shake(Vector2(3,0), 0.95)
		if card.get_type() == CardResource.CardType.Move:
			player_position = at
			success = true
		elif card.get_type() == CardResource.CardType.Build:
			if _validate_structure_at(card, at):
				success = %Structure.place_build(%Terrain.tilemap.map_to_local(at), at, card.structure.new(), x)
				if success:
					%Camera.shake(Vector2(0,1), 0.9)
		elif card.card_name == "Perpetual Stew":
			success = %Utility.stew(at)

	%Terrain.hide_selector()
	_on_terrain_update()

	if (success):
		card_played.emit(card)
		# Use all all energy for X cost cards
		if card.energy_cost < 0:
			energy = 0
		elif card.ant_cost < 0:
			ants = 0
		
		if energy > 0:
			energy -= card.energy_cost
		if ants > 0:
			ants -= card.ant_cost
		
		if card.should_exhaust():
			exhaust(index)
		elif card.single_use:
			destroy(index)
		else:
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
		var area = card.get_area()
		if x > 0:
			area = x_area(area, x)
		var dig_touches_path = dig_area_touches_path(area, at)
		%Terrain.show_selector(at, area, %Terrain.PlacingMethod.Dig, null, dig_touches_path)
	if card.get_type() == CardResource.CardType.Build:
		var s_position = %Terrain/GroundMap.to_global(%Terrain/GroundMap.map_to_local(at)) - $%Camera.position
		var valid = _validate_structure_at(card, at)
		%Terrain.show_selector(at, card.structure.size, %Terrain.PlacingMethod.Build, card.structure.required_ground, valid)
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

func _on_utility_discard_gain(n: int, source: int) -> void:
	for i in range(n):
		if hand.size() == 0:
			break
		var discard = randi_range(0, hand.size())
		while discard == source:
			if hand.size() == 1:
				break
			discard = randi_range(0, hand.size())
		discard(discard)
		if discard < source:
			source -= 1

func _on_utility_draw_gain(n: int) -> void:
	draw(n)

func _on_utility_eff_gain(n: int) -> void:
	eff += n

func _on_utility_money_gain(n: int) -> void:
	money_earned.emit(n)

func _on_clock_day_end(day: int) -> void:	
	%Camera.go_home()
	# Copied from elsewhere in this file
	while len(hand) > 0:
		discard(0)
		# Give a litte animation
		await get_tree().create_timer(.03).timeout
	
	day_end.emit()
	
	%DayLabel.text = "Day " + str(day)
	%TurnLabel.text = "Turn 0"
	
	%Army.reset_ants()
	ants = 0

	var temp = []
	var i = len(%Structure.structures) - 1
	while i >= 0:
		var s = %Structure.structures[i]
		if s.lifetime == 0:
			discard_pile.append(exhaust_pile.pop_back())
			%Structure.structures.pop_at(i)
			s.queue_free()
		elif s.lifetime > 0:
			s.lifetime -= 1
			temp.append(exhaust_pile.pop_back())
		else:
			exhaust_pile.push_front(exhaust_pile.pop_back())
		i -= 1
	for n in range(len(temp)):
		exhaust_pile.append(temp.pop_back())
	
	%Structure.determine_links()
	%Structure.determine_groups()
	_on_terrain_update()

func _on_clock_day_tick(tick: int) -> void:
	%TurnLabel.text = "Turn " + str(tick)
	on_turn_changed.emit(tick)
	on_turn_end()

func on_turn_end() -> void:
	%EndTurnButton.disabled = true

	while len(hand) > 0:
		discard(0)
		# Give a litte animation
		await get_tree().create_timer(.03).timeout

	start_turn()

func start_turn(initial_hand: Array[CardResource.Card] = []):
	%Camera.make_active()
	if len(initial_hand) == 0:
		draw(DEFAULT_HAND)
	else:
		hand = initial_hand
		for card in initial_hand:
			%PlayCards.draw_card(card)

	# Reset energy to maximum
	energy = 3
	ants += 10
	eff = 0

	%Utility.turn_resources()
	for s in %Structure.structures:
		%Utility.utilize(s.structure.resource.util_buffs, s.magic_number, -1)

	if allow_end_turn:
		%EndTurnButton.disabled = false

func start_day(deck: Array[CardResource.Card], initial_hand: Array[CardResource.Card] = []) -> void:
	energy = 3
	ants = 0
	eff = 0
	
	draw_pile = deck.duplicate()
	draw_pile.shuffle()
	
	for s in %Structure.structures:
		if s.structure.resource.structure_name == "TV":
			s.magic_number += 1

	start_turn(initial_hand)

func money_passthrough(value: int):
	money_earned.emit(value)

func on_card_reward(to_roll: int) -> void:
	var cards: Array[CardResource.Card] = []
	for card in to_roll:
		cards.append(AllCards.resources[
			rng.rand_weighted(
				AllCards.resources.map(func(c): return c.rarity)
			)
		].new())
		card_earned.emit(card)
	%CardReward.show_cards(cards)
	%CardReward.show()

func _process(delta: float) -> void:
	var structure_pos: Array[Vector3] = []
	for s in %Structure.structures:
		structure_pos.append(Vector3((s.global_position.x - %Camera.position.x) / 1080., (s.global_position.y - %Camera.position.y) / 1080., 1))
	%Camera/Visibility.material.set_shader_parameter("discoveries", structure_pos)
	%Camera/Visibility.material.set_shader_parameter("interactable_pos", Vector2(-1,-1))

func _on_discard_pile_mouse_entered() -> void:
	%CardPileDisplay.show_cards(discard_pile)
	%CardPileDisplay.show()

func _on_exhaust_pile_mouse_entered() -> void:
	%CardPileDisplay.show_cards(exhaust_pile)
	%CardPileDisplay.show()

func _on_draw_pile_mouse_entered() -> void:
	%CardPileDisplay.show_cards(draw_pile)
	%CardPileDisplay.show()

func _on_pile_mouse_exited() -> void:
	%CardPileDisplay.hide()

func isolate_hand_card(i: int) -> void:
	%PlayCards.isolate_card(i)

func new_turn_enabled(enabled: bool) -> void:
	allow_end_turn = enabled
	%EndTurnButton.disabled = not enabled

func _on_game_card_purchased(card: CardResource.Card) -> void:
	print("Purchased: ", card)
	discard_pile.append(card)
