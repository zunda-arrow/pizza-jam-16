extends AnimatedSprite2D
class_name Ant

var following_path: Array = []
var timer = 0
var facing = "right"
var _current_rotation = 0

func _ready() -> void:
	play("walk")

var grid_position: Vector2i
var ground_direction: Vector2i = Vector2i(0, 1)

func move_to_tile(along_path: Array, facing_: String):
	following_path = along_path
	facing = facing_ 

func _process(delta: float) -> void:
	timer += delta
	
	if facing == "left":
		flip_h = true
	else:
		flip_h = false

	if len(following_path) > 0:
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
