@tool

extends Node2D

var _card_scene = preload("res://cards/Card.tscn")

var cards = []
var card_scenes = []

signal card_clicked(i: int)

@export var radius = 2000
@export var distance_between_cards = 200
@export var animation_speed = 30

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
	var selected_card_index = -1
	
	for i in range(len(card_scenes)):
		if card_scenes[i].hovered:
			selected_card_index = i

	for i in range(len(card_scenes)):
		var card: Node2D = card_scenes[i]
		var distance_from_center = len(card_scenes) / 2. - i - 0.5

		var x_positon = -distance_from_center * distance_between_cards
		# x^2 + y^2 = r^2
		# y^2 = r^2 - x^2
		# y = sqrt(r^2 - x^2)
		var y_position = radius - sqrt(radius ** 2 - x_positon ** 2)
		var target_rotation = 0.
		if x_positon != 0:
			target_rotation = tan(y_position / x_positon)
		
		var target_scale = Vector2(1, 1)

		if selected_card_index == i:
			target_scale = Vector2(1.5, 1.5)
			target_rotation = 0
			y_position = 0

		if selected_card_index != -1:
			if selected_card_index < i:
				x_positon += 50
			if selected_card_index > i:
				x_positon -= 50

		var lerp_amount = animation_speed * delta
		if delta == -1:
			lerp_amount = 1

		card.position.x = lerp(card.position.x, float(x_positon), lerp_amount)
		card.position.y = lerp(card.position.y, float(y_position), lerp_amount)
		card.rotation = lerp(card.rotation, float(target_rotation), lerp_amount)
		card.scale = lerp(card.scale, target_scale, lerp_amount)	
