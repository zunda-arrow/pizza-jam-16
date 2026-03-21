extends Node2D


func set_cards(cards) -> void:
	$Card.instantiated_card_resource = cards[0]

func on_button_pressed() -> void:
	hide()
