extends Node2D

var hand: Array[CardResource] = []
var deck: Array[CardResource] = []
var discard_pile: Array[CardResource] = []

func _ready():
	var cards: Array[CardResource.Card] = [
		load("res://resources/cards/dig.tres").new(),
		load("res://resources/cards/dig.tres").new(),
		load("res://resources/cards/dig.tres").new(),
		load("res://resources/cards/dig.tres").new(),
		load("res://resources/cards/dig.tres").new(),
	]
	for card in cards:
		%PlayCards.draw_card(card)

func _on_play_cards_card_used(card: CardResource.Card, at: Vector2) -> void:
	print("Using card: ", card, at)
	%Terrain.destroy(at, card.get_area())
	%Terrain.hide_selector()

func _on_play_cards_aiming_card(card: CardResource.Card, at: Vector2) -> void:
	%Terrain.show_selector(at, card.get_area())

func _on_play_cards_card_discarded(index: int) -> void:
	print("discraded", index)
