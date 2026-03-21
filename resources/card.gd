class_name CardResource
extends Resource

@export var card_name: String
@export_multiline var description: String
@export var image: Texture2D
@export_range(-100, 100) var energy_cost: int
@export_range(-100, 100) var ant_cost: int
@export var card_impl: Cards
@export var	structureResource: StructureResource
@export var dig_area: Array[Rect2i]
@export_range(-1,10) var dig_power: int
@export var utility: UtilityResource

@export var cost := 0
@export var rarity := 1.0


enum CardType {
	Unset,
	Dig,
	Move,
	Build,
	Utility,
}

enum Cards {
	Default,
	Dig,
	Move,
	Build,
	Utility
}

class Card extends Node:
	var card_name: String
	var description: String
	var image: Texture2D
	var energy_cost: int
	var ant_cost: int
	var structure: StructureResource
	var dig_area: Array[Rect2i]
	var dig_power: int
	var utility: UtilityResource
	
	func get_type() -> CardType:
		return CardType.Unset

	func get_area() -> Array[Rect2i]:
		return []
	
	func should_exhaust() -> bool:
		return false

class Dig extends Card:
	func get_type() -> CardType:
		return CardType.Dig

	func get_area() -> Array[Rect2i]:
		return dig_area
	
	func power() -> int:
		return dig_power

class Move extends Card:
	func get_type() -> CardType:
		return CardType.Move
		
class Build extends Card:
	func get_type() -> CardType:
		return CardType.Build
		
	func get_area() -> Array[Rect2i]:
		return structure.size
	
	func should_exhaust() -> bool:
		return true
		
class Utility extends Card:
	func get_type() -> CardType:
		return CardType.Utility

var all_cards = {
	Cards.Default: Card,
	Cards.Dig: Dig,
	Cards.Move: Move,
	Cards.Build: Build,
	Cards.Utility: Utility
}

func new() -> Card:
	var card = all_cards[card_impl].new()
	card.card_name = card_name
	card.description = description
	card.energy_cost = energy_cost
	card.ant_cost = ant_cost
	card.structure = structureResource
	card.dig_area = dig_area
	card.dig_power = dig_power
	card.utility = utility
	card.image = image
	return card
