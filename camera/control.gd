extends Node2D

@export var speed := 1000.0
@export var camera_size := Vector2i(1920, 1080)

@onready var camera: Camera2D = $Camera2D

func _ready():
	if get_tree().root == get_parent():
		for child in get_children():
			if child.name.begins_with("_"):
				child.reparent.call_deferred(get_parent())
		return

	for child in get_children():
		if child.name.begins_with("_"):
			child.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var inp = Input.get_vector("left", "right", "up", "down")
	position += inp.normalized() * speed * delta
	# Sets discovery overlay shader. Not sure if this should go here
	%Terrain/Visibility.position = position - Vector2(1920. / 2., 1080. / 2.)
	var structure_pos: Array[Vector3] = []
	for s in %Structure.structures:
		structure_pos.append(Vector3((s.global_position.x - position.x) / 1080., (s.global_position.y - position.y) / 1080., 1))
	print(structure_pos)
	%Terrain/Visibility.material.set_shader_parameter("discoveries", structure_pos)

# Used for generating new terrain when it becomes visible
func get_bounding_area() -> Rect2:
	var size = camera_size / camera.zoom.x
	return Rect2(camera.global_position - size/2, size)
