extends Node2D
class_name Game

signal turn_start
signal day_start(deck: Array[CardResource.Card])
signal shop_start

var deck: Array[CardResource.Card] = []
var money := 0

var day = 1

func calculate_daily_goal(day_number: int):
	return 10*day_number

func loop_music():
	$Music.play()
	await get_tree().create_timer(88.63).timeout
	loop_music()

func _ready() -> void:
	for c in AllCards.resources:
		deck.push_back(c.new())
	
	$ShopCamera.hide()
	%Shop.get_money = get_money
	
	loop_music()
	start_game()

func start_game() -> void:
	day_start.emit(deck) # Day start also starts a turn.
	
	%Toolbar.daily_goal = calculate_daily_goal(day)

func on_day_end() -> void:
	shop_start.emit()
	get_tree().paused = true
	day += 1
	%Toolbar.daily_goal = calculate_daily_goal(day)
	

func on_money_earned(value: int) -> void:
	money += value
	%Toolbar.money = money

func get_money() -> int:
	return money

func on_card_purchased(card: CardResource) -> void:
	deck.append(card.new())

func shop_phase_done() -> void:
	$ShopCamera.hide()
	get_tree().paused = false
	turn_start.emit()
