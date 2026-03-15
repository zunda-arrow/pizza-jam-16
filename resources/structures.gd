class_name StructureResource
extends Resource

#### Definitions for each Structure ####
@export var structure_name: String
@export var size: Array[Rect2i]
@export var texture: Texture2D

class Structure:
	var structure_name: String

func new() -> Structure:
	var structure = Structure.new()
	structure.structure_name = structure.structure_name
	return structure
