@tool
extends Node2D

signal on_mouse_entered
signal on_mouse_exited
signal on_clicked
signal on_right_clicked

@export var card_resource: CardResource
# The card object that should be displayed with this card resource.
var _instantiated_card_resource
var instantiated_card_resource: CardResource.Card:
	set(card):
		_instantiated_card_resource = card
		%CardName.text = card.card_name
		%CardDescription.text = card.description
		%Energy.text = string(card.energy_cost)
		%Ants.text = string(card.ant_cost / 10)
		%CardImage.texture = card.image
	get():
		return _instantiated_card_resource

var hovered = false

func string(n: int) -> String:
	if n < -1:
		return str(n) + "X"
	elif n < 0:
		return "X"
	return str(n)

func _ready() -> void:
	if card_resource != null:
		instantiated_card_resource = card_resource.new()

func _on_texture_mouse_entered() -> void:
	hovered = true
	on_mouse_entered.emit()

func _on_texture_mouse_exited() -> void:
	hovered = false
	on_mouse_exited.emit()


func _on_texture_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			on_clicked.emit()
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			on_right_clicked.emit()
