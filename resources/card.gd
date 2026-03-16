class_name CardResource
extends Resource

@export var card_name: String
@export_multiline var description: String
@export_range(0, 100) var enegry_cost: int
@export_range(0, 100) var ant_cost: int
@export var card_impl: Cards
@export var structureResource: StructureResource

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
	var energy_cost: int
	var ant_cost: int
	var description: String
	var structure: StructureResource
	
	func get_type() -> CardType:
		return CardType.Unset

	func get_area() -> Array[Rect2i]:
		return []

class Dig extends Card:
	func get_type() -> CardType:
		return CardType.Dig

	func get_area() -> Array[Rect2i]:
		return [Rect2(-1, -1, 3, 3)]

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
	card.energy_cost = enegry_cost
	card.ant_cost = ant_cost
	card.structure = structureResource
	return card
