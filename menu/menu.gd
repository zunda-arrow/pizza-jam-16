extends CenterContainer

var loading_game = false
var delay = 2

@onready var menu = $MainMenu
@onready var options = $Options
@onready var loadmap = $LoadMap

@onready var title = $MainMenu/HBoxContainer/Label

func _ready() -> void:
	title.text = ProjectSettings.get_setting("application/config/name")
	menu.show()
	options.hide()

func start_pressed() -> void:
	print("Starting the game")
	ResourceLoader.load_threaded_request("res://game/game.tscn")
	loading_game = true

func options_pressed() -> void:
	if loading_game:
		return
	options.show()
	menu.hide()

func options_back_pressed() -> void:
	menu.show()
	options.hide()

func quit_pressed() -> void:
	get_tree().quit()

func _process(_delta: float) -> void:
	if not loading_game:
		return
	var progress = []
	ResourceLoader.load_threaded_get_status("res://game/game.tscn", progress)
	loadmap.set_progress(progress[0])
	if progress[0] == 1.0:
		delay -= 1
		if delay <= 0:
			var scn = ResourceLoader.load_threaded_get("res://game/game.tscn")
			get_tree().change_scene_to_packed(scn)
