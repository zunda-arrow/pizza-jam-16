extends Node2D

var hand: Array[CardResource] = []
var deck: Array[CardResource] = []
var discard_pile: Array[CardResource] = []

var player_position: Vector2i:
	set(pos):
		%Player.position = pos * 32
	get():
		return %Player.position / 32


func _ready():
	%Terrain.region = %Camera

	var cards: Array[CardResource.Card] = [
		load("res://resources/cards/dig.tres").new(),
		load("res://resources/cards/dig.tres").new(),
		load("res://resources/cards/dig.tres").new(),
		load("res://resources/cards/move.tres").new(),
		load("res://resources/cards/move.tres").new(),
	]
	for card in cards:
		%PlayCards.draw_card(card)

func _on_play_cards_card_used(card: CardResource.Card, at: Vector2) -> void:
	print("Using card: ", card, at)
	
	if card.get_type() == CardResource.CardType.Dig:
		%Terrain.destroy(at, card.get_area())
	if card.get_type() == CardResource.CardType.Move:
		player_position = at

	%Terrain.hide_selector()

func _on_play_cards_aiming_card(card: CardResource.Card, at: Vector2) -> void:
	%Terrain.show_selector(at, card.get_area())

func _on_play_cards_card_discarded(index: int) -> void:
	print("discraded", index)
