class_name CardResource
extends Resource

@export var card_name: String
@export_multiline var description: String
@export_range(0, 100) var energy_cost: int
@export_range(0, 100) var ant_cost: int
@export var card_impl: Cards
@export var	structureResource: StructureResource
@export var dig_area: Array[Rect2i]
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
	var energy_cost: int
	var ant_cost: int
	var structure: StructureResource
	var dig_area: Array[Rect2i]
	
	func get_type() -> CardType:
		return CardType.Unset

	func get_area() -> Array[Rect2i]:
		return []

class Dig extends Card:
	func get_type() -> CardType:
		return CardType.Dig

	func get_area() -> Array[Rect2i]:
		return dig_area

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
	card.energy_cost = energy_cost
	card.ant_cost = ant_cost
	card.structure = structureResource
	card.dig_area = dig_area
	return card
