extends Node2D

var items_for_current_player = []
var last_item
var current_item_name
var player
var play_ending = false
var screen_size
var num_of_players_in_sauna = 0

var objective_id = 0
var objectives = ["Pick up wooden logs", "Pick up towels", "Pick up furnace and place it down at the construction site", "Pick up oil and lavender", "Pick up stones from the cave and place them in the furnace", "Go to the casino", "Buy a beer in the Frogshop", "Fly to Finland!", "Build a sauna", "Go to the sauna with both characters!"]
# Called when the node enters the scene tree for the first time.

func set_objective_id(id):
	objective_id = id
	$CanvasLayer/ObjectiveLabel.text = "Objective: " + objectives[objective_id] #throws Invalid access to property or key '<null>' on a base object of type 'Array'.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	
	var file = FileAccess.open("res://save_game.data", FileAccess.READ)
	var current_objective = file.get_var().get("objective_id")
	set_objective_id(current_objective)
	file.close()

	file = FileAccess.open("res://save_game.data", FileAccess.READ)
	match name:
		"FinnishRootNode":
			last_item = file.get_var().get("Finn").get("last_item")
			items_for_current_player = ["Wood", "Furnace", "Stones", "Filled furnace"]
			player = $FinnCharacter
			player.item_placed.connect(place_item)
			
			$ConstructionArea.body_entered.connect(player._on_enter_construction_site)
			$ConstructionArea.body_exited.connect(player._on_exit_place)
			
			$Cave.body_entered.connect(player._on_enter_cave)
			$Cave.body_exited.connect(player._on_exit_place)

		"PolishRootNode":
			last_item = file.get_var().get("Pole").get("last_item")
			items_for_current_player = ["Towel", "Sauna oil", "Beer"]
			player = $PoleCharacter
			$AirportArea.body_entered.connect(player._on_enter_airport)
			$AirportArea.body_exited.connect(player._on_exit_place)

			$CasinoArea.body_entered.connect(player._on_enter_casino)
			$CasinoArea.body_exited.connect(player._on_exit_place)

			$StoreArea.body_entered.connect(player._on_enter_store)
			$StoreArea.body_exited.connect(player._on_exit_place)
		"CaveLevel":
			player = $FinnCharacter
			last_item = file.get_var().get("Finn").get("last_item")
			items_for_current_player = ["Wood", "Furnace", "Stones", "Filled furnace"]

	if last_item != items_for_current_player[-1]:
		if last_item == "":
			current_item_name = items_for_current_player[0]
		elif last_item == "Sauna oil":
			player.can_enter_store_and_casino = true
			current_item_name = "Beer"
		else:
			current_item_name = items_for_current_player[items_for_current_player.find(last_item) + 1]
			if (last_item == "Furnace" and name != "CaveLevel") or last_item == "Stones":
				$Furnace.position = $ConstructionArea.position
				$Furnace.show()

		if current_item_name != "Beer" and !(current_item_name == "Stones" and name != "CaveLevel") and current_item_name != "Filled furnace":
			if current_item_name == "Sauna oil":
				var first_item = $Oil
				first_item.show()
				get_node(first_item.name+"/CollisionShape2D").disabled = false
				first_item.picked_up.connect(player._on_item_picked_up)
				var second_item = $Lavender
				second_item.show()
				get_node(second_item.name+"/CollisionShape2D").disabled = false
				second_item.picked_up.connect(player._on_item_picked_up)
			else:
				var current_item = get_node(current_item_name)
				current_item.show()
				get_node(current_item_name+"/CollisionShape2D").disabled = false
				current_item.picked_up.connect(player._on_item_picked_up)
	else:
		play_ending = true
	
	file.close()
	if play_ending:

				
		var polish_player = preload("res://scenes/polish_player.tscn")
		add_child(polish_player.instantiate())
		
		player.position.y -= 50

		$FirstLineDialogueWindow.show()
		$FirstLineDialogueWindow.initiate()
		$FinnCharacter.enter_sauna.connect(_on_player_enter_sauna)
		$PoleCharacter.enter_sauna.connect(_on_player_enter_sauna)
		
		$PoleCharacter.position = player.position
		$PoleCharacter.position.x += 50
		$PoleCharacter.is_secondary = true
		
		
		
		$FinnCharacter.ready_to_build = true
		$FinnCharacter.build.connect(_on_player_begin_building)

func _on_player_enter_sauna():
	num_of_players_in_sauna += 1
	if num_of_players_in_sauna == 2:
		get_tree().change_scene_to_file("res://scenes/ending.tscn")

func _on_player_begin_building():
	$FirstLineDialogueWindow.hide()
	$BuildingSoundPlayer.play()
	$SaunaBuildingSprite.show()
	$SaunaBuildingSprite.animation = "Building"
	$SaunaBuildingSprite.play()
	await get_tree().create_timer(3).timeout

	$SaunaBuildingSprite.stop()
	$SaunaBuildingSprite.hide()
	$ConstructionArea.hide()
	$ConstructionArea/CollisionShape2D.disabled = true
	$Sauna.show()
	$Sauna/CollisionShape2D.disabled = false

	$SecondLineDialogueWindow.show() #having them be 2 completely separate windows seems bad, i may change it later
	$SecondLineDialogueWindow.initiate()
	#var pole = $PoleCharacter
	# $Sauna.body_entered.connect(player._on_enter_sauna)
	# $Sauna.body_entered.connect(pole._on_enter_sauna)
	# $Sauna.body_exited.connect(player._on_exit_place)
	# $Sauna.body_exited.connect(pole._on_exit_place)
	$Sauna.body_entered.connect(_on_body_enter_sauna)
	$Sauna.body_exited.connect(_on_body_exit_sauna)

func _on_body_enter_sauna(body : Node2D):
	if body.name == "FinnCharacter":
		player._on_enter_sauna()
	else:
		$PoleCharacter._on_enter_sauna()

func _on_body_exit_sauna(body : Node2D):
	if body.name == "FinnCharacter":
		player._on_exit_place()
	else:
		$PoleCharacter._on_exit_place()
func place_item(item_name):
	match item_name:
		"Furnace":
			if current_item_name != "Stones":
				
				$Furnace.position = $ConstructionArea.position
				$Furnace.show()
				player.last_item = "Furnace"
				player.save_game()
				
		"Stones":
			player.last_item = "Filled furnace"
			player.save_game()
			$Furnace/Sprite2D.texture = load("res://images/sprites/furnaceFilled.png")
			
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/polish_map.tscn")


	
