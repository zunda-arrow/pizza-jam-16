extends Node2D


func _ready() -> void:
	if get_parent() == get_tree().root:
		add_struct(Vector2(0, -100), preload("res://resources/structures/example.tres"))
	else:
		%StructureHolder.queue_free()

func add_struct(pos: Vector2, structure: StructureResource) -> void:
	# We will assume checking it is safe to place is done elsewhere for now
	var new_struct = structure
	var new_struct_scene = preload("res://structures/structure.tscn").instantiate()
	new_struct_scene.structure = new_struct
	add_child(new_struct_scene)
