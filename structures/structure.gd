extends RigidBody2D

var structure: StructureResource :
	set(value):
		structure = value
		$Sprite2D.texture = structure.texture.duplicate()
		
