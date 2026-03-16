extends Sprite2D
class_name Ant

var following_path: Array = []
var timer = 0

var grid_position: Vector2i:
	set(pos):
		self.position = (pos * 32) + Vector2i(16, 16)
	get():
		return Vector2i(self.position / 32)

var ground_direction: Vector2i = Vector2i(0, 1)

func move_to_tile(along_path: Array):
	following_path = along_path

func _process(delta: float) -> void:
	timer += delta
	
	if timer >= .2:
		timer = 0
		if len(following_path) > 0:
			var p = following_path.pop_at(0)

			grid_position = p[0]
			ground_direction = p[1]
			rotation = Vector2(p[1]).angle() - PI / 2
