@tool
extends Node2D

@onready var PathFollower = $Path2D/CursorBall

var hovering = false
var followers = []
var time = 0

var end_position: Vector2
var start_position: Vector2

func set_start_position(pos: Vector2):
	start_position = pos

func set_end_position(pos: Vector2):
	end_position = pos

func _ready() -> void:
	$Path2D.position = Vector2(0, 0)
	start_position = Vector2(0, 0)
	end_position = Vector2(100, 100)

func _process(delta: float) -> void:
	time += delta * 50
	if hovering:
		time += delta * 300

	$Path2D.curve.clear_points()
	$Path2D.curve.add_point(start_position)
	$Path2D.curve.add_point(end_position)

	for f in followers:
		f.queue_free()
	followers = []

	var length = $Path2D.curve.get_baked_length()

	var sample_a = $Path2D.curve.sample_baked(length * 0.999, true)
	var sample_b = $Path2D.curve.sample_baked(length, true)
	var theta = atan((sample_a.y - sample_b.y) / (sample_a.x - sample_b.x))
	
	if (end_position.x <= 0): theta += PI

	$Path2D/Head.progress_ratio = 1
	$Path2D/Head.rotation = theta

	var n = 0
	while n < length:
		n += 30
		var follower = PathFollower.duplicate()
		follower.visible = true
		follower.progress = n + (int(time) % 30)
		$Path2D.add_child(follower)
		followers.push_back(follower)
