extends Node2D

@onready var episode_controller = $EpisodeController
@onready var video_exporter = $VideoExporter
@onready var background_manager = $BackgroundManager

# Variables dialogue - TYPE CORRIGÉ
var dialogue_text_label: Label  # Label au lieu de RichTextLabel
var is_dialogue_typing: bool = false
var dialogue_target_text: String = ""
var dialogue_current_text: String = ""
var dialogue_typing_speed: float = 0.03

func _ready():
	add_to_group("main")
	
	print("=== SYSTÈME CAMÉRA MOBILE + DIALOGUE COLLÉ ===")
	
	_configure_animation_stage()
	_configure_dialogue_stage()
	_configure_camera()
	
	# PAS DE BACKGROUND EN DUR - Le JSON s'en charge
	# background_manager.load_background("forest_day", 0.0)  # SUPPRIMÉ
	
	# Charger épisode qui contient le background dans sa timeline
	episode_controller.load_episode("res://episodes/test_episode.json")

func _process(delta):
	_update_dialogue_position()

func _configure_animation_stage():
	"""AnimationStage = toute la scène 1920x1080"""
	var animation_stage = $AnimationStage
	animation_stage.size = Vector2(1920, 1080)  
	animation_stage.position = Vector2(0, 0)
	print("✅ AnimationStage configuré : 1920x1080 (scène complète)")

func _configure_dialogue_stage():
	"""DialogueStage collé à la caméra - VERSION QUI MARCHAIT"""
	var dialogue_stage = $DialogueStage
	
	dialogue_stage.size = Vector2(320, 45)
	dialogue_stage.visible = false
	
	# Fond noir
	var dialogue_bg = ColorRect.new()
	dialogue_bg.name = "DialogueBG"
	dialogue_bg.size = Vector2(320, 45)
	dialogue_bg.position = Vector2(0, 0)
	dialogue_bg.color = Color(0, 0, 0, 0.85)
	dialogue_stage.add_child(dialogue_bg)
	
	# Bordure blanche
	var border = ColorRect.new()
	border.name = "Border"
	border.size = Vector2(320, 2)
	border.position = Vector2(0, 0)
	border.color = Color.WHITE
	dialogue_stage.add_child(border)
	
	# Texte - VERSION SIMPLE QUI MARCHAIT
	dialogue_text_label = Label.new()
	dialogue_text_label.name = "DialogueText"
	dialogue_text_label.size = Vector2(300, 35)
	dialogue_text_label.position = Vector2(10, 5)
	dialogue_text_label.add_theme_font_size_override("font_size", 10)
	dialogue_text_label.add_theme_color_override("font_color", Color.WHITE)
	dialogue_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	dialogue_stage.add_child(dialogue_text_label)
	
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

func _update_dialogue_position():
	"""Coller le DialogueStage en bas de la vue caméra"""
	var camera = $CameraSystem
	var dialogue_stage = $DialogueStage
	
	if not camera or not dialogue_stage or not dialogue_stage.visible:
		return
	
	# Position de la caméra dans le monde
	var camera_world_pos = camera.global_position
	
	# Coins de ce que voit la caméra (320x180)
	var view_half_width = 160   # 320/2
	var view_half_height = 90   # 180/2
	
	var camera_bottom_left = Vector2(
		camera_world_pos.x - view_half_width,
		camera_world_pos.y + view_half_height - 45  # -45 = hauteur du dialogue
	)
	
	# Positionner le dialogue
	dialogue_stage.position = camera_bottom_left

func show_dialogue(text: String, character_id: String = "", duration: float = 5.0):
	"""VERSION QUI MARCHAIT AVANT"""
	print("💬 Main.show_dialogue called with: ", text)
	
	var dialogue_stage = $DialogueStage
	dialogue_stage.visible = true
	
	if dialogue_text_label:
		dialogue_text_label.text = text
		print("✅ Text set in label: ", text)
	else:
		print("❌ dialogue_text_label is null!")
	
	# Auto-hide
	if duration > 0:
		var timer = get_tree().create_timer(duration)
		timer.timeout.connect(_hide_dialogue)

func _hide_dialogue():
	$DialogueStage.visible = false
	print("🚪 Dialogue hidden")
func _debug_dialogue_system():
	"""Debug du système de dialogue"""
	var dialogue_stage = $DialogueStage
	print("=== DIALOGUE DEBUG ===")
	print("DialogueStage exists: ", dialogue_stage != null)
	
	if dialogue_stage:
		print("DialogueStage visible: ", dialogue_stage.visible)
		print("DialogueStage position: ", dialogue_stage.position)
		print("DialogueStage size: ", dialogue_stage.size)
		print("Stage children: ", dialogue_stage.get_children().size())
		for child in dialogue_stage.get_children():
			print("  - ", child.name, " visible=", child.visible)
	
	print("dialogue_text_label exists: ", dialogue_text_label != null)
	if dialogue_text_label:
		print("Label text: '", dialogue_text_label.text, "'")
		print("Label size: ", dialogue_text_label.size)
		print("Label position: ", dialogue_text_label.position)
		print("Label visible: ", dialogue_text_label.visible)

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Espace
		episode_controller.play_episode()
	
	# Export manuel seulement
	if event.is_action_pressed("ui_select"):  # Entrée
		print("Starting manual video export...")
		video_exporter.quick_export_current_episode()
	
	if Input.is_key_pressed(KEY_D):  # Test dialogue avec debug
		_debug_dialogue_system()
		show_dialogue("Test dialogue avec background du JSON !", "", 8.0)
	
	if Input.is_key_pressed(KEY_T):  # Test texte direct
		if dialogue_text_label:
			dialogue_text_label.text = "Test direct réussi!"
			$DialogueStage.visible = true
			print("✅ Direct text test: PASSED")
		else:
			print("❌ Label null pour test direct")
	
	# Debug caméra
	if Input.is_key_pressed(KEY_C):
		var camera = $CameraSystem
		print("Camera pos: ", camera.position)
		camera.position += Vector2(randf_range(-50, 50), randf_range(-50, 50))
