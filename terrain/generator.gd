# Handles terrain generation
extends Node2D

@export var initial_seed = 0 # The noise seed on ready. If set to 0, random seed.

@export var noise: FastNoiseLite # The noise we will use to generate the terrain
@export var block_threshold: float = 0.5 # Threshold to place a block (less than)
@export var unbreakable_threshold: float = 0.0 # Threshold to place an unbreakable block #TODO: Implement

@onready var tilemap: TileMapLayer = %GroundMap

func _ready():
    if initial_seed == 0:
        initial_seed = randi()
    generate(initial_seed)

func generate(new_seed) -> void:
    tilemap.clear()
    noise.seed = new_seed

    await get_tree().process_frame

    var set_cells = []
    for y in 100:
        for x in 100:
            #TODO: Can probably do this better.
            if get_cell(x, y):
                set_cells.append(Vector2i(x, y))
    tilemap.set_cells_terrain_connect(set_cells, 0, 0)

func get_cell(x: int, y: int) -> bool: # Check if there is a cell here
    return absf(noise.get_noise_2d(x, y)) > block_threshold
