extends Node2D

@export var speed := 1000.0
@export var camera_size := Vector2i(1920, 1080)

@onready var camera: Camera2D = $Camera2D

var _time = 0
var going_home = false

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
	_time += delta
	
	var inp = Input.get_vector("left", "right", "up", "down")
	
	if going_home:
		global_position = lerp(global_position, Vector2(0,0), _time * 0.4)
		if global_position == Vector2(0,0) or inp.length() > 0.1:
			going_home = false
				
	position += inp.normalized() * speed * delta

# Used for generating new terrain when it becomes visible
func get_bounding_area() -> Rect2:
	var size = camera_size / camera.zoom.x
	return Rect2(camera.global_position - size/2, size)


func _on_go_home_button_down() -> void:
	going_home = true
	_time = 0
