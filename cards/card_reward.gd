extends Node2D


func _ready():
	hide()

func show_cards(cards: Array[CardResource.Card]) -> void:
	$Panel.hide()
	hide()
	await get_tree().create_timer(2.0).timeout
	show()
	$Panel.show()
	$CardList.show_cards(cards)

func on_respond() -> void:
	hide()
