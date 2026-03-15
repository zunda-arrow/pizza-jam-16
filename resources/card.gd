class_name CardResource
extends Resource

@export var card_name: String
@export_multiline var description: String
@export var card_impl: Cards

enum CardType {
	Unset,
	Dig,
	Build,
	Power,
}

enum Cards {
	Default,
	Dig,
}

class Card extends Node:
	var card_name: String
	var description: String

	func get_type() -> CardType:
		return CardType.Unset

	func get_area() -> Array[Rect2i]:
		return []

class Dig extends Card:
	func get_type() -> CardType:
		return CardType.Dig

	func get_area() -> Array[Rect2i]:
		return [Rect2(-2, -2, 5, 5)]

var all_cards = {
	Cards.Default: Card,
	Cards.Dig: Dig,
}

func new() -> Card:
	var card = all_cards[card_impl].new()
	card.card_name = card_name
	card.description = description
	return card
