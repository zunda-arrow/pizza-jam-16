extends Node2D

var hand: Array[CardResource] = []
var deck: Array[CardResource] = []
var discard_pile: Array[CardResource] = []

func _ready():
	var cards: Array[CardResource] = [
		load("res://resources/cards/dig.tres"),
		load("res://resources/cards/dig.tres"),
		load("res://resources/cards/dig.tres"),
		load("res://resources/cards/dig.tres"),
		load("res://resources/cards/dig.tres"),
	]
	for card in cards:
		%PlayCards.draw_card(card)

func _on_play_cards_card_used(card: CardResource, position: Vector2) -> void:
	print("Using card: ", card, position)

	%Terrain.destroy(position, 3)
	%Terrain.hide_selector()

func _on_play_cards_aiming_card(card: CardResource, position: Vector2) -> void:
	var target: Array[Rect2i] = [Rect2i(0, 0, 1, 1)]
	%Terrain.show_selector(position, target)


func _on_play_cards_card_discarded(index: int) -> void:
	print("discraded", index)
