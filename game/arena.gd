extends Node2D

func _ready() -> void:
	pass


func _on_play_cards_card_used(card: CardResource, position: Vector2) -> void:
	print("Using card: ", card, position)

	%Terrain.destroy(position, 3)
	%Terrain.hide_selector()

func _on_play_cards_aiming_card(card: CardResource, position: Vector2) -> void:
	var target: Array[Rect2i] = [Rect2i(0, 0, 1, 1)]
	%Terrain.show_selector(position, target)
