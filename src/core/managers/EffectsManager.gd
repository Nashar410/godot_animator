class_name EffectsManager extends Node

@onready var effects_container = get_node("../AnimationStage/SceneContainer/EffectsContainer")

# Cache des effets
var effect_templates: Dictionary = {}
var active_effects: Dictionary = {}

# Pool d'effets réutilisables
var particle_pool: Array[GPUParticles2D] = []
var sprite_pool: Array[AnimatedSprite2D] = []

func _ready():
	print("EffectsManager initialized")
	_create_effect_pools()
	_load_effect_templates()

func _create_effect_pools():
	# Pool de particules
	for i in range(20):
		var particles = GPUParticles2D.new()
		particles.emitting = false
		particles.visible = false
		effects_container.add_child(particles)
		particle_pool.append(particles)
	
	# Pool de sprites animés
	for i in range(10):
		var sprite = AnimatedSprite2D.new()
		sprite.visible = false
		effects_container.add_child(sprite)
		sprite_pool.append(sprite)
	
	print("Effects pools created: ", particle_pool.size(), " particles, ", sprite_pool.size(), " sprites")

func _load_effect_templates():
	# Templates d'effets prédéfinis
	effect_templates = {
		"rain": {
			"type": "particles",
			"texture": "res://assets/effects/raindrop.png",
			"amount": 500,
			"emission_rate": 100.0,
			"lifetime": 3.0,
			"direction": Vector2(0, 1),
			"spread": 10.0,
			"speed": {"min": 200, "max": 400},
			"gravity": Vector2(0, 500),
			"scale": {"min": 0.5, "max": 1.0}
		},
		"snow": {
			"type": "particles", 
			"texture": "res://assets/effects/snowflake.png",
			"amount": 300,
			"emission_rate": 50.0,
			"lifetime": 8.0,
			"direction": Vector2(0, 1),
			"spread": 15.0,
			"speed": {"min": 50, "max": 150},
			"gravity": Vector2(0, 100),
			"scale": {"min": 0.3, "max": 0.8}
		},
		"fire": {
			"type": "particles",
			"texture": "res://assets/effects/flame.png", 
			"amount": 100,
			"emission_rate": 30.0,
			"lifetime": 2.0,
			"direction": Vector2(0, -1),
			"spread": 30.0,
			"speed": {"min": 50, "max": 150},
			"gravity": Vector2(0, -200),
			"scale": {"min": 0.5, "max": 1.5}
		},
		"explosion": {
			"type": "animated_sprite",
			"spritesheet": "res://assets/effects/explosion/",
			"frames": 8,
			"fps": 15,
			"scale": 2.0,
			"duration": 0.5
		},
		"magic_sparkles": {
			"type": "particles",
			"texture": "res://assets/effects/sparkle.png",
			"amount": 50,
			"emission_rate": 25.0,
			"lifetime": 2.0,
			"direction": Vector2(0, 0),
			"spread": 360.0,
			"speed": {"min": 30, "max": 100},
			"gravity": Vector2(0, 0),
			"scale": {"min": 0.2, "max": 0.6}
		}
	}

# === FONCTIONS PRINCIPALES ===

func play_effect(effect_id: String, position: Vector2, params: Dictionary = {}) -> String:
	var template = effect_templates.get(effect_id, {})
	if template.is_empty():
		push_error("Effect template not found: " + effect_id)
		return ""
	
	# Générer ID unique pour cette instance
	var instance_id = effect_id + "_" + str(Time.get_ticks_msec())
	
	match template.type:
		"particles":
			_create_particle_effect(instance_id, template, position, params)
		"animated_sprite":
			_create_sprite_effect(instance_id, template, position, params)
	
	print("Effect started: ", instance_id, " at ", position)
	return instance_id

func stop_effect(instance_id: String):
	if not active_effects.has(instance_id):
		return
	
	var effect_data = active_effects[instance_id]
	var effect_node = effect_data.node
	
	if effect_node and is_instance_valid(effect_node):
		if effect_node is GPUParticles2D:
			effect_node.emitting = false
			# Retourner au pool après que les particules s'éteignent
			var timer = get_tree().create_timer(effect_node.lifetime)
			timer.timeout.connect(func(): _return_particle_to_pool(effect_node))
		else:
			effect_node.visible = false
			_return_sprite_to_pool(effect_node)
	
	active_effects.erase(instance_id)
	print("Effect stopped: ", instance_id)

# === CRÉATION D'EFFETS ===
func _create_particle_effect(instance_id: String, template: Dictionary, position: Vector2, params: Dictionary):
	var particles = _get_particle_from_pool()
	if not particles:
		push_error("No available particles in pool")
		return
	
	# Configuration de base
	particles.position = position
	particles.visible = true
	particles.emitting = true
	
	# Configuration directe des propriétés GPUParticles2D
	particles.amount = template.amount
	particles.lifetime = template.lifetime
	
	# Texture directement sur GPUParticles2D
	var texture = _load_effect_texture(template.texture)
	particles.texture = texture
	
	# Créer et configurer le ParticleProcessMaterial
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(template.direction.x, template.direction.y, 0)
	material.spread = template.spread
	material.initial_velocity_min = template.speed.min
	material.initial_velocity_max = template.speed.max
	material.gravity = Vector3(template.gravity.x, template.gravity.y, 0)
	material.scale_min = template.scale.min
	material.scale_max = template.scale.max
	
	# Couleur selon l'effet
	match instance_id.split("_")[0]:
		"rain":
			material.color = Color.CYAN
		"snow":
			material.color = Color.WHITE
		"fire":
			material.color = Color.ORANGE_RED
		"magic_sparkles":
			material.color = Color.YELLOW
		_:
			material.color = Color.WHITE
	
	# Appliquer le material
	particles.process_material = material
	
	# Overrides depuis params
	if params.has("intensity"):
		particles.amount = int(template.amount * params.intensity)
	
	# Sauvegarder l'effet actif
	active_effects[instance_id] = {
		"node": particles,
		"type": "particles",
		"template": template
	}
	
	print("Particle effect created: ", instance_id, " with ", particles.amount, " particles")

func _create_sprite_effect(instance_id: String, template: Dictionary, position: Vector2, params: Dictionary):
	var sprite = _get_sprite_from_pool()
	if not sprite:
		push_error("No available sprites in pool")
		return
	
	sprite.position = position
	sprite.visible = true
	sprite.scale = Vector2(template.get("scale", 1.0), template.get("scale", 1.0))
	
	# Charger l'animation
	_load_sprite_animation(sprite, template)
	
	# Jouer l'animation
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("default"):
		sprite.play("default")
	
	# Auto-cleanup après duration
	var duration = template.get("duration", 2.0)
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func(): stop_effect(instance_id))
	
	# Sauvegarder l'effet actif
	active_effects[instance_id] = {
		"node": sprite,
		"type": "sprite",
		"template": template
	}

# === GESTION DES POOLS ===

func _get_particle_from_pool() -> GPUParticles2D:
	for particles in particle_pool:
		if not particles.emitting and not particles.visible:
			return particles
	return null

func _get_sprite_from_pool() -> AnimatedSprite2D:
	for sprite in sprite_pool:
		if not sprite.visible:
			return sprite
	return null

func _return_particle_to_pool(particles: GPUParticles2D):
	particles.emitting = false
	particles.visible = false
	particles.amount = 0

func _return_sprite_to_pool(sprite: AnimatedSprite2D):
	sprite.stop()
	sprite.visible = false

# === UTILITAIRES ===

func _load_effect_texture(path: String) -> Texture2D:
	if FileAccess.file_exists(path):
		return load(path)
	else:
		# Texture par défaut
		var placeholder = ImageTexture.new()
		var image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		placeholder.set_image(image)
		return placeholder

func _load_sprite_animation(sprite: AnimatedSprite2D, template: Dictionary):
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("default")
	
	var base_path = template.spritesheet
	var frame_count = template.get("frames", 4)
	var fps = template.get("fps", 10)
	
	sprite_frames.set_animation_speed("default", fps)
	
	for i in range(frame_count):
		var frame_path = base_path + "frame_" + str(i).pad_zeros(2) + ".png"
		var texture = _load_effect_texture(frame_path)
		sprite_frames.add_frame("default", texture)
	
	sprite.sprite_frames = sprite_frames

# === FONCTIONS TIMELINE ===

func start_weather(weather_type: String, intensity: float = 1.0) -> String:
	return play_effect(weather_type, Vector2(960, -100), {"intensity": intensity})

func stop_weather(weather_type: String):
	# Arrêter tous les effets de ce type
	var to_remove = []
	for instance_id in active_effects.keys():
		if instance_id.begins_with(weather_type):
			to_remove.append(instance_id)
	
	for instance_id in to_remove:
		stop_effect(instance_id)

func screen_flash(color: Color, duration: float = 0.2):
	var flash_rect = ColorRect.new()
	flash_rect.color = color
	flash_rect.size = Vector2(1920, 1080)
	flash_rect.modulate.a = 0.8
	get_tree().current_scene.add_child(flash_rect)
	
	var tween = create_tween()
	tween.tween_property(flash_rect, "modulate:a", 0.0, duration)
	tween.tween_callback(func(): flash_rect.queue_free())
	
