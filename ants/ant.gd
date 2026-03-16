extends Sprite2D
class_name Ant

var following_path: Array[Vector2i] = []
var timer = 0

var grid_position: Vector2i:
	set(pos):
		self.position = (pos * 32) + Vector2i(16, 16)
	get():
		return Vector2i(self.position / 32)

func move_to_tile(along_path: Array[Vector2i]):
	following_path = along_path

func _process(delta: float) -> void:
	timer += delta
	
	if timer >= .1:
		timer = 0
		if len(following_path) > 0:
			grid_position = following_path.pop_at(0)
