extends TileMapLayer

# Radius is a square radius
func destroy(position: Vector2i, diameter: int):
	var radius = diameter / 2.
	var cell_coordinate_center = local_to_map(Vector2i(position.x,position.y+40))
	
	for x in range(ceil(cell_coordinate_center.x-radius),ceil(cell_coordinate_center.x+radius)):
		for y in range(ceil(cell_coordinate_center.y-radius),ceil(cell_coordinate_center.y+radius)):
			self.erase_cell(Vector2(x,y))

	
func _input(event):
	# Mouse in viewport coordinates.
	if event is InputEventMouseButton:
		destroy(to_local(event.position),3)
