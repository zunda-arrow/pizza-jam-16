extends Node2D


func _ready():
	hide()

func show_cards(cards: Array[CardResource.Card]) -> void:
	show()
	$CardList.show_cards(cards)

func on_respond() -> void:
	hide()
