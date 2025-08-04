class_name DialogueSystem extends Control

signal dialogue_finished

# === TYPES DE DIALOGUE ===
enum DialogueType {
	MAIN,    # Style Pokémon - Panel plein écran
	SMILEY,  # Bulle avec émoji/expression
	QUICK    # Micro-réaction rapide
}

var current_character_id: String = ""

# === PARAMÈTRES ===
var typing_speed_main: float = 0.03      # Rapide pour dialogue principal
var typing_speed_quick: float = 0.01     # Ultra-rapide pour réactions
var is_typing: bool = false
var current_text: String = ""
var target_text: String = ""
var typing_timer: float = 0.0

# === NODES DIALOGUE PRINCIPAL ===
var main_dialogue_panel: Panel
var main_text_label: RichTextLabel
var main_portrait: TextureRect
var main_continue_arrow: TextureRect

# === NODES DIALOGUE SMILEY ===
var smiley_container: Control
var smiley_background: NinePatchRect
var smiley_label: Label

# === NODES DIALOGUE RAPIDE ===
var quick_container: Control
var quick_background: ColorRect
var quick_label: Label

# === PARAMÈTRES ACTUELS ===
var current_dialogue_type: DialogueType
var current_character_pos: Vector2
var current_duration: float

func _ready():
	print("DialogueSystem Polish initialized")
	_setup_main_dialogue()
	_setup_smiley_dialogue()
	_setup_quick_dialogue()
	hide()

# === SETUP DIALOGUE PRINCIPAL ===
func _setup_main_dialogue():
	# Panel principal en bas d'écran (style Pokémon)
	main_dialogue_panel = Panel.new()
	main_dialogue_panel.name = "MainDialoguePanel"
	
	# Position : 80% en bas, centré
	main_dialogue_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	main_dialogue_panel.size = Vector2(1700, 200)
	main_dialogue_panel.position = Vector2(110, -220)  # Centré avec marge
	
	# Style panel (fond noir semi-transparent)
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.8)
	style_box.border_width_top = 3
	style_box.border_color = Color.WHITE
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	main_dialogue_panel.add_theme_stylebox_override("panel", style_box)
	
	add_child(main_dialogue_panel)
	
	# Portrait du personnage (gauche)
	main_portrait = TextureRect.new()
	main_portrait.name = "Portrait"
	main_portrait.size = Vector2(150, 150)
	main_portrait.position = Vector2(25, 25)
	main_portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	main_dialogue_panel.add_child(main_portrait)
	
	# Texte principal
	main_text_label = RichTextLabel.new()
	main_text_label.name = "MainText"
	main_text_label.position = Vector2(200, 30)
	main_text_label.size = Vector2(1400, 120)
	main_text_label.bbcode_enabled = true
	main_text_label.scroll_active = false
	main_text_label.fit_content = true
	
	# Style texte
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

# === SETUP DIALOGUE SMILEY ===
func _setup_smiley_dialogue():
	smiley_container = Control.new()
	smiley_container.name = "SmileyContainer"
	smiley_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(smiley_container)
	
	# Bulle smiley
	smiley_background = NinePatchRect.new()
	smiley_background.name = "SmileyBubble"
	smiley_background.texture = _create_smiley_bubble_texture()
	smiley_background.size = Vector2(80, 60)
	smiley_container.add_child(smiley_background)
	
	# Label pour emoji/expression
	smiley_label = Label.new()
	smiley_label.name = "SmileyText"
	smiley_label.add_theme_font_size_override("font_size", 36)
	smiley_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	smiley_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	smiley_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	smiley_background.add_child(smiley_label)
	
	smiley_container.visible = false

# === SETUP DIALOGUE RAPIDE ===
func _setup_quick_dialogue():
	quick_container = Control.new()
	quick_container.name = "QuickContainer"
	quick_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(quick_container)
	
	# Background rapide (semi-transparent)
	quick_background = ColorRect.new()
	quick_background.name = "QuickBackground"
	quick_background.color = Color(0, 0, 0, 0.6)
	quick_background.size = Vector2(120, 40)
	quick_container.add_child(quick_background)
	
	# Texte rapide
	quick_label = Label.new()
	quick_label.name = "QuickText"
	quick_label.add_theme_font_size_override("font_size", 18)
	quick_label.add_theme_color_override("font_color", Color.WHITE)
	quick_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quick_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	quick_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	quick_background.add_child(quick_label)
	
	quick_container.visible = false

func show_dialogue(text: String, character_position: Vector2, style: String = "main", duration: float = 3.0, character_id: String = ""):
	target_text = text
	current_text = ""
	current_character_pos = character_position
	current_duration = duration
	current_character_id = character_id  # NOUVEAU : stocker l'ID
	
	# Déterminer le type de dialogue
	match style:
		"main", "normal":
			current_dialogue_type = DialogueType.MAIN
			_show_main_dialogue(character_id)
		"smiley", "emoji", "expression":
			current_dialogue_type = DialogueType.SMILEY
			_show_smiley_dialogue()
		"quick", "rapid", "reaction":
			current_dialogue_type = DialogueType.QUICK
			_show_quick_dialogue()
		_:
			current_dialogue_type = DialogueType.MAIN
			_show_main_dialogue(character_id)
	
	show()

# === DIALOGUE PRINCIPAL ===
func _show_main_dialogue(character_id: String):
	_hide_all_dialogues()
	main_dialogue_panel.visible = true
	
	# Charger portrait si personnage spécifié
	if character_id != "":
		_load_character_portrait(character_id)
	
	# Démarrer l'animation de typage
	_start_typing(DialogueType.MAIN)
	
	# Auto-hide après duration
	if current_duration > 0:
		var timer = get_tree().create_timer(current_duration)
		timer.timeout.connect(_hide_dialogue)

func _load_character_portrait(character_id: String):
	var portrait_path = "res://assets/characters/" + character_id + "/portrait.png"
	
	if FileAccess.file_exists(portrait_path):
		main_portrait.texture = load(portrait_path)
		main_portrait.visible = true
	else:
		main_portrait.visible = false
		print("Portrait not found for: ", character_id)

# === DIALOGUE SMILEY ===
func _show_smiley_dialogue():
	_hide_all_dialogues()
	
	smiley_label.text = target_text
	smiley_container.visible = true
	
	# Position initiale sera mise à jour par _follow_character_realtime()
	
	# Animation bounce
	_animate_smiley_bounce()
	
	# Auto-hide
	var timer = get_tree().create_timer(current_duration)
	timer.timeout.connect(_hide_dialogue)
	
func _animate_smiley_bounce():
	var tween = create_tween()
	var original_scale = smiley_background.scale
	
	smiley_background.scale = Vector2.ZERO
	tween.tween_property(smiley_background, "scale", original_scale * 1.2, 0.1)
	tween.tween_property(smiley_background, "scale", original_scale, 0.1)

# === DIALOGUE RAPIDE ===
func _show_quick_dialogue():
	_hide_all_dialogues()
	
	# Ajuster taille selon texte
	var text_width = target_text.length() * 12 + 30
	text_width = max(text_width, 80)
	quick_background.size = Vector2(text_width, 40)
	
	quick_container.visible = true
	
	# Position initiale sera mise à jour par _follow_character_realtime()
	
	# Typage ultra-rapide
	_start_typing(DialogueType.QUICK)
	
	# Auto-hide rapide
	var hide_timer = max(current_duration, 1.0)
	var timer = get_tree().create_timer(hide_timer)
	timer.timeout.connect(_hide_dialogue)
# === SYSTÈME DE TYPAGE ===
func _start_typing(dialogue_type: DialogueType):
	is_typing = true
	typing_timer = 0.0
	current_text = ""
	
	# Réinitialiser les textes
	match dialogue_type:
		DialogueType.MAIN:
			main_text_label.text = ""
			main_continue_arrow.visible = false
		DialogueType.QUICK:
			quick_label.text = ""

func _process(delta):
	# Suivi en temps réel des personnages
	if current_character_id != "" and (current_dialogue_type == DialogueType.SMILEY or current_dialogue_type == DialogueType.QUICK):
		_follow_character_realtime()
	
	# Typage existant
	if not is_typing:
		return
	
	typing_timer += delta
	
	var speed = typing_speed_main
	if current_dialogue_type == DialogueType.QUICK:
		speed = typing_speed_quick
	
	if typing_timer >= speed:
		typing_timer = 0.0
		
		if current_text.length() < target_text.length():
			current_text += target_text[current_text.length()]
			
			match current_dialogue_type:
				DialogueType.MAIN:
					main_text_label.text = current_text
				DialogueType.QUICK:
					quick_label.text = current_text
		else:
			is_typing = false
			_on_typing_finished()

func _follow_character_realtime():
	# Récupérer la position actuelle du personnage
	var character_container = get_node("../../CharacterContainer")
	var character = character_container.get_node_or_null(current_character_id)
	
	if not character:
		return
	
	var character_pos = character.global_position
	var animated_sprite = character.get_node_or_null("AnimatedSprite2D")
	
	# Calculer l'offset basé sur la taille du sprite
	var sprite_height = 64  # Défaut pour pixel art
	if animated_sprite and animated_sprite.sprite_frames:
		# Essayer de récupérer la texture de l'animation actuelle
		var current_animation = animated_sprite.animation
		if current_animation != "" and animated_sprite.sprite_frames.has_animation(current_animation):
			var frame_count = animated_sprite.sprite_frames.get_frame_count(current_animation)
			if frame_count > 0:
				var texture = animated_sprite.sprite_frames.get_frame_texture(current_animation, 0)
				if texture:
					sprite_height = texture.get_height() * animated_sprite.scale.y
	
	# Positionner selon le type de dialogue
	if current_dialogue_type == DialogueType.SMILEY:
		var bubble_pos = character_pos + Vector2(-40, -sprite_height - 20)
		smiley_background.global_position = bubble_pos
		
	elif current_dialogue_type == DialogueType.QUICK:
		var text_width = quick_background.size.x
		var quick_pos = character_pos + Vector2(-text_width/2, -sprite_height - 10)
		quick_background.global_position = quick_pos

func _on_typing_finished():
	match current_dialogue_type:
		DialogueType.MAIN:
			main_continue_arrow.visible = true
			_animate_arrow()

func _animate_arrow():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(main_continue_arrow, "modulate:a", 0.3, 0.5)
	tween.tween_property(main_continue_arrow, "modulate:a", 1.0, 0.5)

# === UTILITAIRES ===
func _hide_all_dialogues():
	main_dialogue_panel.visible = false
	smiley_container.visible = false
	quick_container.visible = false

func _hide_dialogue():
	_hide_all_dialogues()
	hide()
	dialogue_finished.emit()

func _create_arrow_texture() -> Texture2D:
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Dessiner triangle simple
	for y in range(8, 24):
		for x in range(8, 24):
			if x > y - 8 and x < 32 - (y - 8):
				image.set_pixel(x, y, Color.WHITE)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _create_smiley_bubble_texture() -> Texture2D:
	var image = Image.create(80, 60, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Bulle blanche avec contour
	for y in range(5, 45):
		for x in range(5, 75):
			if (x - 40) * (x - 40) + (y - 25) * (y - 25) < 625:  # Cercle
				image.set_pixel(x, y, Color.WHITE)
			elif (x - 40) * (x - 40) + (y - 25) * (y - 25) < 700:
				image.set_pixel(x, y, Color.BLACK)
	
	# Petite pointe vers le bas
	for y in range(45, 55):
		for x in range(35, 45):
			if abs(x - 40) < (55 - y):
				image.set_pixel(x, y, Color.WHITE)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

# === API POUR FORCER COMPLÉTION ===
func force_complete_text():
	if is_typing:
		current_text = target_text
		
		match current_dialogue_type:
			DialogueType.MAIN:
				main_text_label.text = current_text
			DialogueType.QUICK:
				quick_label.text = current_text
		
		is_typing = false
		_on_typing_finished()

# === API SPÉCIALISÉES ===
func show_main_dialogue(text: String, character_id: String = "", duration: float = 5.0):
	show_dialogue(text, Vector2.ZERO, "main", duration, character_id)

func show_smiley(emoji: String, character_position: Vector2, duration: float = 2.0):
	show_dialogue(emoji, character_position, "smiley", duration)

func show_quick_reaction(text: String, character_position: Vector2, duration: float = 1.5):
	show_dialogue(text, character_position, "quick", duration)
