extends Node

signal end_turn_enable(enable: bool)
signal isolate_card(i: int)

# I am sorry again... but I dont have time to do this properly
@onready var textbox = $"../Toolbar/Textbox"

var current_line = -1

var dialouge_lines = [
	["queen", "Hey! You there! <space to continue>"],
	["ant", "... <space to continue>"],
	["queen", "You’re promoted, you’re now the new NEO - that’s nest expansion officer to the newbies. <space to continue>"],
	["ant", "... <space to continue>"],
	["queen", "The nest is expanding and I need enough fungus to feed my larvae, you better get digging or you’re DECAPITATED. <space to continue>"],
	["ant", "... (panicks) ... <space to continue>"],
	["queen", "What are you waiting for? Get to work! <space to continue>"],
	["queen", "First thing to know, is how to drill. Use your drill to expand this cavern.", 0],
	["queen", "Acceptable, I guess. <space to continue>", 200],
	["queen", "I need everyone to know of my greatness, so build me a statue. It’ll also serve as a point for your workers to expand around.", 0],
	["queen", "Don’t I look beautiful? Obviously this statue is eternal, but most buildings only last the day. <space to continue>", -1],
	["queen", "Now, your daily quota is in the top left, your energy and workers in the top right and you can see what buildings and drills you have available on the left. <space to continue>"],
	["queen", "Good luck, and remember the consequences of you failing. <space to exit>"]
]

func _ready() -> void:
	end_turn_enable.emit(false)
	isolate_card.emit(200) # Effectively disables all cards
	next_line()
	
func next_line():
	current_line+=1
	
	if current_line >= len(dialouge_lines):
		textbox.hide()
		end_turn_enable.emit(true)
		return

	var line = dialouge_lines[current_line]

	if len(line) > 2:
		isolate_card.emit(line[2])
	
	if line[0] == "queen":
		textbox.talk_as_queen(line[1])
	if line[0] == "ant":
		textbox.talk_as_ant(line[1])
	

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_SPACE:
			skip()

func skip() -> void:
	if !textbox.is_line_complete():
		textbox.complete_now()
		return
	if current_line != 7 and current_line != 9:
		next_line()

func _on_arena_card_played(card: CardResource.Card) -> void:
	print("hello world")
	if "Drill" in card.card_name and current_line == 7:
		next_line()
	if "Statue" in card.card_name and current_line == 9:
		next_line()
