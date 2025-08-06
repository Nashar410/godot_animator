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

func _configure_stages():
	"""Configuration des 2 étages"""
	var animation_stage = $AnimationStage
	var dialogue_stage = $DialogueStage
	
	animation_stage.size = Vector2(1920, 810)
	animation_stage.position = Vector2(0, 0)
	
	dialogue_stage.size = Vector2(1920, 270)
	dialogue_stage.position = Vector2(0, 810)
	
	# Fond de debug
	var debug_bg = ColorRect.new()
	debug_bg.name = "DebugBG"
	debug_bg.color = Color(0.1, 0.1, 0.2, 0.2)
	debug_bg.size = Vector2(1920, 270)
	debug_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_stage.add_child(debug_bg)
	
	print("✅ Two stages configured")

func _configure_camera():
	"""Configurer la caméra pour voir le background"""
	var camera = $CameraSystem
	
	# Centrer sur votre background (position 256,170 scale 0.25)
	camera.position = Vector2(384, 298)  
	camera.zoom = Vector2(4, 4)
	
	print("✅ Camera configured for background")

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Espace
		episode_controller.play_episode()
	
	if event.is_action_pressed("ui_select"):  # Entrée - EXPORT MANUEL SEULEMENT
		print("Starting video export...")
		video_exporter.quick_export_current_episode()
	
	if Input.is_action_just_pressed("ui_cancel"):  # Escape
		background_manager.load_background("castle_room", 0.0)
	
	if Input.is_key_pressed(KEY_D):  # Test dialogue
		dialogue_system.show_main_dialogue("Test dialogue étage du bas !", "alex_1", 5.0)
