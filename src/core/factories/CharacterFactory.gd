class_name CharacterFactory extends Node

const ANIMATION_STATES = {
	"idle": {"frames": 4, "fps": 6},
	"walk": {"frames": 8, "fps": 12}
	#"run": {"frames": 8, "fps": 16},
	#"talk": {"frames": 4, "fps": 8},
	#"attack": {"frames": 6, "fps": 12}
}

const DIRECTIONS = ["n", "e", "s", "w"]

# Préchargement du script d'ombre
const ShadowSystem = preload("res://src/components/shadows/ShadowSystem.gd")

func create_character(character_id: String) -> CharacterBody2D:
	var character = CharacterBody2D.new()
	character.name = character_id
	
	# Pour le chargement des sprites, on utilise toujours le nom de base
	var base_character_id = _extract_base_character_id(character_id)
	
	# Charger la configuration du personnage
	var config = _load_character_config(base_character_id)
	
	# === SYSTÈME D'OMBRE (AJOUTÉ EN PREMIER) ===
	var shadow_system = ShadowSystem.new()
	character.add_child(shadow_system)
	
	# Sprite animé
	var animated_sprite = AnimatedSprite2D.new()
	animated_sprite.name = "AnimatedSprite2D"
	character.add_child(animated_sprite)
	
	# Appliquer le scale depuis la config
	var sprite_scale = config.get("sprite_scale", 1.0)
	animated_sprite.scale = Vector2(sprite_scale, sprite_scale)
	
	# Chargement automatique des animations
	_load_animations(animated_sprite, base_character_id)
	
	# Collision avec taille depuis config
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	var collision_size = config.get("collision_size", {"width": 16, "height": 24})
	shape.size = Vector2(collision_size.width, collision_size.height)
	collision_shape.shape = shape
	collision_shape.name = "CollisionShape2D"
	character.add_child(collision_shape)
	
	# Stocker la config dans le personnage pour usage ultérieur
	character.set_meta("config", config)
	
	print("Character created with shadow: ", character_id)
	return character

func _extract_base_character_id(character_id: String) -> String:
	# Si c'est "alex_1" ou "alex_2", on retourne "hero_alex_default"
	# Sinon on retourne l'ID tel quel
	if character_id.begins_with("alex_"):
		return "hero_alex_default"
	return character_id

func _load_character_config(character_id: String) -> Dictionary:
	var config_path = "res://assets/characters/" + character_id + "/config.json"
	
	if not FileAccess.file_exists(config_path):
		print("No config file found for ", character_id, ", using defaults")
		return {
			"sprite_scale": 1.0,
			"collision_size": {"width": 16, "height": 24},
			"animation_offsets": {},
			"dialogue_offset": {"x": 0, "y": -40},
			"shadow_config": {
				"enabled": true,
				"opacity": 0.4,
				"offset": {"x": 0, "y": 5},
				"scale": {"x": 1.0, "y": 0.6}
			}
		}
	
	var file = FileAccess.open(config_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse config JSON: " + config_path)
		return {}
	
	var config = json.data.get("config", {})
	
	# Ajouter config d'ombre par défaut si manquante
	if not config.has("shadow_config"):
		config.shadow_config = {
			"enabled": true,
			"opacity": 0.4,
			"offset": {"x": 0, "y": 5},
			"scale": {"x": 1.0, "y": 0.6}
		}
	
	return config

func _has_valid_sprites(character_id: String) -> bool:
	var idle_path = "res://assets/characters/" + character_id + "/sprites/idle/s.png"
	return FileAccess.file_exists(idle_path)
	
func _load_animations(animated_sprite: AnimatedSprite2D, character_id: String):
	var character_path = "res://assets/characters/" + character_id + "/"
	
	# Vérifier si le dossier existe
	if not DirAccess.dir_exists_absolute(character_path):
		push_error("Character folder not found: " + character_path)
		return
	
	# Charger les animations disponibles
	for anim_name in ANIMATION_STATES.keys():
		_create_animation(animated_sprite, character_id, anim_name)
	
	# Définir l'animation par défaut
	if animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")

func _create_animation(animated_sprite: AnimatedSprite2D, character_id: String, anim_name: String):
	var sprite_frames = animated_sprite.sprite_frames
	if sprite_frames == null:
		sprite_frames = SpriteFrames.new()
		animated_sprite.sprite_frames = sprite_frames
	
	var anim_path = "res://assets/characters/" + character_id + "/sprites/" + anim_name + "/"
	
	# Vérifier si le dossier d'animation existe
	if not DirAccess.dir_exists_absolute(anim_path):
		print("Animation folder not found (skipping): " + anim_path)
		return
	
	# Créer l'animation pour chaque direction
	for direction in DIRECTIONS:
		var full_anim_name = anim_name + "_" + direction
		sprite_frames.add_animation(full_anim_name)
		
		var anim_config = ANIMATION_STATES[anim_name]
		sprite_frames.set_animation_speed(full_anim_name, anim_config.fps)
		sprite_frames.set_animation_loop(full_anim_name, true)
		
		# Charger les frames
		_load_animation_frames(sprite_frames, full_anim_name, anim_path, direction, anim_config.frames)
	
	# Créer aussi une version sans direction (par défaut = sud)
	if sprite_frames.has_animation(anim_name + "_s"):
		sprite_frames.add_animation(anim_name)
		sprite_frames.set_animation_speed(anim_name, ANIMATION_STATES[anim_name].fps)
		sprite_frames.set_animation_loop(anim_name, true)
		
		# Copier les frames de la direction sud
		var source_anim = anim_name + "_s"
		for i in sprite_frames.get_frame_count(source_anim):
			var texture = sprite_frames.get_frame_texture(source_anim, i)
			sprite_frames.add_frame(anim_name, texture)

func _load_animation_frames(sprite_frames: SpriteFrames, anim_name: String, base_path: String, direction: String, max_frames: int):
	for frame_idx in range(1, max_frames + 1):  # Commencer à 1 au lieu de 0
		var frame_number = str(frame_idx).pad_zeros(2)  # Format 01, 02, 03...
		var frame_path = base_path + direction + "_" + frame_number + ".png"
		
		if FileAccess.file_exists(frame_path):
			var texture = load(frame_path) as Texture2D
			if texture:
				sprite_frames.add_frame(anim_name, texture)
				print("Loaded frame: ", frame_path)
		else:
			print("Frame not found: ", frame_path)
			# Si frame 01 n'existe pas, essayer sans numéro (sprite statique)
			if frame_idx == 1:
				var static_frame_path = base_path + direction + ".png"
				if FileAccess.file_exists(static_frame_path):
					var texture = load(static_frame_path) as Texture2D
					if texture:
						sprite_frames.add_frame(anim_name, texture)
						print("Loaded static sprite: ", static_frame_path)
			break

# === API POUR CONFIGURATION D'OMBRES ===
func configure_character_shadow(character: CharacterBody2D, shadow_config: Dictionary):
	var shadow_system = character.get_node_or_null("ShadowSystem")
	if not shadow_system:
		return
	
	if shadow_config.has("opacity"):
		shadow_system.set_shadow_opacity(shadow_config.opacity)
	
	if shadow_config.has("offset"):
		var offset = Vector2(shadow_config.offset.x, shadow_config.offset.y)
		shadow_system.set_shadow_offset(offset)
	
	if shadow_config.has("scale"):
		var scale = Vector2(shadow_config.scale.x, shadow_config.scale.y)
		shadow_system.set_shadow_scale(scale)
	
	if shadow_config.get("enabled", true) == false:
		shadow_system.hide_shadow()
