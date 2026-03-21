@tool
extends Node2D

signal card_purchased(card: CardResource)
signal charge_account(value: int)
signal shopping_done

var cardScene = preload("res://cards/Card.tscn")

@export var start_pos := Vector2(200, 200)
@export var gap := Vector2(300, 300)
@export var cards := Vector2i(5, 2)

var get_money := func(): return 1

@onready var rng = RandomNumberGenerator.new()

func _ready() -> void:
	generate_shop()
	roll_cards()

func generate_shop() -> void:
	for child in %CardContainer.get_children():
		child.queue_free()
	var current_pos = start_pos
	var i := 0
	for y in cards.y:
		for x in cards.x:
			var new_card = cardScene.instantiate()
			new_card.position = current_pos
			new_card.on_clicked.connect(func(): card_clicked(i, new_card.card_resource))
			%CardContainer.add_child(new_card)
			i += 1
			current_pos.x += gap.x
		current_pos.x = start_pos.x
		current_pos.y += gap.y

func roll_cards() -> void:
	for child in %CardContainer.get_children():
		child.show()
		var card = roll_card()
		child.card_resource = card
		child.instantiated_card_resource = card.new()

func roll_card() -> CardResource:
	return AllCards.resources[
		rng.rand_weighted(
			AllCards.resources.map(func(card): return card.rarity)
		)
	]

func card_clicked(idx: int, card: CardResource) -> void:
	if not card or get_money.call() < card.cost: # Can't afford
		return
	%CardContainer.get_child(idx).hide()
	charge_account.emit(card.cost)
	card_purchased.emit(card)

	$Money.text = "Money: " + str(get_money.call())

func on_open() -> void:
	$Money.text = "Money: " + str(get_money.call())
	roll_cards()

func on_done_pressed() -> void:
	shopping_done.emit()


func _process(delta: float) -> void:
	for card in  %CardContainer.get_children():
		if card.hovered:
			card.scale = lerp(card.scale, Vector2(1.3, 1.3), 30 * delta)
		else:
			card.scale = lerp(card.scale, Vector2(1.0, 1.0), 30 * delta)
