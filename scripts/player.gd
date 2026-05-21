#base class that finnish and polish players will inherit
extends CharacterBody2D
var last_item
@export var speed = 1

@export var dev_mode = false

var screen_size
var last_played_anim #the last walking animation played - this is used to play the right idle animation once the player stops moving
var complete_save_data #the save data for both characters
var character_name

var touched_item_name = "" #the name of the collectible that the player is nearby

var place_name = "" #the name of the place a player is on - casino/store/construction site

var can_enter_store_and_casino

var ready_to_build = false

var money

signal item_placed(item_name)

signal build

signal enter_sauna
var current_character_save_data

var is_secondary = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	character_name = name.replace("Character", "")
	print(character_name)
	if character_name == "Finn" or character_name == "Pole": #for SOME reason, there appears to be a third node with this script and a weird name
		
		var loaded_file = FileAccess.open("res://save_game.data", FileAccess.READ)
		complete_save_data = loaded_file.get_var()
		current_character_save_data = complete_save_data.get(character_name)
		print(complete_save_data)
		if current_character_save_data.get("last_item") == "" or get_parent().name == "CaveLevel":
			position = $"../StartingPoint".position
		else:
			position = current_character_save_data.get("position")

		last_item = current_character_save_data.get("last_item")
		if last_item == "Stones":
			touched_item_name = "Stones"
		else:
			touched_item_name = ""
		if dev_mode:
			money = 999
		else:
			money = current_character_save_data.get("money")
		screen_size = get_viewport_rect().size
		$Camera2D.set_limit(Side.SIDE_LEFT, 0)
		$Camera2D.set_limit(Side.SIDE_RIGHT, int(screen_size.x))
		$Camera2D.set_limit(Side.SIDE_TOP, 0)
		$Camera2D.set_limit(Side.SIDE_BOTTOM, int(screen_size.y))
	else:
		queue_free()
func save_game():
	if get_parent().name != "CaveLevel":
		var current_scene_save_data = {"position":position, "last_item":last_item, "money":money} 
		complete_save_data.set(character_name, current_scene_save_data)
		if place_name != "cave": #if we are NOT on the level where you need to enter the cave!
			var new_objective_id = get_parent().objective_id + 1
			complete_save_data.set("objective_id", new_objective_id)
	else:
		current_character_save_data.set("last_item", last_item)
		current_character_save_data.set("money", money)
		complete_save_data.set(character_name, current_character_save_data)
		
	#if we enter or leave the cave, don't!!

	
	
	var file = FileAccess.open("res://save_game.data", FileAccess.WRITE)

	file.store_var(complete_save_data)
	file.close()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	velocity = Vector2.ZERO # The player's movement vector.
	if (Input.is_action_pressed("move_right") and !is_secondary) or (is_secondary and  Input.is_action_pressed("move_right_secondary")):
		velocity.x += 1
	if (Input.is_action_pressed("move_left") and !is_secondary) or (is_secondary and  Input.is_action_pressed("move_left_secondary")):
		velocity.x -= 1
	if (Input.is_action_pressed("move_down") and !is_secondary) or (is_secondary and  Input.is_action_pressed("move_down_secondary")):
		velocity.y += 1
	if (Input.is_action_pressed("move_up") and !is_secondary) or (is_secondary and  Input.is_action_pressed("move_up_secondary")):
		velocity.y -= 1
	if velocity.length() > 0:
		if !$WalkingSoundPlayer.playing:
			$WalkingSoundPlayer.play()
		$PlayerSprite.play()
		
	else:
		$WalkingSoundPlayer.stop()
		$PlayerSprite.stop()
		$PlayerSprite.animation = $PlayerSprite.animation.replace("walk", "idle")
		$PlayerSprite.play()
	
	position = position.clamp(Vector2.ZERO, screen_size)
	move_and_collide(velocity)

	if velocity.x > 0:
		$PlayerSprite.animation = "walk_right"
	elif velocity.y > 0:
		$PlayerSprite.animation = "walk_down" #this is not a mistake - godot's (0,0) coords are in the "top left corner", so y is posiitve if the vector is pointing downwards. Don't change!
	elif velocity.x < 0:
		$PlayerSprite.animation = "walk_left"
	elif velocity.y < 0:
		$PlayerSprite.animation = "walk_up"
	
		
	last_played_anim = 	$PlayerSprite.animation

	if Input.is_action_just_pressed("item_interact") and !is_secondary:
		print(place_name)
		match place_name:
			"construction site":
				print(touched_item_name)
				if (touched_item_name == "Furnace" or touched_item_name == "Stones"):
					last_item = touched_item_name
					item_placed.emit(touched_item_name)
				elif ready_to_build:
					build.emit()
			"cave":
				if last_item == "Furnace":
					save_game()
					get_tree().change_scene_to_file("res://scenes/quiz.tscn")
			"airport":
				if touched_item_name == "Beer":
					get_tree().change_scene_to_file("res://scenes/flying.tscn")
			"casino":
				if last_item == "Sauna oil" and money < 250:
					save_game()
					get_tree().change_scene_to_file("res://scenes/casino_minigame.tscn")
			"store":
				if money >= 250:
					get_parent().get_node("CashSoundPlayer").play()
					get_parent().get_node("StoreArea/Sprite2D").texture = load("res://images/sprites/FrogShopOGDoorsOpen.png")
					money -= 250
					var new_objective_id = get_parent().objective_id + 1
					get_parent().set_objective_id(new_objective_id)
					_on_item_picked_up("Beer")
			"sauna": #issue: if both players are on the sauna and one walks in, the other has to leave and then go back to be able to enter
				enter_sauna.emit()
				queue_free()


	if Input.is_action_just_pressed("item_interact_secondary") and is_secondary:
		if place_name == "sauna":
			enter_sauna.emit()
			queue_free()
func _on_item_picked_up(item_name): #this entire function feels very unoptimized, try to smmoothen it out
	await get_tree().create_timer(0.5).timeout
	touched_item_name = item_name
	print(touched_item_name + " found!")
	if touched_item_name != "Furnace":
		
		if !((touched_item_name == "Oil" and last_item != "Lavender") or (touched_item_name == "Lavender" and last_item != "Oil")):

			if touched_item_name == "Oil" or touched_item_name == "Lavender":
				last_item = "Sauna oil"
			else:
				last_item = touched_item_name
			save_game()
			if touched_item_name != "Beer":
				if get_parent().name == "PolishRootNode" or get_parent().name == "CaveLevel":
					get_tree().change_scene_to_file("res://scenes/finnish_map.tscn")
				else:
					get_tree().change_scene_to_file("res://scenes/polish_map.tscn")
			
		else:
			last_item = touched_item_name #this should trigger for oil and lavender, but NOT furnace!

func _on_enter_sauna():
	place_name = "sauna"

func _on_enter_cave(args):
	place_name = "cave"

func _on_enter_construction_site(args):
	place_name = "construction site"		 

func _on_enter_airport(args):
	place_name = "airport"		 

func _on_enter_casino(args):
	place_name = "casino"

func _on_enter_store(args):
	place_name = "store"		 

func _on_exit_place(args = null):
	place_name = ""