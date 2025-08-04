class_name DialogueBubble extends Node2D

# === TYPES DE BULLES ===
enum BubbleType {
	NONE,
	SMILEY,
	QUICK
}

# === NODES BULLES ===
var smiley_background: NinePatchRect
var smiley_label: Label
var quick_background: ColorRect
var quick_label: Label

# === PARAMÈTRES ===
var current_bubble_type: BubbleType = BubbleType.NONE
var typing_speed: float = 0.01
var is_typing: bool = false
var current_text: String = ""
var target_text: String = ""
var typing_timer: float = 0.0

# === POSITION ===
var bubble_offset: Vector2 = Vector2(0, -80)  # Au-dessus de la tête

func _ready():
	name = "DialogueBubble"
	_setup_smiley_bubble()
	_setup_quick_bubble()
	hide_all_bubbles()

func _setup_smiley_bubble():
	# Container smiley
	smiley_background = NinePatchRect.new()
	smiley_background.name = "SmileyBubble"
	smiley_background.texture = _create_smiley_bubble_texture()
	smiley_background.size = Vector2(80, 60)
	smiley_background.position = bubble_offset + Vector2(-40, 0)  # Centré
	add_child(smiley_background)
	
	# Label emoji
	smiley_label = Label.new()
	smiley_label.name = "SmileyText"
	smiley_label.add_theme_font_size_override("font_size", 36)
	smiley_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	smiley_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	smiley_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	smiley_background.add_child(smiley_label)
	
	smiley_background.visible = false

func _setup_quick_bubble():
	# Container quick
	quick_background = ColorRect.new()
	quick_background.name = "QuickBubble"
	quick_background.color = Color(0, 0, 0, 0.8)
	quick_background.size = Vector2(120, 40)
	quick_background.position = bubble_offset + Vector2(-60, 0)  # Centré
	add_child(quick_background)
	
	# Label texte rapide
	quick_label = Label.new()
	quick_label.name = "QuickText"
	quick_label.add_theme_font_size_override("font_size", 18)
	quick_label.add_theme_color_override("font_color", Color.WHITE)
	quick_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quick_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	quick_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	quick_background.add_child(quick_label)
	
	quick_background.visible = false

# === API PUBLIQUE ===
func show_smiley(emoji: String, duration: float = 2.0):
	hide_all_bubbles()
	
	if not smiley_background:
		push_error("Smiley background not initialized")
		return
	
	current_bubble_type = BubbleType.SMILEY
	target_text = emoji
	
	smiley_label.text = emoji
	smiley_background.visible = true
	
	# Animation bounce
	_animate_bounce(smiley_background)
	
	# Auto-hide
	if duration > 0:
		var timer = get_tree().create_timer(duration)
		timer.timeout.connect(hide_all_bubbles)
	
	print("Smiley shown on ", get_parent().name, ": ", emoji)

func show_quick_reaction(text: String, duration: float = 1.5):
	hide_all_bubbles()
	
	if not quick_background:
		push_error("Quick background not initialized")
		return
	
	current_bubble_type = BubbleType.QUICK
	target_text = text
	current_text = ""
	
	# Ajuster taille selon texte
	var text_width = text.length() * 12 + 30
	text_width = max(text_width, 80)
	quick_background.size = Vector2(text_width, 40)
	quick_background.position = bubble_offset + Vector2(-text_width/2, 0)  # Recentrer
	
	quick_background.visible = true
	
	# Démarrer typage
	_start_typing()
	
	# Auto-hide
	if duration > 0:
		var timer = get_tree().create_timer(duration)
		timer.timeout.connect(hide_all_bubbles)
	
	print("Quick reaction shown on ", get_parent().name, ": ", text)

func hide_all_bubbles():
	if smiley_background:
		smiley_background.visible = false
	if quick_background:
		quick_background.visible = false
	current_bubble_type = BubbleType.NONE
	is_typing = false

# === SYSTÈME DE TYPAGE ===
func _start_typing():
	is_typing = true
	typing_timer = 0.0
	current_text = ""
	quick_label.text = ""

func _process(delta):
	if not is_typing or current_bubble_type != BubbleType.QUICK:
		return
	
	typing_timer += delta
	
	if typing_timer >= typing_speed:
		typing_timer = 0.0
		
		if current_text.length() < target_text.length():
			current_text += target_text[current_text.length()]
			quick_label.text = current_text
		else:
			is_typing = false

# === ANIMATIONS ===
func _animate_bounce(node: Control):
	var tween = create_tween()
	var original_scale = node.scale
	
	node.scale = Vector2.ZERO
	tween.tween_property(node, "scale", original_scale * 1.2, 0.1)
	tween.tween_property(node, "scale", original_scale, 0.1)

# === UTILITAIRES ===
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

# === API POUR CONFIGURATION ===
func set_bubble_offset(offset: Vector2):
	bubble_offset = offset
	smiley_background.position = bubble_offset + Vector2(-40, 0)
	quick_background.position = bubble_offset + Vector2(-quick_background.size.x/2, 0)
