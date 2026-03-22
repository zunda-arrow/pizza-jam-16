extends Control


signal skip

var target_text: String = ""
var idx = 0
var current_text = ""

var timer = 0

func talk_as_ant(text: String):
	target_text = text
	idx = 0
	current_text = ""
	%AntPortrait.play("talk")
	
	%QueenPortrait.hide()
	%AntPortrait.show()
	%AntTextbox.show()
	%QueenTextbox.hide()

func talk_as_queen(text: String):
	target_text = text
	idx = 0
	current_text = ""
	
	%QueenPortrait.play("talk")
	
	%QueenPortrait.show()
	%AntPortrait.hide()
	%AntTextbox.hide()
	%QueenTextbox.show()

func is_line_complete():
	return len(target_text) <= len(current_text)

func complete_now():
	current_text = target_text
	idx = len(target_text)

func box_gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_LEFT and ev.is_pressed():
			skip.emit()


func _process(delta: float) -> void:
	timer += delta
	if idx >= len(target_text):
		%AntPortrait.pause()
		%QueenPortrait.pause()
	
	if timer > .01 and idx < len(target_text):
		current_text += target_text[idx]
		timer = 0
		idx += 1

	%AntTextbox.text = current_text
	%QueenTextbox.text = current_text
