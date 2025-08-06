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

func _ready():
	print("DialogueSystem initialized - Main dialogue only")
	_setup_main_dialogue()
	visible = false

func _setup_main_dialogue():
	# Panel principal en bas d'écran (style Pokémon)
	main_dialogue_panel = Panel.new()
	main_dialogue_panel.name = "MainDialoguePanel"
	
	# Position : en bas, centré
	main_dialogue_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	main_dialogue_panel.size = Vector2(1700, 200)
	main_dialogue_panel.position = Vector2(110, -220)
	
	# Style panel avec fond noir
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.9)
	style_box.border_width_top = 3
	style_box.border_color = Color.WHITE
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	main_dialogue_panel.add_theme_stylebox_override("panel", style_box)
	
	add_child(main_dialogue_panel)
	
	# Portrait du personnage
	main_portrait = TextureRect.new()
	main_portrait.name = "Portrait"
	main_portrait.size = Vector2(150, 150)
	main_portrait.position = Vector2(25, 25)
	main_portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	main_portrait.visible = false  # Masqué par défaut
	main_dialogue_panel.add_child(main_portrait)
	
	# Texte principal
	main_text_label = RichTextLabel.new()
	main_text_label.name = "MainText"
	main_text_label.position = Vector2(200, 30)
	main_text_label.size = Vector2(1400, 120)
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
	main_continue_arrow.position = Vector2(1620, 160)
	main_continue_arrow.texture = _create_arrow_texture()
	main_continue_arrow.visible = false
	main_dialogue_panel.add_child(main_continue_arrow)
	
	main_dialogue_panel.visible = false
	print("✅ Main dialogue panel created and configured")

# === API PUBLIQUE ===
func show_main_dialogue(text: String, character_id: String = "", duration: float = 5.0):
	print("🗨️ Showing main dialogue: ", text)
	
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
	
	print("✅ Main dialogue shown successfully")

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

func _process(delta):
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
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Dessiner triangle simple blanc
	for y in range(8, 24):
		for x in range(8, 24):
			if x > y - 8 and x < 32 - (y - 8):
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

# === TEST FUNCTION ===
func test_dialogue():
	print("🧪 Testing main dialogue...")
	show_main_dialogue("Test dialogue system!", "", 10.0)
