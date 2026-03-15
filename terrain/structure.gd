@tool
extends Node2D

@export var structure: StructureResource

func _ready() -> void:
	if structure == null:
		return
	$Sprite2D.texture = structure.texture
