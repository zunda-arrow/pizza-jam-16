extends Node2D

signal energy_gain(n: int)
signal ants_gain(n: int)
signal draw_gain(n: int)

var energy: Array[int] = []
var ants: Array[int] = []
var draws: Array[int] = []
var discard: Array[int] = []
var efficiency: Array[int] = []
var treasure: Array[int] = []

func utilize(utility: UtilityResource) -> bool:
	# TODO: Discard, Efficiency, Treasure
	if !utility.energy.is_empty():
		var array = utility.energy.duplicate()
		energy_gain.emit(array.pop_front())
		for i in range(array.size()):
			if i == energy.size():
				energy.append(0)
			energy[i] += array[i]
	if !utility.ants.is_empty():
		var array = utility.ants.duplicate()
		ants_gain.emit(array.pop_front())
		for i in range(array.size()):
			if i == ants.size():
				ants.append(0)
			ants[i] += array[i]
	if !utility.draw.is_empty():
		var array = utility.draw.duplicate()
		draw_gain.emit((array.pop_front()))
		for i in range(array.size()):
			if i == draws.size():
				draws.append(0)
			draws[i] += array[i]
			
	return true

func turn_reources():
	if !energy.is_empty():
		energy_gain.emit(energy.pop_front())
	if !ants.is_empty():
		ants_gain.emit(ants.pop_front())
	if !draws.is_empty():
		draw_gain.emit(draws.pop_front())
