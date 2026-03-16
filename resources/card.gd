class_name CardResource
extends Resource

@export var card_name: String
@export_multiline var description: String
@export var card_impl: Cards
@export var	structureResource: StructureResource
@export var digArea: Array[Rect2i]
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
	Build
}

class Card extends Node:
	var card_name: String
	var description: String
	var structure: StructureResource
	var digArea: Array[Rect2i]
	
	func get_type() -> CardType:
		return CardType.Unset

	func get_area() -> Array[Rect2i]:
		return []

class Dig extends Card:
	func get_type() -> CardType:
		return CardType.Dig

	func get_area() -> Array[Rect2i]:
		return digArea

class Move extends Card:
	func get_type() -> CardType:
		return CardType.Move
		
class Build extends Card:
	func get_type() -> CardType:
		return CardType.Build
		
	func get_area() -> Array[Rect2i]:
		return structure.size

var all_cards = {
	Cards.Default: Card,
	Cards.Dig: Dig,
	Cards.Move: Move,
	Cards.Build: Build,
}

func new() -> Card:
	var card = all_cards[card_impl].new()
	card.card_name = card_name
	card.description = description
	card.structure = structureResource
	card.digArea = digArea
	return card
