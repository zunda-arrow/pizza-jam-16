@tool

extends Node2D

var _card_scene = preload("res://cards/Card.tscn")

var cards = []
var card_scenes = []

signal card_clicked(i: int)

@export var radius = 2000
@export var distance_between_cards = 200
@export var animation_speed = 30

var selected_card_index = -1

func _ready():
	for i in range(6):
		var next_card = _card_scene.instantiate()
		card_scenes.push_back(next_card)
		%Cards.add_child(next_card)
		
		next_card.on_clicked.connect(func ():
			card_clicked.emit(i)
		)

	positon_cards(-1)

func _process(delta: float) -> void:
	positon_cards(delta)

func positon_cards(delta):
	for i in range(len(card_scenes)):
		var card = card_scenes[i]

		var pos = position_card(i)
		var lerp_amount = animation_speed * delta
		if delta == -1:
			lerp_amount = 1

		card.position.x = lerp(card.position.x, float(pos.x), lerp_amount)
		card.position.y = lerp(card.position.y, float(pos.y), lerp_amount)
		card.rotation = lerp(card.rotation, float(rotate_card(i)), lerp_amount)
		card.scale = lerp(card.scale, scale_card(i), lerp_amount)

func position_card(i: int):
	var distance_from_center = len(card_scenes) / 2. - i - 0.5

	var y_position = distance_from_center * distance_between_cards
	# x^2 + y^2 = r^2
	# x^2 = r^2 - y^2
	# x = sqrt(r^2 - y^2)
	var x_position = sqrt(radius ** 2 - y_position ** 2) - radius

	if selected_card_index == i:
		x_position = 50

	if selected_card_index != -1:
		if selected_card_index < i:
			y_position -= 50
		if selected_card_index > i:
			y_position += 50

	return Vector2(x_position, y_position)

func rotate_card(i: int):
	var pos = position_card(i)

	if selected_card_index == i:
		return 0

	if pos.x != 0:
		return -tan(pos.x / pos.y)

	return 0

func scale_card(i: int):
	if selected_card_index == i:
		return Vector2(1.5, 1.5)
	return Vector2(1, 1)
