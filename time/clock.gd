extends Node2D

signal day_end(day: int)
signal day_tick(tick: int)

@export var day_length := 3

var day := 0
var tick := 0.0 : 
	set(value):
		tick = value
		%ClockSprite.rotation_degrees = 360 * (tick / day_length)

func advance_time() -> void:
	tick += 1
	if tick > day_length - 1: # Overtime detection would go here
		set_time(0, day + 1)
		day_end.emit(day)
	else:
		day_tick.emit(tick)

func set_time(new_tick, new_day = -1) -> void:
	if new_day >= 0:
		day = new_day
	tick = new_tick
