extends Node2D

signal turn_start
signal day_start(deck: Array[CardResource.Card])
signal shop_start

var deck = []
var money := 0

func _ready() -> void:
	deck = AllCards.cards.duplicate()
	
	$ShopCamera.hide()
	%Shop.get_money = get_money
	
	start_game()

func start_game() -> void:
	day_start.emit(deck) # Day start also starts a turn.

func on_day_end() -> void:
	shop_start.emit()
	get_tree().paused = true

func on_money_earned(value: int) -> void:
	money += value

func get_money() -> int:
	return money

func on_card_purchased(card: CardResource) -> void:
	deck.append(card.new())

func shop_phase_done() -> void:
	$ShopCamera.hide()
	get_tree().paused = false
	turn_start.emit()
