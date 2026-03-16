extends Node2D

var hand: Array[CardResource.Card] = []
var deck: Array[CardResource.Card] = []
var draw_pile: Array[CardResource.Card] = []
var discard_pile: Array[CardResource.Card] = []

func _ready():
	var cards: Array[CardResource.Card] = [
		load("res://resources/cards/dig.tres").new(),
		load("res://resources/cards/dig.tres").new(),
		load("res://resources/cards/dig.tres").new(),
		load("res://resources/cards/dig.tres").new(),
		load("res://resources/cards/dig.tres").new(),
		load("res://resources/cards/dig.tres").new(),
		load("res://resources/cards/dig.tres").new(),
		load("res://resources/cards/dig.tres").new(),
		load("res://resources/cards/dig.tres").new(),
		load("res://resources/cards/dig.tres").new(),
		]
	deck.append_array(cards)
	draw_pile.append_array(cards)
	draw(5)
		
func draw(n: int): # TODO: Handle empty draw pile.
	for i in range(n):
		var card = draw_pile.pop_back()
		hand.append(card)
		%PlayCards.draw_card(card)

func _on_play_cards_card_used(card: CardResource.Card, at: Vector2) -> void:
	print("Using card: ", card, at)
	%Terrain.destroy(at, card.get_area())
	%Terrain.hide_selector()

func _on_play_cards_aiming_card(card: CardResource.Card, at: Vector2) -> void:
	%Terrain.show_selector(at, card.get_area())

func _on_play_cards_card_discarded(index: int) -> void:
	print(hand)
	discard_pile.append(hand[index])
	print("discarded", index)
	print(discard_pile)
