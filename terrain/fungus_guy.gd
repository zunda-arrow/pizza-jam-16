extends RigidBody2D

var done = false

func on_create() -> void:
	rotation = randf_range(-PI,PI)
	linear_velocity = Vector2(randf_range(-5,5),randf_range(-5,5))
	angular_velocity = randf_range(-PI,PI)
	await get_tree().create_timer(1.5).timeout
	collision_layer = 2
	collision_mask = 2
	done = true
	gravity_scale = 0

func _physics_process(delta: float) -> void:
	if done:
		linear_velocity = position.direction_to(Vector2(700,-550)) * 1500
	if position.x > 690:
		queue_free()
		$"../Muhnee".pitch_scale = randf_range(0.9,1.1)
		$"../Muhnee".play(0.02)
