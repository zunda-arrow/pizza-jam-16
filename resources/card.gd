class_name CardResource
extends Resource

@export var card_name: String
@export var behavior: Behavior

enum Behavior {
	Default,
	Dig,
}

class Card extends Node:
	var card_name: String
	var behavior: DefaultCard

class DefaultCard:
	pass

class Dig extends DefaultCard:
	pass

var all_behaviors = {
	Behavior.Default: DefaultCard,
	Behavior.Dig: Dig,
}

func new() -> Card:
	var card = Card.new()
	card.card_name = card_name
	card.behavior = all_behaviors[behavior].new()
	return card
