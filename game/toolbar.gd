@tool
extends Node2D

@export var money: int
@export var day: int
@export var daily_goal: int
@export var total_days: int = 20


func _process(delta: float) -> void:
	%Money.text = str(money) + "/" + str(daily_goal)
	%Day.text = str(day) + "/" + str(total_days)
