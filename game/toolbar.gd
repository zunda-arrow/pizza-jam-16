@tool
extends Node2D

@export var money: int:
	set(val):
		money = val
		update_toolbar()
	get():
		return money
	
@export var rerolls: int:
	set(val):
		rerolls = val
		update_toolbar()
	get():
		return rerolls

@export var day: int:
	set(val):
		day = val
		update_toolbar()
	get():
		return day
	
@export var daily_goal: int:
	set(val):
		daily_goal = val
		update_toolbar()
	get():
		return daily_goal
	
@export var total_days: int = 20

@export var turn: int

@export var in_game: bool:
	set(val):
		in_game = val
		update_toolbar()
	get():
		return in_game


@export var ant_count: int
@export var energy_count: int

func _ready() -> void:
	in_game = false


func _process(delta: float) -> void:
	update_toolbar()

func update_toolbar():
	%Turn.text = "Turn " + str(turn + 1) + "/4"
	%Money.text = str(money) + "/" + str(daily_goal)
	%Rerolls.text = "Rerolls: " + str(rerolls)
	%Day.text = "Day " + str(day) + "/" + str(total_days)

	if not in_game:
		%Energy.text = str(0)
		%Ants.text = str(0)
	else:
		%Energy.text = str(energy_count)
		%Ants.text = str(ant_count)

	# I am sorry. This was the quickest way to fix the issue with the toolbar not following the camera.
	%Toolbar.position = $"../Arena/Camera".position - Vector2(960, 540)
