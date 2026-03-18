extends Node2D

signal card_used(card: CardResource, position: Vector2, index: int)
signal aiming_card(card: CardResource, position: Vector2, index: int)
signal cancel_aiming_card()

@export var cards_in_hand: Array[CardResource]

@onready var hand = %Hand
@onready var target_arrow = %TargetArrow

# Playing cards works in two steps. The player drags the card and picks a target.
# If cards do not have a target, you still drag them to the play area like slay the spire.

var _targetting_card_index = -1

func _on_hand_card_clicked(i: int) -> void:
	_targetting_card_index = i
	
func show_target_arrow(i: int):
	var start_pos = hand.position_card(i)
	target_arrow.set_start_position(start_pos)
	target_arrow.show()

func _process(delta: float) -> void:
	target_arrow.set_end_position(target_arrow.get_local_mouse_position())

	hand.selected_card_index = -1
	
	if _targetting_card_index == -1:
		for i in range(len(hand.card_scenes)):
			if hand.card_scenes[i].hovered:
				hand.selected_card_index = i
	else:
		hand.selected_card_index = _targetting_card_index

	if _targetting_card_index != -1:
		var resource = hand.card_scenes[_targetting_card_index].instantiated_card_resource
		var pos = get_global_mouse_position() / 32
		aiming_card.emit(resource, Vector2i(int(pos.x), int(pos.y)), _targetting_card_index)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		# The right mouse button can be used to cancel an action
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_targetting_card_index = -1
			target_arrow.hide()
			cancel_aiming_card.emit()
	if event is InputEventMouseButton and event.is_released():
		if event.button_index == MOUSE_BUTTON_LEFT:
			if _targetting_card_index == -1:
				return
			try_to_play_card(_targetting_card_index)
			_targetting_card_index = -1
			target_arrow.hide()

func try_to_play_card(i: int):
	# This function should be expanded to properly check targets
	var resource = hand.card_scenes[i].instantiated_card_resource
	var pos = get_global_mouse_position() / 32

	card_used.emit(resource, Vector2i(int(pos.x), int(pos.y)), i)
	_targetting_card_index = -1

func discard_card(i: int):
	hand.remove_card_from_hand(i)

func draw_card(card: CardResource.Card):
	hand.add_card_to_hand(card)

func _on_hand_card_discarded(i: int) -> void:
	# I dont think we want discarding actually
	return
	_targetting_card_index = -1
	
