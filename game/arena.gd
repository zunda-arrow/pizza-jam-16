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

var eff: int

var player_position: Vector2i:
	set(pos):
		%Player.position = pos * 32
	get():
		return %Player.position / 32

var visible_region :
	set(value):
		%Terrain.region = value

func _ready():
	%Terrain.occupation_checks.append(%Structure.building_occupation)
	%Structure.occupation_checker = %Terrain.get_occupied_cells
	%Structure.has_terrain = _is_cell_filled
	_on_terrain_update()
	%Army.number_of_ants = 10
	%Army.spawn_ants()
	
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

func _on_play_cards_card_used(card: CardResource.Card, at: Vector2, index: int) -> void:
	var success = false
	var x = 0
	print("Using card: ", card, at)
	if card.energy_cost > energy or card.ant_cost > ants:
		print("Card Too Expensive")
		return
	
	if card.energy_cost < 0:
		x += energy
		energy = -1
	elif card.ant_cost < 0:
		x += ants / 10
		ants = -1
		
	if card.get_type() == CardResource.CardType.Dig:
		success = %Terrain.destroy(at, card.get_area(), card.power() + eff, x)
	if card.get_type() == CardResource.CardType.Move:
		player_position = at
		success = true
	if card.get_type() == CardResource.CardType.Build:
		success = %Structure.place_build(%Terrain.tilemap.map_to_local(at), at, card.structure.new())
	if card.get_type() == CardResource.CardType.Utility:
		success = %Utility.utilize(card.utility, x)

	%Terrain.hide_selector()
	_on_terrain_update()
	
	if (success):
		energy -= card.energy_cost
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
		%Terrain.show_selector(at, card.get_area(), %Terrain.PlacingMethod.Build)

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
