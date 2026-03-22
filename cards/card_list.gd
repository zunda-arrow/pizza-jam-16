extends Node2D

var cardScene = preload("res://cards/Card.tscn")

@export var start_pos := Vector2(500, 200)
@export var gap := Vector2(325, 225)

var get_money := func(): return 1

@onready var rng = RandomNumberGenerator.new()

func show_cards(cards: Array[CardResource.Card]) -> void:
	for child in %CardContainer.get_children():
		child.queue_free()
	var current_pos = start_pos
	for card in cards:
		var new_card = cardScene.instantiate()
		new_card.position = current_pos
		new_card.instantiated_card_resource = card
		%CardContainer.add_child(new_card)
		if current_pos.x > 2500:
			current_pos.x = start_pos.x
			current_pos.y += gap.y
		else:
			current_pos.x += gap.x
