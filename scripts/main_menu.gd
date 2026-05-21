extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CenterContainer/VBoxContainer/PlayButton.button_down.connect(_start_game)
	$CenterContainer/VBoxContainer/CreditsButton.button_down.connect(_show_credits)
	$CenterContainer/VBoxContainer/ReturnButton.button_down.connect(_return_to_menu)

func _start_game():
	var initial_data = {
		"objective_id":0,
		"Finn":
			{
				"position":"",
				"last_item":"",
				"money":50
			},
		"Pole":
			{
				"position":"",
				"last_item":"",
				"money":50
			}
	}
	var file = FileAccess.open("res://save_game.data", FileAccess.WRITE)
	file.store_var(initial_data)
	file.close()
	get_tree().change_scene_to_file("res://scenes/intro_scene.tscn")

func _show_credits():
	$CenterContainer/VBoxContainer/PlayButton.hide()
	$CenterContainer/VBoxContainer/CreditsButton.hide()
	$CenterContainer/VBoxContainer/ReturnButton.show()
	$CenterContainer/VBoxContainer/Label.show()
	$CenterContainer/VBoxContainer/Label.text = "Programming: Ignacy Guminiak, Michał Wójtowicz, Zuzanna Dróżdż, Jan Kukier\nNetwork management: Jan Kukier, Jan Maciejewski, Jakub Klimowicz\nGraphic design: Michał Wójtowicz, Zuzanna Dróżdż, Jan Maciejewski\nAudio design: Jakub Klimowicz, Jan Sarnecki, Ignacy Guminiak\nProject leader: Jakub Klimowicz\nSpecial thanks to mechatronics team :)\n"
	$CenterContainer/VBoxContainer/Label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
func _return_to_menu():
	$CenterContainer/VBoxContainer/PlayButton.show()
	$CenterContainer/VBoxContainer/CreditsButton.show()
	$CenterContainer/VBoxContainer/ReturnButton.hide()
	$CenterContainer/VBoxContainer/Label.hide()
