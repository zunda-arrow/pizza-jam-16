class_name UtilityResource
extends Resource

# Array index in turn delays, index 0 is immediate.
@export var energy: Array[int]
@export var ants: Array[int]
@export var draw: Array[int]
@export var discard: Array[int]
@export var efficiency: Array[int]
@export var treasure: Array[int]
@export var bonus_coins: Array[int]

class Utility:
	var energy: Array[int]
	var ants: Array[int]
	var draw: Array[int]
	var discard: Array[int]
	var efficiency: Array[int]
	var Treasure: Array[int]
	var bonus_coins: Array[int]
	
func new() -> Utility:
	var util = Utility.new()
	util.energy = energy
	util.ants = ants
	util.draw = draw
	util.discard = discard
	util.efficiency = efficiency
	util.treasure = treasure
	util.bonus_coins = bonus_coins
	return util
	
	
