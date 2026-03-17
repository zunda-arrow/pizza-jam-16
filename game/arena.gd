extends Node2D

var HAND_SIZE = 6

var hand: Array[CardResource.Card] = []
var deck: Array[CardResource.Card] = []
var draw_pile: Array[CardResource.Card] = []
var discard_pile: Array[CardResource.Card] = []

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
	get():
		return _ants

var player_position: Vector2i:
	set(pos):
		%Player.position = pos * 32
	get():
		return %Player.position / 32


func _ready():
	%Terrain.region = %Camera
	%Terrain.occupation_checks.append(%Structure.building_occupation)
	%Structure.occupation_checker = %Terrain.get_occupied_cells
	%Structure.has_terrain = _is_cell_filled
	_on_terrain_update()

	var cards: Array[CardResource.Card] = [
		load("res://resources/cards/fungus_bar.tres").new(),
		load("res://resources/cards/fungus_bar.tres").new(),
		load("res://resources/cards/fungus_bar.tres").new(),
		load("res://resources/cards/fungus_bar.tres").new(),
		load("res://resources/cards/scoop.tres").new(),
		load("res://resources/cards/dig.tres").new(),
		load("res://resources/cards/quarry.tres").new(),
		load("res://resources/cards/excavate.tres").new(),
		load("res://resources/cards/bulldoze.tres").new(),
		]

	deck.append_array(cards)
	draw_pile.append_array(cards)
	draw_pile.shuffle()
	draw()
	
	energy = 9
	ants = 10

func _on_terrain_update():
	%Army.is_grid_cell_filled = _is_cell_filled
	%Army.spawn_position = Vector2(3, -1)
	%Army.spawn_ground_direction = Vector2(0, 1)
	%Army.generate_loop()
	%Army.spawn_ants()

	for structure in %Structure.structures:
		var cells = structure.get_tiles()

		for c in cells:
			# We use Vector2i(0, 1) because structures can only be placed
			# vertically right now.
			# In the future this should be the direction of the floor.
			if %Army.is_cell_on_loop(c, Vector2i(0, 1)):
				structure.set_connected_to_loop(true)
				break


func draw():
	for i in range(HAND_SIZE):
		if len(draw_pile) == 0:
			# When the draw pile is empty, we put the discard pile back
			# into the draw pile.
			draw_pile = discard_pile
			discard_pile = []
		var card = draw_pile.pop_at(randi() % len(draw_pile))
		hand.append(card)
		%PlayCards.draw_card(card)

func discard(i: int):
	%PlayCards.discard_card(i)
	discard_pile.append(hand[i])
	hand.pop_at(i)
	

func _is_cell_filled(pos: Vector2i):
	return %Terrain.tilemap.get_cell_tile_data(pos) != null

func _on_play_cards_card_used(card: CardResource.Card, at: Vector2, index: int) -> void:
	var success = false
	print("Using card: ", card, at)
	if (card.energy_cost > energy or card.ant_cost > ants):
		print("Card Too Expensive")
		return
		
	if card.get_type() == CardResource.CardType.Dig:
		%Terrain.destroy(at, card.get_area())
		success = true
	if card.get_type() == CardResource.CardType.Move:
		player_position = at
		success = true
	if card.get_type() == CardResource.CardType.Build:
		success = %Structure.place_build(%Terrain.tilemap.map_to_local(at), at, card.structure)

	%Terrain.hide_selector()
	_on_terrain_update()
	
	if (success):
		energy -= card.energy_cost
		ants -= card.ant_cost
		discard(index)

func _on_play_cards_aiming_card(card: CardResource.Card, at: Vector2) -> void:
	if card.get_type() == CardResource.CardType.Dig:
		%Terrain.show_selector(at, card.get_area(), %Terrain.PlacingMethod.Dig)
	if card.get_type() == CardResource.CardType.Build:
		%Terrain.show_selector(at, card.get_area(), %Terrain.PlacingMethod.Build)
		

func _on_end_turn_button_button_down() -> void:
	# At the end of the turn, we want to draw cards

	%EndTurnButton.disabled = true

	while len(hand) > 0:
		discard(0)
		# Give a litte animation
		await get_tree().create_timer(.05).timeout

	draw()

	# Reset energy to maximum
	energy = 9
	ants = 10

	%EndTurnButton.disabled = false
