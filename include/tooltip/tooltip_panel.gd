@tool
extends Control

@export var tooltip_name: String = "Name"
@export_multiline var tooltip_description: String = "Example tooltip description"
@export var tooltip_cost: int = 0

func _process(_delta) -> void:
	%TooltipName.text = tooltip_name
	%TooltipDescription.text = tooltip_description
	%Cost.text = str(tooltip_cost)
