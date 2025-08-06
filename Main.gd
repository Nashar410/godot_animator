extends Node2D

@onready var episode_controller = $EpisodeController
@onready var video_exporter = $VideoExporter
@onready var background_manager = $BackgroundManager
@onready var dialogue_system = $DialogueStage/UIContainer/DialogueSystem

# === SYSTÈME DE DIALOGUE PRINCIPAL ===
var dialogue_text_label: RichTextLabel
var is_dialogue_typing: bool = false
var dialogue_target_text: String = ""
var dialogue_current_text: String = ""
var dialogue_typing_speed: float = 0.05

func _setup_dialogue_system():
	"""Créer le système de dialogue principal"""
	var dialogue_stage = $DialogueStage
	
	# Créer le label de texte principal
	dialogue_text_label = RichTextLabel.new()
	dialogue_text_label.name = "MainDialogueText"
	dialogue_text_label.size = Vector2(460, 58)  # Un peu plus petit que l'étage
	dialogue_text_label.position = Vector2(10, 5)  # Marge de 10px
	dialogue_text_label.bbcode_enabled = true
	dialogue_text_label.scroll_active = false
	dialogue_text_label.fit_content = true
	dialogue_text_label.add_theme_font_size_override("normal_font_size", 12)  # Taille pixel art
	dialogue_text_label.add_theme_color_override("default_color", Color.WHITE)
	
	dialogue_stage.add_child(dialogue_text_label)
	
	print("✅ Dialogue system setup complete")

func show_dialogue(text: String, character_id: String = "", duration: float = 5.0):
	"""Afficher dialogue principal (style Pokémon)"""
	print("🗨️ Showing main dialogue: ", text)
	
	var dialogue_stage = $DialogueStage
	dialogue_stage.visible = true
	
	# Démarrer l'animation de typage
	dialogue_target_text = text
	dialogue_current_text = ""
	is_dialogue_typing = true
	dialogue_text_label.text = ""
	
	# Auto-hide après duration
	if duration > 0:
		var timer = get_tree().create_timer(duration)
		timer.timeout.connect(_hide_dialogue)

func _process(delta):
	_update_dialogue_typing(delta)

func _update_dialogue_typing(delta):
	"""Animation typage pour dialogue principal"""
	if not is_dialogue_typing:
		return
	
	if dialogue_current_text.length() < dialogue_target_text.length():
		# Ajouter un caractère
		dialogue_current_text += dialogue_target_text[dialogue_current_text.length()]
		dialogue_text_label.text = dialogue_current_text
		
		# Attendre avant le prochain caractère
		await get_tree().create_timer(dialogue_typing_speed).timeout
	else:
		is_dialogue_typing = false
		print("✅ Dialogue typing finished")

func _hide_dialogue():
	"""Masquer le dialogue"""
	$DialogueStage.visible = false
	is_dialogue_typing = false
	print("🚪 Dialogue hidden")

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
	"""Configuration 2 étages COHÉRENTS avec caméra pixel art"""
	var animation_stage = $AnimationStage
	var dialogue_stage = $DialogueStage
	
	# DIMENSIONS basées sur la vue caméra (480x270)
	animation_stage.size = Vector2(480, 202)  # 75% de 270 = 202px
	animation_stage.position = Vector2(0, 0)
	
	dialogue_stage.size = Vector2(480, 68)    # 25% de 270 = 68px  
	dialogue_stage.position = Vector2(0, 202)
	dialogue_stage.visible = false
	
	# Fond de debug pour DialogueStage
	var debug_bg = ColorRect.new()
	debug_bg.name = "DebugBG"
	debug_bg.color = Color(0, 0, 0, 0.8)  # Fond noir pour voir le dialogue
	debug_bg.size = dialogue_stage.size
	debug_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_stage.add_child(debug_bg)
	
	print("✅ Pixel Art stages: Animation(480x202) + Dialogue(480x68)")
	print("Total viewport: 480x270 (rendu 1920x1080 avec zoom 4x)")


func _configure_camera():
	"""Caméra pixel art avec limites - null safe"""
	var camera = $CameraSystem
	
	camera.enabled = true
	camera.make_current()
	
	# PIXEL ART : zoom 4x 
	camera.zoom = Vector2(4, 4)
	camera.position = Vector2(240, 135)
	
	# LIMITES 
	camera.limit_left = 240
	camera.limit_right = 1680  
	camera.limit_top = 135
	camera.limit_bottom = 945
	camera.limit_smoothed = true
	
	# UI SCALE - avec vérification
	var ui_container = get_node_or_null("UIContainer")
	if not ui_container:
		ui_container = get_node_or_null("DialogueStage/UIContainer")
	
	if ui_container:
		ui_container.scale = Vector2(4, 4)
		print("✅ UI Container scaled to 4x")
	else:
		print("⚠️ UIContainer not found - check scene structure")
	
	camera.force_update_scroll()
	
	print("✅ Camera Pixel Art configured")

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
