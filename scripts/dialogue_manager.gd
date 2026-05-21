extends Control
var is_line_finished

var dialogue_dict = {
	0:
		["Finn:No moi, what's up? How are things with you?", "Pole:Siema! Pretty chill, some studying, some gaming. What about you?", "Finn:Same here, been spending a lot of time outside lately. The weather's actually nice.", "Pole:Nice, kinda jealous. The weather here is all over the place.", "Finn:Yeah, I get that… hey, I've got an idea.", "Pole:Alright, let's hear it.", "Finn:Let's build a sauna. ", "Pole:Oh alright, bet.", "Finn:Knew you'd be in."],
	1:
		["Rudolf:Hello! My name is Rudolf and I will guide you through the game rules.", "Rudolf:First of all, move your character with  W(up), S(down), A(left), D(right). ", "Rudolf:To pick up an item from the ground or to interact with objects, press  E.", "Rudolf:Your goal is to get materials from both Polish and Finnish maps to hit a sauna together!", "Rudolf:You start as a Finnish character. After picking one or two materials (depending on the level) you will move to the second map and play as a second character.", "Rudolf:On the Finnish map, find wooden logs, an empty furnace and stones from the cave to fill the furnace.", "Rudolf:On the Polish map, find towels, plus oil and lavender to create the sauna aroma. As for the final item, go to the casino, win some money, then buy some beer in Żabka!","Rudolf:After collecting all of the materials and items, walk to the airport and fly to Finland!", "Rudolf:The game ends when you successfully build a sauna with the materials gathered and go in with both characters to chill out together.","Rudolf:Good luck!"],
	2:
		["Troll:Uhehehe! Not so fast, kaveri!", "Troll:If you wish to explore this cave, you must answer my questions fist!", "Troll:Three wrong answers, and you're OUT!", "Troll:Oletko valmis? Yks, kaks...", "Troll:Q-What is the Finnish word for “dom”?", "Troll:Q-What does the Finnish word “vesi” mean in Polish?", "Troll:Q-What is the Polish translation of the Finnish word “ystävä”?", "Troll:Q-What does the Polish word “szkoła” mean in Finnish?","Troll:Q-What is the Finnish word for “książka”?","Troll:Q-What does the Finnish word “aurinko” mean in Polish?","Troll:Q-How do you say “samochód” in Finnish?","Troll:Q-What does the Polish word “jabłko” mean in Finnish?","Troll:Q-What is the Finnish word for “okno”?","Troll:Q-What does the Finnish word “ruoka” mean in Polish?", "Troll:Done! You have X/10 correct answers, and you need at least 7 to pass!"],
	3:
		["Rudolf:Tervetuloa Suomeen! Now, walk to the building spot, and press E to construct your sauna."],
	4:
		["Rudolf:Beautiful! Now let's hop into the sauna together. Walk in there with one character, then with the second one (use arrows and F in place of WASD and E for the Pole)."]
}
var answers = [
	["koulu", "talo", "kirja"],
	["ogień", "woda", "chleb"],
	["przyjaciel", "nauczyciel", "lekarz"],
	["koulu", "pöytä", "ikkuna"],
	["kirja", "auto", "ovi"],
	["księżyc", "gwiazda", "słońce"],
	["pyörä", "auto", "tie"],
	["omena", "banaani", "appelsiini"],
	["ikkuna", "tuoli", "pöytä"],
	["szkoła", "jedzenie", "rodzina"],
]
var correct_answers = [1,1,0,0,0,2,1,0,0,1]
@export var scene_id = 0 #info about which scene we're in

var line_id = 0
var current_scene_dialogue
var current_line
var character_index = 0
var next_scene

var question_id = 0
var answer_id = 0
var quiz_mode = false
var number_of_correct_answers = 0
var opacityDirection = -1
var dialogue_sfx = []

var current_sound_name

# Called when the node enters the scene tree for the first time.

func initiate():
	
	$TalkerSprite.play()
	
	$AnswerAButton.pressed.connect(_on_player_select_answer_a)
	$AnswerBButton.pressed.connect(_on_player_select_answer_b)
	$AnswerCButton.pressed.connect(_on_player_select_answer_c)
	if scene_id != 3 and scene_id != 4:
		position = get_viewport_rect().get_center()
	match scene_id: #i know this doesn't deal with the quiz, but that's handled below, dw
		0:
			next_scene = "tutorial"
			dialogue_sfx = ["PhoneChatter1","PhoneChatter2", "PhoneChatter1","PhoneChatter2", "PhoneChatter1","PhoneChatter2", "PhoneChatter1","PhoneChatter2", "PhoneChatter1"]

		1:
			next_scene = "finnish_map"
			dialogue_sfx = ["ReindeerIntro/ri1", "ReindeerIntro/ri2", "ReindeerIntro/ri3", "ReindeerIntro/ri4", "ReindeerIntro/ri5", "ReindeerIntro/ri6", "ReindeerIntro/ri7", "ReindeerIntro/ri8", "ReindeerIntro/ri9", "ReindeerIntro/ri10",]
		2:
			dialogue_sfx = ["TrollCave1", "TrollCave2", "TrollCave1", "TrollCave2", "TrollCave1", "TrollCave2", "TrollCave1", "TrollCave2", "TrollCave1", "TrollCave2", "TrollCave1", "TrollCave2", "TrollCave1", "TrollCave2", "TrollCave1", "TrollCave2","TrollCave1", "TrollCave2","TrollCave1", "TrollCave2","TrollCave1", "TrollCave2","TrollCave1", "TrollCave2","TrollCave1", "TrollCave2","TrollCave1", "TrollCave2","TrollCave1", "TrollCave2","TrollCave1", "TrollCave2",]
		3:
			dialogue_sfx = ["PhoneChatter1"]
		4:
			dialogue_sfx = ["PhoneChatter1"]
	$DialogueRTLabel.text = ""
	current_scene_dialogue = dialogue_dict.get(scene_id)
	$TalkingSFXPlayer.stream = ResourceLoader.load("res://Sound Effects/" + dialogue_sfx[0] + ".mp3")
	$TalkingSFXPlayer.play()
	$TalkerSprite.animation = current_scene_dialogue[0].split(":")[0] + "Talk"
	$TalkerSprite.play()
	current_line = current_scene_dialogue[0].split(":")[1]
func _ready() -> void:

	if visible:
		initiate()

#maybe have the enter stuff only trigger if we're not in a quiz question

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta:float) -> void:
	#could be a good idea to set the text speed to match the speaking speed of the mp3 file
	if $AdvanceTipLabel.visible:
		$AdvanceTipLabel.modulate.a += 1 * opacityDirection * delta
		if $AdvanceTipLabel.modulate.a < 0.3 or $AdvanceTipLabel.modulate.a >= 1:
			opacityDirection *= -1
	#print($AdvanceTipLabel.modulate.a)
		
			
		
	if visible:
		if Input.is_action_just_pressed("advance_dialogue"):
			
			if is_line_finished:
				if current_line.contains("Q-"):
					if !quiz_mode:
						quiz_mode = true
					$DialogueRTLabel.hide()
					$BubbleSprite.hide()
					$TalkerSprite.hide()
					$AdvanceTipLabel.hide()
					$AdvanceTipBG.hide()

					$AnswerAButton.text = "A." + answers[question_id][0]
					$AnswerAButton.disabled = false
					$AnswerAButton.show()

					$AnswerBButton.text = "B." + answers[question_id][1]
					$AnswerBButton.disabled = false
					$AnswerBButton.show()

					$AnswerCButton.text = "C." + answers[question_id][2]	
					$AnswerCButton.disabled = false			
					$AnswerCButton.show()
					
					if scene_id != 1:
						$TalkingSFXPlayer.stop() 
				else: 
					
					if line_id < current_scene_dialogue.size()-1:
						show_next_line()
					else:
						hide()
						if quiz_mode:
							if number_of_correct_answers >= 7:
								next_scene = "cave_level"
							else:
								next_scene = "finnish_map"
						if scene_id != 3 and scene_id != 4: #so it doesn't trigger on the sauna building level
							get_tree().change_scene_to_file("res://scenes/" + next_scene+".tscn")
			else:
				if character_index > 4:
					is_line_finished = true
					$DialogueRTLabel.text = current_line
					character_index = current_line.length()
					$TalkerSprite.stop()
					$AdvanceTipLabel.show()
					$AdvanceTipBG.show()
					if scene_id != 1:
						$TalkingSFXPlayer.stop() 

		elif not is_line_finished:
			if character_index >= current_line.length():
				is_line_finished = true
				$TalkerSprite.stop()
				$AdvanceTipLabel.show()
				$AdvanceTipBG.show()
				if scene_id != 1:
					$TalkingSFXPlayer.stop() 
			else:
				$DialogueRTLabel.text += current_line[character_index]
				character_index += 1
				
	
		
func disable_buttons():
	$AnswerAButton.disabled = true
	$AnswerBButton.disabled = true
	$AnswerCButton.disabled = true
func _on_player_select_answer_a():
	disable_buttons()
	answer_id = 0
	verify_answer()
func _on_player_select_answer_b():
	disable_buttons()
	answer_id = 1
	verify_answer()
func _on_player_select_answer_c():
	disable_buttons()
	answer_id = 2
	verify_answer()

func verify_answer():
	if answer_id == correct_answers[question_id]:
		$VerificationLabel.text = "CORRECT!!!"
		number_of_correct_answers += 1
	else:
		$VerificationLabel.text = "INCORRECT!!! Correct answer is: " + answers[question_id][correct_answers[question_id]]
	$VerificationLabel.show()
	get_tree().create_timer(1).timeout.connect(show_next_line)


func show_next_line():
	if quiz_mode: 
		
		$AnswerAButton.hide()
		$AnswerBButton.hide()
		$AnswerCButton.hide()
		$VerificationLabel.hide()


		$DialogueRTLabel.show()
		$BubbleSprite.show()
		$TalkerSprite.show()
		$AdvanceTipLabel.show()
		$AdvanceTipBG.show()
		question_id += 1
	
	
	$AdvanceTipLabel.hide()
	$AdvanceTipBG.hide()
	line_id += 1
	
	current_sound_name = dialogue_sfx[line_id]
	$TalkingSFXPlayer.stream = ResourceLoader.load("res://Sound Effects/" + current_sound_name + ".mp3")
	$TalkingSFXPlayer.play() 
	$TalkerSprite.animation = current_scene_dialogue[line_id].split(":")[0] + "Talk"
	$TalkerSprite.play()
	$DialogueRTLabel.text = ""
	is_line_finished = false
	character_index = 0
	
	current_line = current_scene_dialogue[line_id].split(":")[1]
	if current_line.contains("X"):
		current_line = current_line.replace("X", str(number_of_correct_answers))



