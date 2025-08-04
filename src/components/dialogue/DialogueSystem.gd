class_name DialogueSystem extends Control

signal dialogue_finished

var typing_speed: float = 0.05
var is_typing: bool = false
var current_text: String = ""
var target_text: String = ""
var typing_timer: float = 0.0

# Nodes UI
var bubble_container: Control
var bubble_background: NinePatchRect
var text_label: RichTextLabel
var arrow_indicator: TextureRect

# Styles de bulles
var bubble_styles = {
	"normal": null,  # Sera chargé depuis les assets
	"shout": null,
	"thought": null
}

func _ready():
	print("DialogueSystem initialized")
	_setup_ui()
	hide()  # Caché par défaut

func _setup_ui():
	# Container principal pour la bulle
	bubble_container = Control.new()
	bubble_container.name = "BubbleContainer"
	bubble_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bubble_container)
	
	# Background de la bulle (NinePatch pour adaptation automatique)
	bubble_background = NinePatchRect.new()
	bubble_background.name = "BubbleBackground"
	bubble_background.texture = _load_bubble_texture("normal")
	bubble_container.add_child(bubble_background)
	
	# Label pour le texte
	text_label = RichTextLabel.new()
	text_label.name = "TextLabel"
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.scroll_active = false
	bubble_background.add_child(text_label)
	
	# Flèche indicatrice (fin de dialogue)
	arrow_indicator = TextureRect.new()
	arrow_indicator.name = "ArrowIndicator"
	arrow_indicator.texture = _load_arrow_texture()
	arrow_indicator.visible = false
	bubble_background.add_child(arrow_indicator)
	
	_configure_text_style()

func _configure_text_style():
	# Style du texte pour pixel art
	text_label.add_theme_font_size_override("normal_font_size", 16)
	text_label.add_theme_color_override("default_color", Color.BLACK)
	
	# Marges internes
	text_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text_label.position = Vector2(12, 8)
	text_label.size = bubble_background.size - Vector2(24, 16)

func _load_bubble_texture(style: String) -> Texture2D:
	var path = "res://assets/ui/bubble_" + style + ".png"
	if FileAccess.file_exists(path):
		return load(path)
	else:
		# Texture par défaut temporaire
		var placeholder = ImageTexture.new()
		var image = Image.create(64, 48, false, Image.FORMAT_RGBA8)
		image.fill(Color(1, 1, 1, 0.9))  # Blanc semi-transparent
		placeholder.set_image(image)
		return placeholder

func _load_arrow_texture() -> Texture2D:
	var path = "res://assets/ui/dialogue_arrow.png"
	if FileAccess.file_exists(path):
		return load(path)
	else:
		# Texture par défaut temporaire
		var placeholder = ImageTexture.new()
		var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		image.fill(Color.BLACK)
		placeholder.set_image(image)
		return placeholder

func show_dialogue(text: String, character_position: Vector2, style: String = "normal", duration: float = 3.0):
	target_text = text
	current_text = ""
	
	# Positionner la bulle
	_position_bubble(character_position)
	
	# Appliquer le style
	_apply_bubble_style(style)
	
	# Démarrer l'animation de typage
	_start_typing()
	
	# Timer pour auto-hide
	if duration > 0:
		var timer = get_tree().create_timer(duration)
		timer.timeout.connect(_hide_dialogue)
	
	show()

func _position_bubble(character_pos: Vector2):
	# Convertir position monde vers position écran
	var camera = get_viewport().get_camera_2d()
	var screen_pos = character_pos
	
	if camera:
		var viewport_size_v2 = Vector2(get_viewport().size)  # Convertir Vector2i en Vector2
		screen_pos = character_pos - camera.global_position + viewport_size_v2 / 2
	
	# Position de base au-dessus du personnage
	var bubble_pos = screen_pos + Vector2(0, -60)
	
	# Calculer taille de la bulle basée sur le texte
	var estimated_width = target_text.length() * 8 + 24  # Approximation
	estimated_width = min(estimated_width, 300)  # Max width
	var estimated_height = 48
	
	# Ajustements pour rester à l'écran
	var viewport_size = Vector2(get_viewport().size)  # Convertir Vector2i en Vector2
	
	if bubble_pos.x + estimated_width > viewport_size.x:
		bubble_pos.x = viewport_size.x - estimated_width - 10
	if bubble_pos.x < 10:
		bubble_pos.x = 10
	if bubble_pos.y < 10:
		bubble_pos.y = screen_pos.y + 40  # En dessous si pas de place au-dessus
	
	# Appliquer position et taille
	bubble_container.position = bubble_pos
	bubble_background.size = Vector2(estimated_width, estimated_height)
	text_label.size = Vector2(estimated_width - 24, estimated_height - 16)

func _apply_bubble_style(style: String):
	# Changer texture selon le style
	var texture = _load_bubble_texture(style)
	bubble_background.texture = texture
	
	# Ajustements spécifiques par style
	match style:
		"shout":
			text_label.add_theme_color_override("default_color", Color.RED)
		"thought":
			text_label.add_theme_color_override("default_color", Color.BLUE)
		_:
			text_label.add_theme_color_override("default_color", Color.BLACK)

func _start_typing():
	is_typing = true
	typing_timer = 0.0
	text_label.text = ""
	arrow_indicator.visible = false

func _process(delta):
	if not is_typing:
		return
	
	typing_timer += delta
	
	if typing_timer >= typing_speed:
		typing_timer = 0.0
		
		if current_text.length() < target_text.length():
			current_text += target_text[current_text.length()]
			text_label.text = current_text
		else:
			# Fin du typage
			is_typing = false
			arrow_indicator.visible = true
			_position_arrow()

func _position_arrow():
	# Positionner la flèche en bas à droite de la bulle
	arrow_indicator.position = Vector2(
		bubble_background.size.x - 24,
		bubble_background.size.y - 20
	)

func _hide_dialogue():
	hide()
	dialogue_finished.emit()

func force_complete_text():
	if is_typing:
		current_text = target_text
		text_label.text = current_text
		is_typing = false
		arrow_indicator.visible = true
		_position_arrow()
