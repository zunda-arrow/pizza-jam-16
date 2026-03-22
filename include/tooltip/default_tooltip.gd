@tool

extends Control

@export var around: Node
var card: CardResource

func _ready() -> void:
	%Tooltip.show_when_hovering = around
	%Tooltip.around = around
	%Tooltip.avoid_overlap.push_back(around)
