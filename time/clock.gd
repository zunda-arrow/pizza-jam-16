extends Node2D

signal day_end
signal day_tick

@export var day_length := 8

var day := 0
var tick := 0.0 : 
	set(value):
		tick = value
		%ClockSprite.rotation_degrees = 360 * (tick / day_length)

func advance_time() -> void:
	tick += 1
	if tick > day_length - 1: # Overtime detection would go here
		day_end.emit()
		set_time(0, day + 1)
	else:
		day_tick.emit(tick)

func set_time(new_tick, new_day = -1) -> void:
	if new_day >= 0:
		day = new_day
	tick = new_tick

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_down"):
		advance_time()
