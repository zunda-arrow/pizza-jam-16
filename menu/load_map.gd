extends TileMapLayer


@onready var size = ceil(Vector2(1920, 1080) / tile_set.tile_size.x)

func set_progress(progress: float) -> void:
	var width_current = floor(progress * size.x)
	for x in width_current:
		for y in size.y:
			set_cell(
				Vector2i(x, y),
				0,
				Vector2i(1, 0) if x < (width_current - 1) else Vector2i(6, 1)
			)
