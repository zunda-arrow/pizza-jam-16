@tool
extends Node2D

@export var money: int
@export var day: int
@export var daily_goal: int
@export var total_days: int = 20

@export var turn: int

@export var in_game: bool = false

@export var ant_count: int
@export var energy_count: int


func _process(delta: float) -> void:
	%Money.text = str(money) + "/" + str(daily_goal)
	%Day.text = "Day " + str(day) + "/" + str(total_days)
	%Turn.text = "Turn " + str(turn + 1) + "/5"

	if not in_game:
		%Energy.text = str(0)
		%Ants.text = str(0)
	else:
		%Energy.text = str(energy_count)
		%Ants.text = str(ant_count)
