class_name CardResource
extends Resource

@export var card_name: String
@export_multiline var description: String
@export var card_impl: Cards

enum CardType {
	Unset,
	Dig,
	Move,
	Build,
	Power,
}

enum Cards {
	Default,
	Dig,
	Move,
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

class Move extends Card:
	func get_type() -> CardType:
		return CardType.Move

var all_cards = {
	Cards.Default: Card,
	Cards.Dig: Dig,
	Cards.Move: Move,
}

func new() -> Card:
	var card = all_cards[card_impl].new()
	card.card_name = card_name
	card.description = description
	return card
