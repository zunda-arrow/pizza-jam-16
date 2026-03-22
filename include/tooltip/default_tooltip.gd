@tool

extends Control

@export var around: Node
@export var card: CardResource

func _ready() -> void:
	%Tooltip.show_when_hovering = around
	%Tooltip.around = around
	%Tooltip.avoid_overlap.push_back(around)

func _process(delta: float) -> void:
	if card == null:
		return

	%MainTooltip.tooltip_name = card.card_name
	%MainTooltip.tooltip_description = card.description
	%MainTooltip.tooltip_cost = card.cost
