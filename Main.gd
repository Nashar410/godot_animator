extends Node2D

@onready var episode_controller = $EpisodeController
@onready var video_exporter = $VideoExporter
@onready var background_manager = $BackgroundManager

# Variables dialogue
var dialogue_text_label: RichTextLabel
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
	
	# Tests
	await get_tree().create_timer(1.0).timeout
	background_manager.test_load_castle_room()
	
	await get_tree().create_timer(2.0).timeout
	show_dialogue("Test du dialogue collé à la caméra mobile !", "", 8.0)
	
	# Charger épisode
	episode_controller.load_episode("res://episodes/test_episode.json")

func _process(delta):
	_update_dialogue_position()
	_update_dialogue_typing(delta)

func _configure_animation_stage():
	"""AnimationStage = toute la scène 1920x1080"""
	var animation_stage = $AnimationStage
	
	# L'AnimationStage couvre TOUTE la scène virtuelle
	animation_stage.size = Vector2(1920, 1080)  
	animation_stage.position = Vector2(0, 0)
	
	print("✅ AnimationStage configuré : 1920x1080 (scène complète)")

func _configure_dialogue_stage():
	"""DialogueStage collé à la caméra (25% de 320x180)"""
	var dialogue_stage = $DialogueStage
	
	# Taille = 25% de la vue caméra (320x180)
	dialogue_stage.size = Vector2(320, 45)  # 180 * 0.25 = 45px
	dialogue_stage.visible = false  # Caché par défaut
	
	# Fond du dialogue
	var dialogue_bg = ColorRect.new()
	dialogue_bg.name = "DialogueBG"
	dialogue_bg.size = Vector2(320, 45)
	dialogue_bg.position = Vector2(0, 0)
	dialogue_bg.color = Color(0, 0, 0, 0.85)  # Noir semi-transparent
	
	dialogue_stage.add_child(dialogue_bg)
	
	# Bordure blanche
	var border = ColorRect.new()
	border.name = "Border"
	border.size = Vector2(320, 2)
	border.position = Vector2(0, 0)
	border.color = Color.WHITE
	dialogue_stage.add_child(border)
	
	# Texte du dialogue
	dialogue_text_label = RichTextLabel.new()
	dialogue_text_label.name = "DialogueText"
	dialogue_text_label.size = Vector2(300, 35)  # Marge de 10px
	dialogue_text_label.position = Vector2(10, 5)
	dialogue_text_label.bbcode_enabled = true
	dialogue_text_label.scroll_active = false
	dialogue_text_label.fit_content = true
	dialogue_text_label.add_theme_font_size_override("normal_font_size", 8)  # Petit pour 320px
	dialogue_text_label.add_theme_color_override("default_color", Color.WHITE)
	
	dialogue_stage.add_child(dialogue_text_label)
	
	print("✅ DialogueStage configuré : 320x45 (25% de vue caméra)")

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
	"""Afficher dialogue collé à la caméra"""
	print("💬 Showing dialogue: ", text)
	
	var dialogue_stage = $DialogueStage
	dialogue_stage.visible = true
	
	# Animation de typage
	dialogue_target_text = text
	dialogue_current_text = ""
	is_dialogue_typing = true
	if dialogue_text_label:
		dialogue_text_label.text = ""
	
	# Auto-hide après duration
	if duration > 0:
		var timer = get_tree().create_timer(duration)
		timer.timeout.connect(_hide_dialogue)

func _update_dialogue_typing(delta):
	"""Animation typage"""
	if not is_dialogue_typing or not dialogue_text_label:
		return
	
	# Ajouter caractères progressivement (sans await dans _process)
	var chars_to_add = int(delta / dialogue_typing_speed)
	if chars_to_add > 0:
		var remaining = dialogue_target_text.length() - dialogue_current_text.length()
		chars_to_add = min(chars_to_add, remaining)
		
		if chars_to_add > 0:
			dialogue_current_text += dialogue_target_text.substr(dialogue_current_text.length(), chars_to_add)
			dialogue_text_label.text = dialogue_current_text
		
		if dialogue_current_text.length() >= dialogue_target_text.length():
			is_dialogue_typing = false

func _hide_dialogue():
	"""Masquer dialogue"""
	$DialogueStage.visible = false
	is_dialogue_typing = false

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Espace
		episode_controller.play_episode()
	
	#if event.is_action_pressed("ui_select"):  # Entrée
		#video_exporter.quick_export_current_episode()
	
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
