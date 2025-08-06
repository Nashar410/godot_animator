extends Node2D

@onready var episode_controller = $EpisodeController
@onready var video_exporter = $VideoExporter
@onready var background_manager = $BackgroundManager
@onready var dialogue_system = $DialogueStage/UIContainer/DialogueSystem

func _ready():
	add_to_group("main")
	
	_configure_stages()
	_configure_camera()
	
	# Tests
	print("=== TESTING BACKGROUND LOADING ===")
	await get_tree().create_timer(1.0).timeout
	background_manager.test_load_castle_room()
	
	await get_tree().create_timer(2.0).timeout
	dialogue_system.test_dialogue()
	
	# Charger épisode SANS démarrer export automatique
	episode_controller.load_episode("res://episodes/test_episode.json")

func _process(delta):
	_update_dialogue_position()

func _update_dialogue_position():
	"""Faire coller le DialogueStage à la caméra"""
	var camera = $CameraSystem
	var dialogue_stage = $DialogueStage
	
	if not camera or not dialogue_stage:
		return
	
	# Position de la caméra dans le monde
	var camera_world_pos = camera.global_position
	
	# Coin bas-gauche de ce que voit la caméra (pixel art 320x240)
	var camera_bottom_left = camera_world_pos - Vector2(160, 120)
	
	# Positionner dialogue en bas de la vue caméra
	dialogue_stage.position = Vector2(
		camera_bottom_left.x,
		camera_bottom_left.y + 180  # En dessous de AnimationStage
	)

func _configure_stages():
	"""Configuration 2 étages en PIXEL ART"""
	var animation_stage = $AnimationStage
	var dialogue_stage = $DialogueStage
	
	# DIMENSIONS PIXEL ART
	animation_stage.size = Vector2(320, 180)  # 75% de 240
	animation_stage.position = Vector2(0, 0)
	
	dialogue_stage.size = Vector2(320, 60)    # 25% de 240
	dialogue_stage.position = Vector2(0, 180)
	dialogue_stage.visible = false  # MASQUÉ par défaut
	
	print("✅ Pixel Art stages: Animation(320x180) + Dialogue(320x60)")

func _configure_camera():
	"""Caméra pixel art 320x240 mais rendu 1920x1080"""
	var camera = $CameraSystem
	
	camera.enabled = true
	camera.make_current()
	
	# Position au centre de la ZONE PIXEL ART
	camera.position = Vector2(160, 120)  # Centre de 320x240
	camera.zoom = Vector2(1, 1)  # Zoom 1x en pixel art
	
	camera.force_update_scroll()
	
	print("✅ Camera PIXEL ART: 320x240 viewport, scaled to 1920x1080")

# Fonction simple pour montrer/cacher dialogue
func show_dialogue(text: String, character_id: String = "", duration: float = 5.0):
	var dialogue_stage = $DialogueStage
	dialogue_stage.visible = true
	
	# Déléguer au DialogueSystem existant
	var dialogue_system = dialogue_stage.get_node("UIContainer/DialogueSystem")
	if dialogue_system:
		dialogue_system.show_main_dialogue(text, character_id, duration)

func _hide_dialogue():
	$DialogueStage.visible = false

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Espace
		episode_controller.play_episode()
	
	if event.is_action_pressed("ui_select"):  # Entrée - EXPORT MANUEL SEULEMENT
		print("Starting video export...")
		video_exporter.quick_export_current_episode()
	
	if Input.is_action_just_pressed("ui_cancel"):  # Escape
		background_manager.load_background("castle_room", 0.0)
	
	if Input.is_key_pressed(KEY_D):  # Test dialogue
		show_dialogue("Test dialogue étage du bas !", "alex_1", 5.0)
	
	if Input.is_key_pressed(KEY_C):
		var camera = $CameraSystem
		print("=== CAMERA DEBUG ===")
		print("Position: ", camera.position)
		print("Zoom: ", camera.zoom) 
		print("Enabled: ", camera.enabled)
		print("Is Current: ", camera.is_current())
		print("Global Position: ", camera.global_position)
		
		# Test déplacement forcé
		camera.position = Vector2(randf() * 320, randf() * 240)
		print("NEW Position: ", camera.position)
	
	# RESET CAMÉRA
	if Input.is_key_pressed(KEY_R):
		var camera = $CameraSystem
		camera.position = Vector2(160, 120)
		camera.zoom = Vector2(1, 1)
		camera.enabled = true
		camera.make_current()
		print("🔄 Camera RESET to pixel art center")
