extends AnimatedSprite2D
class_name Ant

@export var TIME_BETWEEN_PATH_FINDING_SECONDS = .5
var following_path: Array = []
var timer = 0
var facing = "right"
var going_home = false
var _current_rotation = 0

var sleeping: bool:
	set(val):
		sleeping = val
		if val:
			if randf() < 0.01:
				play("nap-cap")
			play("nap")
		else:
			play("walk")
	get():
		return sleeping

func _ready() -> void:
	play("walk")

var grid_position: Vector2i
var ground_direction: Vector2i = Vector2i(0, 1)
var thinking_time = 0

func move_to_tile(along_path: Array, facing_: String):
	following_path = along_path
	facing = facing_ 

func is_thinking():
	return thinking_time < TIME_BETWEEN_PATH_FINDING_SECONDS

func _process(delta: float) -> void:
	timer += delta
	
	thinking_time += delta
	
	if facing == "left":
		flip_h = true
	else:
		flip_h = false

	if len(following_path) == 0 and animation == "walk":
		pause()
		if going_home:
			queue_free()
	else:
		play()

	if sleeping:
			position.x = grid_position.x * 32 + 16
			position.y = grid_position.y * 32 + 16
			rotation = Vector2(ground_direction).angle() - PI / 2 + 2 * PI
			return

	if len(following_path) > 0:
		thinking_time = 0
		var target = following_path[0][0]
		var r = following_path[0][1]

		if grid_position.x == target.x and grid_position.y == target.y:
			# Inner corner
			var target_angle = Vector2(r).angle() - PI / 2 + 2 * PI
			rotation = lerp_angle(float(_current_rotation), target_angle, timer / .2)
			position.x = grid_position.x * 32 + 16
			position.y = grid_position.y * 32 + 16
		elif grid_position.x == target.x or grid_position.y == target.y:
			position.x = lerp(grid_position.x, target.x, timer / .2) * 32 + 16
			position.y = lerp(grid_position.y, target.y, timer / .2) * 32 + 16
		else:
			# This must be an outer corner
			var target_angle = Vector2(r).angle() - PI / 2
			rotation = lerp_angle(float(_current_rotation), target_angle, timer / .2)
			position.x = lerp(grid_position.x, target.x, timer / .2) * 32 + 16
			position.y = lerp(grid_position.y, target.y, timer / .2) * 32 + 16

		if timer >= .2:
			timer = 0
			if len(following_path) > 0:
				var p = following_path.pop_at(0)
				grid_position = p[0]
				ground_direction = p[1]
				_current_rotation = Vector2(p[1]).angle() - PI / 2 + 2 * PI
				rotation = _current_rotation
