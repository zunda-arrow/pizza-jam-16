extends Node

var resources: Array[CardResource] = [
	load("res://resources/cards/fungus_bar.tres"),
	load("res://resources/cards/breakfast.tres"),
	load("res://resources/cards/beam_drill.tres"),
	load("res://resources/cards/dirt_nap.tres"),
	load("res://resources/cards/super_drill.tres"),
	load("res://resources/cards/drill.tres"),
	load("res://resources/cards/big_drill.tres"),
	load("res://resources/cards/super_buff.tres"),
	load("res://resources/cards/bulldozer.tres"),
	load("res://resources/cards/brainstorm.tres"),
	load("res://resources/cards/bridge.tres"),
	load("res://resources/cards/ladder.tres"),
]

var cards = resources.map(func(card): return card.new())
