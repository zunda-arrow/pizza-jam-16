extends Node2D

var hand: Array[CardResource.Card] = []
var deck: Array[CardResource.Card] = []
var draw_pile: Array[CardResource.Card] = []
var discard_pile: Array[CardResource.Card] = []

var player_position: Vector2i:
	set(pos):
		%Player.position = pos * 32
	get():
		return %Player.position / 32


func _ready():
	%Terrain.region = %Camera
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
		load("res://resources/cards/dig.tres").new(),
		load("res://resources/cards/fungus_bar.tres").new(),
		]
	deck.append_array(cards)
	draw_pile.append_array(cards)
	draw_pile.shuffle()
	draw(5)

func _on_terrain_update():
	%Army.is_grid_cell_filled = _is_cell_filled
	%Army.spawn_position = Vector2(3, -1)
	%Army.spawn_ground_direction = Vector2(0, 1)
	%Army.generate_loop()
	%Army.spawn_ants()

	for structure in %Terrain.structures:
		var cells = structure.get_tiles()

		for c in cells:
			# We use Vector2i(0, 1) because structures can only be placed
			# vertically right now.
			# In the future this should be the direction of the floor.
			if %Army.is_cell_on_loop(c, Vector2i(0, 1)):
				structure.set_connected_to_loop(true)
				break


func draw(n: int): # TODO: Handle empty draw pile.
	for i in range(n):
		var card = draw_pile.pop_back()
		hand.append(card)
		%PlayCards.draw_card(card)

func _is_cell_filled(pos: Vector2i):
	return %Terrain.tilemap.get_cell_tile_data(pos) != null

func _on_play_cards_card_used(card: CardResource.Card, at: Vector2) -> void:
	print("Using card: ", card, at)

	if card.get_type() == CardResource.CardType.Dig:
		%Terrain.destroy(at, card.get_area())
	if card.get_type() == CardResource.CardType.Move:
		player_position = at
	if card.get_type() == CardResource.CardType.Build:
		%Terrain.place_build(at, card.structure)

	%Terrain.hide_selector()
	_on_terrain_update()

func _on_play_cards_aiming_card(card: CardResource.Card, at: Vector2) -> void:
	if card.get_type() == CardResource.CardType.Dig:
		%Terrain.show_selector(at, card.get_area(), %Terrain.PlacingMethod.Dig)
	if card.get_type() == CardResource.CardType.Build:
		%Terrain.show_selector(at, card.get_area(), %Terrain.PlacingMethod.Build)

func _on_play_cards_card_discarded(index: int) -> void:
	print(hand)
	discard_pile.append(hand[index])
	print("discarded", index)
	print(discard_pile)
