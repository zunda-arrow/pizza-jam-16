extends Node2D

signal turn_start
signal day_start(deck: Array[CardResource.Card])

var deck = []
var money := 0

func _ready() -> void:
	deck = AllCards.cards.duplicate()
	
	$ShopCamera.hide()
	%Shop.get_money = get_money

func start_game() -> void:
	day_start.emit(deck)
	turn_start.emit()

func on_turn_end() -> void:
	$ShopCamera.make_active()

func on_money_earned(value: int) -> void:
	money += value

func get_money() -> int:
	return money

func on_card_purchased(card: CardResource) -> void:
	deck.append(card.new())

func shop_phase_done() -> void:
	$ShopCamera.hide()
	turn_start.emit()
