class_name StructureResource
extends Resource

#### Definitions for each Structure ####
@export var structure_name: String
@export var size: Array[Rect2i]
## Cells that are required to be ground to place the structure, this should be outside of the structure's rect.
@export var required_ground: Array[Rect2i]
## The point on the sitructure the ants will walk to when they decide to visit.
@export var path_finding_points: Array[Vector2i]
@export var texture: Texture2D
@export var structure_type: Structures
@export var lifetime: int
@export var tiles_radius: int = 11

enum Structures {
	Default,
	Home,
}

class Structure:
	var structure_name: String
	var resource: StructureResource

	# The amount of tiles from the structure you are able to access
	func get_visible_radius():
		return 64

class Home extends Structure:
	func get_visible_radius():
		return 128

var structues = {
	Structures.Default: Structure,
	Structures.Home: Home,
}

func new() -> Structure:
	var structure = structues[structure_type].new()
	structure.resource = self
	structure.structure_name = structure.structure_name
	return structure
