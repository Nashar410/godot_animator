class_name DialogueSystem extends Control

signal dialogue_finished

# === PARAMÈTRES ===
var typing_speed_main: float = 0.03
var is_typing: bool = false
var current_text: String = ""
var target_text: String = ""
var typing_timer: float = 0.0
var current_duration: float

# === NODES DIALOGUE PRINCIPAL ===
var main_dialogue_panel: Panel
var main_text_label: RichTextLabel
var main_portrait: TextureRect
var main_continue_arrow: TextureRect

# === CAMÉRA MOBILE ===
@onready var camera_system = get_node("../../../CameraSystem")

func _ready():
	print("DialogueSystem initialized - Mobile camera support")
	_setup_main_dialogue()
	visible = false

func _process(_delta):
	# Mettre à jour position selon caméra
	_update_dialogue_position()
	
	# Animation typage
	if is_typing:
		_update_typing(_delta)

func _setup_main_dialogue():
	# Panel principal qui couvre 25% bas d'écran
	main_dialogue_panel = Panel.new()
	main_dialogue_panel.name = "MainDialoguePanel"
	
	# Taille sera mise à jour dans _update_dialogue_position()
	main_dialogue_panel.size = Vector2(1920, 270)  # 1080 * 0.25 = 270
	main_dialogue_panel.position = Vector2(0, 810)   # 1080 - 270 = 810
	
	# Style panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.85)
	style_box.border_width_top = 3
	style_box.border_color = Color.WHITE
	main_dialogue_panel.add_theme_stylebox_override("panel", style_box)
	
	add_child(main_dialogue_panel)
	
	# Portrait (optionnel)
	main_portrait = TextureRect.new()
	main_portrait.name = "Portrait"
	main_portrait.size = Vector2(100, 100)
	main_portrait.position = Vector2(20, 20)
	main_portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	main_portrait.visible = false
	main_dialogue_panel.add_child(main_portrait)
	
	# Texte principal
	main_text_label = RichTextLabel.new()
	main_text_label.name = "MainText"
	main_text_label.position = Vector2(140, 30)
	main_text_label.size = Vector2(1700, 200)
	main_text_label.bbcode_enabled = true
	main_text_label.scroll_active = false
	main_text_label.fit_content = true
	main_text_label.add_theme_font_size_override("normal_font_size", 24)
	main_text_label.add_theme_color_override("default_color", Color.WHITE)
	main_dialogue_panel.add_child(main_text_label)
	
	# Flèche "continuer"
	main_continue_arrow = TextureRect.new()
	main_continue_arrow.name = "ContinueArrow"
	main_continue_arrow.size = Vector2(32, 32)
	main_continue_arrow.position = Vector2(1850, 220)
	main_continue_arrow.texture = _create_arrow_texture()
	main_continue_arrow.visible = false
	main_dialogue_panel.add_child(main_continue_arrow)
	
	main_dialogue_panel.visible = false
	print("✅ Full-screen dialogue panel created: 25% bottom screen")
	
	
func _update_dialogue_position():
	"""Coller le dialogue en bas de la vue caméra - COORDONNÉES ÉCRAN"""
	if not camera_system or not main_dialogue_panel or not main_dialogue_panel.visible:
		return
	
	# Récupérer la taille de viewport
	var viewport = get_viewport()
	var screen_size = viewport.get_visible_rect().size
	
	# Le dialogue doit être en bas d'écran (position écran, pas monde)
	# 25% de hauteur d'écran = screen_size.y * 0.25
	var dialogue_height = screen_size.y * 0.25
	var dialogue_width = screen_size.x  # Toute la largeur
	
	# Position en bas d'écran
	main_dialogue_panel.size = Vector2(dialogue_width, dialogue_height)
	main_dialogue_panel.position = Vector2(0, screen_size.y - dialogue_height)
	
	# Adapter taille des éléments internes
	if main_text_label:
		main_text_label.size = Vector2(dialogue_width - 100, dialogue_height - 20)
		main_text_label.position = Vector2(50, 10)
	
	if main_continue_arrow:
		main_continue_arrow.position = Vector2(dialogue_width - 30, dialogue_height - 25)
		
# === API PUBLIQUE ===
func show_main_dialogue(text: String, character_id: String = "", duration: float = 5.0):
	print("🗨️ Showing mobile dialogue: ", text)
	
	target_text = text
	current_text = ""
	current_duration = duration
	
	_hide_all_dialogues()
	
	# Afficher le panel
	main_dialogue_panel.visible = true
	visible = true
	
	# Charger portrait si personnage spécifié
	if character_id != "":
		_load_character_portrait(character_id)
	
	# Démarrer l'animation de typage
	_start_typing()
	
	# Auto-hide après duration
	if current_duration > 0:
		var timer = get_tree().create_timer(current_duration)
		timer.timeout.connect(_hide_dialogue)
	
	print("✅ Mobile dialogue shown successfully")

# === SYSTÈME DE TYPAGE ===
func _start_typing():
	is_typing = true
	typing_timer = 0.0
	current_text = ""
	
	if main_text_label:
		main_text_label.text = ""
	if main_continue_arrow:
		main_continue_arrow.visible = false
	
	print("⌨️ Started typing animation")

func _update_typing(delta):
	if not is_typing:
		return
	
	typing_timer += delta
	
	if typing_timer >= typing_speed_main:
		typing_timer = 0.0
		
		if current_text.length() < target_text.length():
			current_text += target_text[current_text.length()]
			if main_text_label:
				main_text_label.text = current_text
		else:
			is_typing = false
			_on_typing_finished()

func _on_typing_finished():
	print("✅ Typing finished")
	if main_continue_arrow:
		main_continue_arrow.visible = true
		_animate_arrow()

func _animate_arrow():
	if not main_continue_arrow:
		return
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(main_continue_arrow, "modulate:a", 0.3, 0.5)
	tween.tween_property(main_continue_arrow, "modulate:a", 1.0, 0.5)

# === UTILITAIRES ===
func _hide_all_dialogues():
	if main_dialogue_panel:
		main_dialogue_panel.visible = false

func _hide_dialogue():
	print("🚪 Hiding dialogue")
	_hide_all_dialogues()
	visible = false
	dialogue_finished.emit()

func _load_character_portrait(character_id: String):
	if not main_portrait:
		return
		
	var portrait_path = "res://assets/characters/" + character_id + "/portrait.png"
	
	if FileAccess.file_exists(portrait_path):
		main_portrait.texture = load(portrait_path)
		main_portrait.visible = true
		print("✅ Portrait loaded: ", portrait_path)
	else:
		main_portrait.visible = false
		print("⚠️ Portrait not found for: ", character_id)

func _create_arrow_texture() -> Texture2D:
	var image = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Triangle blanc compact
	for y in range(3, 9):
		for x in range(3, 9):
			if x > y - 3 and x < 12 - (y - 3):
				image.set_pixel(x, y, Color.WHITE)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

# === API POUR FORCER COMPLÉTION ===
func force_complete_text():
	if is_typing:
		current_text = target_text
		if main_text_label:
			main_text_label.text = current_text
		is_typing = false
		_on_typing_finished()
