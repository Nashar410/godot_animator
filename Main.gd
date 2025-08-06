extends Node2D

@onready var episode_controller = $EpisodeController
@onready var video_exporter = $VideoExporter
@onready var background_manager = $BackgroundManager
@onready var dialogue_system = $DialogueStage/UIContainer/DialogueSystem

func _ready():
	add_to_group("main")
	
	print("=== SYSTÈME CAMÉRA MOBILE + DIALOGUE COLLÉ ===")
	
	_configure_animation_stage()
	_configure_dialogue_stage()
	_configure_camera()
	
	
	# Charger épisode
	episode_controller.load_episode("res://episodes/test_episode.json")

func _process(_delta):
	# Plus de gestion dialogue ici - tout est dans DialogueSystem.gd
	pass

func _configure_animation_stage():
	"""AnimationStage = toute la scène 1920x1080"""
	var animation_stage = $AnimationStage
	
	# L'AnimationStage couvre TOUTE la scène virtuelle
	animation_stage.size = Vector2(1920, 1080)  
	animation_stage.position = Vector2(0, 0)
	
	print("✅ AnimationStage configuré : 1920x1080 (scène complète)")

func _configure_dialogue_stage():
	"""DialogueStage géré par DialogueSystem.gd"""
	var dialogue_stage = $DialogueStage
	
	# Le DialogueStage couvre tout l'écran pour que DialogueSystem puisse gérer le positionnement
	dialogue_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialogue_stage.visible = true  # Toujours visible, c'est le panel interne qui se cache/montre
	
	print("✅ DialogueStage restored to working version")

func _configure_camera():
	"""Caméra mobile 320x180 dans scène complète 1920x1080"""
	var camera = $CameraSystem
	
	camera.enabled = true
	camera.make_current()
	
	# ZOOM pour voir 320x180 du monde sur écran 1920x1080
	camera.zoom = Vector2(6, 6)
	
	# Position de départ au centre du background
	camera.position = Vector2(960, 540)  # Centre de 1920x1080
	
	# LIMITES pour rester dans la scène 1920x1080
	var view_width = 320
	var view_height = 180
	
	camera.limit_left = view_width / 2        # 160
	camera.limit_right = 1920 - view_width / 2  # 1760
	camera.limit_top = view_height / 2        # 90
	camera.limit_bottom = 1080 - view_height / 2  # 990
	camera.limit_smoothed = true
	
	camera.force_update_scroll()
	
	print("✅ Caméra mobile 320x180 configurée dans monde 1920x1080")

func show_dialogue(text: String, character_id: String = "", duration: float = 5.0):
	"""Déléguer au DialogueSystem officiel"""
	if dialogue_system:
		dialogue_system.show_main_dialogue(text, character_id, duration)
		print("✅ Dialogue sent to dialogue_system")
	else:
		push_error("DialogueSystem not found!")

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Espace
		episode_controller.play_episode()
	
	if event.is_action_pressed("ui_select"):  # Entrée
		video_exporter.quick_export_current_episode()
	
	if Input.is_action_just_pressed("ui_cancel"):  # Escape
		background_manager.load_background("castle_room", 0.0)
	
	if Input.is_key_pressed(KEY_D):  # Test dialogue
		show_dialogue("Test dialogue qui suit la caméra partout !", "", 5.0)
	
	# Debug caméra
	if Input.is_key_pressed(KEY_C):
		var camera = $CameraSystem
		print("Camera pos: ", camera.position, " zoom: ", camera.zoom)
		# Déplacer la caméra pour test
		camera.position += Vector2(randf_range(-100, 100), randf_range(-100, 100))
