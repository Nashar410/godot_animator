# À placer dans : src/components/shadows/ShadowSystem.gd

class_name ShadowSystem extends Node2D

# === PARAMÈTRES OMBRES ===
var shadow_offset: Vector2 = Vector2(0, 5)      # Décalage de l'ombre
var shadow_opacity: float = 0.4                  # Transparence
var shadow_scale: Vector2 = Vector2(1.0, 0.6)   # Échelle (aplatie verticalement)
var shadow_color: Color = Color(0, 0, 0, 0.4)   # Couleur de l'ombre

# Nodes
var shadow_sprite: Sprite2D
var parent_character: Node2D

func _ready():
	name = "ShadowSystem"
	
	# Créer le sprite d'ombre
	shadow_sprite = Sprite2D.new()
	shadow_sprite.name = "Shadow"
	shadow_sprite.modulate = shadow_color
	shadow_sprite.scale = shadow_scale
	
	# Z-index pour être derrière le personnage
	shadow_sprite.z_index = -1
	
	add_child(shadow_sprite)
	
	# Trouver le personnage parent
	parent_character = get_parent()
	
	if parent_character:
		_setup_shadow()

func _setup_shadow():
	# Récupérer le sprite principal du personnage
	var main_sprite = parent_character.get_node_or_null("AnimatedSprite2D")
	
	if main_sprite:
		# NOUVEAU : Adapter l'échelle de l'ombre au sprite
		shadow_scale = Vector2(main_sprite.scale.x, main_sprite.scale.y * 0.6)
		shadow_sprite.scale = shadow_scale
		
		# Méthode 1: Essayer de charger une texture d'ombre personnalisée
		_try_load_custom_shadow()
		
		# Méthode 2: Si pas d'ombre personnalisée, utiliser le sprite du personnage
		if not shadow_sprite.texture:
			_create_shadow_from_sprite(main_sprite)
		
		# Positionner l'ombre
		shadow_sprite.position = shadow_offset
		
		print("Shadow created for: ", parent_character.name)

func _try_load_custom_shadow():
	# Essayer de charger shadow.png depuis le dossier du personnage
	var character_name = parent_character.name
	
	# Extraction du nom de base (alex_1 -> hero_alex_default)
	var base_name = _extract_base_character_name(character_name)
	
	var shadow_paths = [
		"res://assets/characters/" + base_name + "/shadow.png",
		"res://assets/characters/" + base_name + "/small_shadow.png",
		"res://assets/effects/shadows/generic_shadow.png"
	]
	
	for path in shadow_paths:
		if FileAccess.file_exists(path):
			shadow_sprite.texture = load(path)
			print("Custom shadow loaded: ", path)
			return
	
	print("No custom shadow found, will use sprite-based shadow")

func _extract_base_character_name(character_id: String) -> String:
	# Même logique que dans CharacterFactory
	if character_id.begins_with("alex_"):
		return "hero_alex_default"
	return character_id

func _create_shadow_from_sprite(main_sprite: AnimatedSprite2D):
	# Utiliser la texture actuelle du sprite comme base pour l'ombre
	if main_sprite.sprite_frames and main_sprite.animation:
		var current_frame = main_sprite.frame
		var current_animation = main_sprite.animation
		
		if main_sprite.sprite_frames.has_animation(current_animation):
			var frame_count = main_sprite.sprite_frames.get_frame_count(current_animation)
			if current_frame < frame_count:
				var texture = main_sprite.sprite_frames.get_frame_texture(current_animation, current_frame)
				if texture:
					shadow_sprite.texture = texture
					print("Shadow created from sprite texture")

func _process(_delta):
	# Synchroniser l'ombre avec le sprite principal si nécessaire
	_update_shadow_texture()

func _update_shadow_texture():
	# Mettre à jour la texture de l'ombre si le personnage change d'animation
	var main_sprite = parent_character.get_node_or_null("AnimatedSprite2D")
	
	if main_sprite and not _has_custom_shadow():
		var current_texture = _get_current_sprite_texture(main_sprite)
		if current_texture != shadow_sprite.texture:
			shadow_sprite.texture = current_texture

func _has_custom_shadow() -> bool:
	# Vérifier si on utilise une ombre personnalisée
	if not shadow_sprite.texture:
		return false
	
	var texture_path = shadow_sprite.texture.resource_path
	return texture_path.contains("shadow.png") or texture_path.contains("shadows/")

func _get_current_sprite_texture(main_sprite: AnimatedSprite2D) -> Texture2D:
	if main_sprite.sprite_frames and main_sprite.animation:
		var current_frame = main_sprite.frame
		var current_animation = main_sprite.animation
		
		if main_sprite.sprite_frames.has_animation(current_animation):
			var frame_count = main_sprite.sprite_frames.get_frame_count(current_animation)
			if current_frame < frame_count:
				return main_sprite.sprite_frames.get_frame_texture(current_animation, current_frame)
	
	return null

# === API PUBLIQUE ===
func set_shadow_opacity(opacity: float):
	shadow_opacity = opacity
	shadow_color.a = opacity
	shadow_sprite.modulate = shadow_color

func set_shadow_offset(offset: Vector2):
	shadow_offset = offset
	shadow_sprite.position = offset

func set_shadow_scale(scale: Vector2):
	shadow_scale = scale
	shadow_sprite.scale = scale

func hide_shadow():
	shadow_sprite.visible = false

func show_shadow():
	shadow_sprite.visible = true
