extends Node2D
class_name Game

signal turn_start
signal day_start(deck: Array[CardResource.Card])
signal shop_start

signal game_won
signal game_over

@export var number_of_days = 20

var deck: Array[CardResource.Card] = []
var money: int:
	set(val):
		money = val
		%Toolbar.money = money
	get():
		return money

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
	%Toolbar.in_game = true

func on_day_end() -> void:
	if day >= number_of_days:
		game_won.emit()
		%GameWon.show()
		return
	
	if money > calculate_daily_goal(day):
		money -= calculate_daily_goal(day)
	else:
		game_over.emit()
		%GameOver.show()
		return

	shop_start.emit()
	day += 1
	%Toolbar.daily_goal = calculate_daily_goal(day)
	%Toolbar.in_game = false
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
	%Toolbar.in_game = true
	turn_start.emit()


func _on_arena_ant_count_changed(ant_count: int) -> void:
	%Toolbar.ant_count = ant_count


func _on_arena_energy_count_changed(energy: int) -> void:
	%Toolbar.energy_count = energy


func _on_arena_on_turn_changed(n: int) -> void:
	%Toolbar.turn = n


func _on_shop_charge_account(value: int) -> void:
	money -= value


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/menu.tscn")
