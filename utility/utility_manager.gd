extends Node2D

signal energy_gain(n: int)
signal ants_gain(n: int)
signal discard_gain(n: int)
signal draw_gain(n: int)
signal eff_gain(n: int)
signal money_gain(n: int)
signal bonus_coin_gain(n: int)

var energy: Array[int] = []
var ants: Array[int] = []
var draws: Array[int] = []
var discard: Array[int] = []
var efficiency: Array[int] = []
var treasure: Array[int] = []
var bonus_coins: Array[int] = []

func utilize(utility: UtilityResource, X: int, source: int) -> bool:
	if utility == null:
		return false
	if !utility.discard.is_empty():
		var array = utility.discard.duplicate()
		for i in range(array.size()):
			if i == discard.size():
				discard.append(0)
			discard[i] += x_scaling(array[i], X)
	if !utility.energy.is_empty():
		var array = utility.energy.duplicate()
		energy_gain.emit(x_scaling(array.pop_front(), X))
		for i in range(array.size()):
			if i == energy.size():
				energy.append(0)
			energy[i] += x_scaling(array[i], X)
	if !utility.ants.is_empty():
		var array = utility.ants.duplicate()
		ants_gain.emit(x_scaling(array.pop_front(), X))
		for i in range(array.size()):
			if i == ants.size():
				ants.append(0)
			ants[i] += x_scaling(array[i], X)
	if !utility.draw.is_empty():
		var array = utility.draw.duplicate()
		draw_gain.emit(x_scaling(array.pop_front(), X))
		for i in range(array.size()):
			if i == draws.size():
				draws.append(0)
			draws[i] += x_scaling(array[i], X)
	if !utility.efficiency.is_empty():
		var array = utility.efficiency.duplicate()
		eff_gain.emit(x_scaling(array.pop_front(), X))
		for i in range(array.size()):
			if i == efficiency.size():
				efficiency.append(0)
			efficiency[i] += x_scaling(array[i], X)
	if !utility.treasure.is_empty():
		var array = utility.treasure.duplicate()
		money_gain.emit(x_scaling(array.pop_front(), X))
		for i in range(array.size()):
			if i == treasure.size():
				treasure.append(0)
			treasure[i] += x_scaling(array[i], X)
	
	return true

func x_scaling(n: int, X: int) -> int:
	if n < 0:
		return -n * X
	return n

func stew(at: Vector2i):
	for s in %Structure.structures:
		if at in s.get_tiles():
			s.lifetime == -1
			break

func turn_resources():
	if !energy.is_empty():
		energy_gain.emit(energy.pop_front())
	if !ants.is_empty():
		ants_gain.emit(ants.pop_front())
	if !draws.is_empty():
		draw_gain.emit(draws.pop_front())
	if !discard.is_empty():
		discard_gain.emit(discard.pop_front(), -1)
	if !efficiency.is_empty():
		eff_gain.emit(efficiency.pop_front())
	if !treasure.is_empty():
		money_gain.emit(treasure.pop_front())
	if !bonus_coins.is_empty():
		bonus_coin_gain.emit(bonus_coins.pop_front())
