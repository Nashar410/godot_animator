class_name TimelineManager extends Node

signal event_executed(event: Dictionary)
signal timeline_finished

var current_time: float = 0.0
var events_queue: Array = []
var is_playing: bool = false
var timeline_data: Array = []

@onready var character_factory = get_node("../CharacterFactory")
@onready var character_container = get_node("../AnimationStage/SceneContainer/CharacterContainer")
@onready var dialogue_system = get_node("../DialogueStage/UIContainer/DialogueSystem")
@onready var audio_manager = get_node("../AudioSystem")
@onready var camera_controller = get_node("../CameraSystem")
@onready var background_manager = get_node("../BackgroundManager")
@onready var effects_manager = get_node("../EffectsManager")

func _ready():
	print("TimelineManager initialized")

func _process(delta):
	if not is_playing:
		return
	
	current_time += delta
	_process_events()

func load_timeline(timeline: Array):
	timeline_data = timeline.duplicate()
	events_queue.clear()
	
	# Préparer la queue d'événements
	for event in timeline_data:
		event["processed"] = false
		events_queue.append(event)
	
	# Trier par temps
	events_queue.sort_custom(_sort_events_by_time)
	
	print("Timeline loaded with ", events_queue.size(), " events")

func _sort_events_by_time(a, b):
	return a.time < b.time

func play_timeline():
	if events_queue.is_empty():
		push_error("No timeline loaded")
		return
	
	current_time = 0.0
	is_playing = true
	
	# Reset tous les événements
	for event in events_queue:
		event.processed = false
	
	print("Timeline playback started")

func stop_timeline():
	is_playing = false
	current_time = 0.0
	print("Timeline playback stopped")

func _process_events():
	var all_processed = true
	
	for event in events_queue:
		if event.processed:
			continue
		
		all_processed = false
		
		if event.time <= current_time:
			_execute_event(event)
			event.processed = true
			event_executed.emit(event)
	
	# Vérifier si timeline terminée
	if all_processed and is_playing:
		is_playing = false
		timeline_finished.emit()

func _execute_event(event: Dictionary):
	print("Executing event: ", event.type, " at time ", event.time)
	
	match event.type:
		"character_enter":
			_handle_character_enter(event)
		"character_move":
			_handle_character_move(event)
		"character_exit":
			_handle_character_exit(event)
		"dialogue":
			_handle_dialogue(event)
		"dialogue_main":
			_handle_dialogue_main(event)
		"dialogue_smiley":
			_handle_dialogue_smiley(event)
		"dialogue_quick":
			_handle_dialogue_quick(event)
		"play_music":
			_handle_play_music(event)
		"stop_music":
			_handle_stop_music(event)
		"play_sfx":
			_handle_play_sfx(event)
		"play_voice":
			_handle_play_voice(event)
		"camera_move":
			_handle_camera_move(event)
		"camera_zoom":
			_handle_camera_zoom(event)
		"camera_follow":
			_handle_camera_follow(event)
		"camera_stop_follow":
			_handle_camera_stop_follow(event)
		"camera_shake":
			_handle_camera_shake(event)
		"camera_pan":
			_handle_camera_pan(event)
		"change_background":
			_handle_change_background(event)
		"time_of_day":
			_handle_time_of_day(event)
		"play_effect":
			_handle_play_effect(event)
		"stop_effect":
			_handle_stop_effect(event)
		"start_weather":
			_handle_start_weather(event)
		"stop_weather":
			_handle_stop_weather(event)
		"screen_flash":
			_handle_screen_flash(event)
		_:
			print("Unknown event type: ", event.type)

# === NOUVEAUX HANDLERS DE DIALOGUE ===

func _handle_dialogue_main(event: Dictionary):
	var data = event.data
	var character_id = data.get("character", "")
	var text = data.text
	var duration = data.get("duration", 5.0)
	
	# Jouer la voix si spécifiée
	if data.has("voice"):
		audio_manager.play_voice("voices/" + data.voice)
	
	# Afficher le dialogue principal
	dialogue_system.show_main_dialogue(text, character_id, duration)
	
	print("Main dialogue shown: ", text)

func _handle_dialogue_smiley(event: Dictionary):
	var data = event.data
	var character_id = data.character
	var character = character_container.get_node_or_null(character_id)
	
	if not character:
		push_error("Character not found for smiley dialogue: " + character_id)
		return
	
	# Trouver la bulle du personnage
	var dialogue_bubble = character.get_node_or_null("DialogueBubble")
	if not dialogue_bubble:
		push_error("DialogueBubble not found on character: " + character_id)
		return
	
	var emoji = data.emoji
	var duration = data.get("duration", 2.0)
	
	# Afficher via la bulle du personnage
	dialogue_bubble.show_smiley(emoji, duration)
	
	print("Smiley shown: ", character_id, " says: ", emoji)
	
func _handle_dialogue_quick(event: Dictionary):
	var data = event.data
	var character_id = data.character
	var character = character_container.get_node_or_null(character_id)
	
	if not character:
		push_error("Character not found for quick dialogue: " + character_id)
		return
	
	# Trouver la bulle du personnage
	var dialogue_bubble = character.get_node_or_null("DialogueBubble")
	if not dialogue_bubble:
		push_error("DialogueBubble not found on character: " + character_id)
		return
	
	var text = data.text
	var duration = data.get("duration", 1.5)
	
	# Afficher via la bulle du personnage
	dialogue_bubble.show_quick_reaction(text, duration)
	
	print("Quick reaction shown: ", character_id, " says: ", text)

# === HANDLER DE DIALOGUE CLASSIQUE (RÉTROCOMPATIBILITÉ) ===

func _handle_dialogue(event: Dictionary):
	var data = event.data
	var character_id = data.character
	var character = character_container.get_node_or_null(character_id)
	
	if not character:
		push_error("Character not found for dialogue: " + character_id)
		return
	
	var text = data.text
	var duration = data.get("duration", 3.0)
	var style = data.get("bubble_style", "main")  # Défaut changé à "main"
	
	# Position du personnage pour la bulle
	var character_pos = character.global_position
	
	# Jouer la voix si spécifiée
	if data.has("voice"):
		audio_manager.play_voice("voices/" + data.voice)
	
	# Afficher le dialogue selon le style
	match style:
		"main", "normal", "pokemon":
			dialogue_system.show_main_dialogue(text, character_id, duration)
		"smiley", "emoji", "expression":
			dialogue_system.show_smiley(text, character_pos, duration)
		"quick", "rapid", "reaction":
			dialogue_system.show_quick_reaction(text, character_pos, duration)
		_:
			# Fallback sur l'ancien système de bulles
			dialogue_system.show_dialogue(text, character_pos, style, duration, character_id)
	
	print("Dialogue shown: ", character_id, " says: ", text, " (style: ", style, ")")

# === HANDLERS EXISTANTS ===

func _handle_play_effect(event: Dictionary):
	var data = event.data
	var effect_id = data.effect
	var position = Vector2(data.position.x, data.position.y)
	var params = data.get("params", {})
	
	effects_manager.play_effect(effect_id, position, params)

func _handle_stop_effect(event: Dictionary):
	var data = event.data
	var instance_id = data.instance_id
	
	effects_manager.stop_effect(instance_id)

func _handle_start_weather(event: Dictionary):
	var data = event.data
	var weather_type = data.weather
	var intensity = data.get("intensity", 1.0)
	
	effects_manager.start_weather(weather_type, intensity)

func _handle_stop_weather(event: Dictionary):
	var data = event.data
	var weather_type = data.weather
	
	effects_manager.stop_weather(weather_type)

func _handle_screen_flash(event: Dictionary):
	var data = event.data
	var color_data = data.get("color", {"r": 1.0, "g": 1.0, "b": 1.0, "a": 1.0})
	var color = Color(color_data.r, color_data.g, color_data.b, color_data.a)
	var duration = data.get("duration", 0.2)
	
	effects_manager.screen_flash(color, duration)

func _handle_change_background(event: Dictionary):
	var data = event.data
	var background_id = data.background
	var transition_duration = data.get("transition_duration", 0.0)
	
	background_manager.change_background(background_id, transition_duration)

func _handle_time_of_day(event: Dictionary):
	var data = event.data
	var time = data.time
	var transition_duration = data.get("transition_duration", 2.0)
	
	background_manager.set_time_of_day(time, transition_duration)

func _handle_camera_move(event: Dictionary):
	var data = event.data
	var target_pos = Vector2(data.position.x, data.position.y)
	var duration = data.get("duration", 1.0)
	var easing = data.get("easing", "ease_in_out")
	
	camera_controller.camera_move_to(target_pos, duration, easing)

func _handle_camera_zoom(event: Dictionary):
	var data = event.data
	var zoom_level = data.zoom
	var duration = data.get("duration", 1.0)
	var easing = data.get("easing", "ease_in_out")
	
	camera_controller.camera_zoom_to(zoom_level, duration, easing)

func _handle_camera_follow(event: Dictionary):
	var data = event.data
	var character_id = data.character
	var offset = Vector2.ZERO
	if data.has("offset"):
		offset = Vector2(data.offset.x, data.offset.y)
	var smoothing = data.get("smoothing", 5.0)
	
	camera_controller.camera_follow_character(character_id, offset, smoothing)

func _handle_camera_stop_follow(event: Dictionary):
	camera_controller.camera_stop_follow()

func _handle_camera_shake(event: Dictionary):
	var data = event.data
	var intensity = data.intensity
	var duration = data.duration
	
	camera_controller.camera_shake(intensity, duration)

func _handle_camera_pan(event: Dictionary):
	var data = event.data
	var points = data.points
	var duration_per_segment = data.get("duration_per_segment", 1.0)
	var easing = data.get("easing", "ease_in_out")
	
	camera_controller.camera_pan_between_points(points, duration_per_segment, easing)

func _handle_play_music(event: Dictionary):
	var data = event.data
	var music_file = data.file
	var fade_in = data.get("fade_in", 0.0)
	var loop = data.get("loop", true)
	
	audio_manager.play_music(music_file, fade_in, loop)

func _handle_stop_music(event: Dictionary):
	var data = event.data
	var fade_out = data.get("fade_out", 0.0)
	
	audio_manager.stop_music(fade_out)

func _handle_play_sfx(event: Dictionary):
	var data = event.data
	var sfx_file = data.file
	var volume = data.get("volume", 1.0)
	
	audio_manager.play_sfx(sfx_file, volume)

func _handle_play_voice(event: Dictionary):
	var data = event.data
	var voice_file = data.file
	var volume = data.get("volume", 1.0)
	
	audio_manager.play_voice(voice_file, volume)

func _handle_character_enter(event: Dictionary):
	var data = event.data
	var character_id = data.character
	
	# Créer le personnage s'il n'existe pas
	var character = character_container.get_node_or_null(character_id)
	if not character:
		character = character_factory.create_character(character_id)
		character_container.add_child(character)
	
	# Positionner
	if data.has("position"):
		character.position = Vector2(data.position.x, data.position.y)
	
	# Scale personnalisé pour cet événement + ADAPTATION OMBRE
	if data.has("scale"):
		var animated_sprite = character.get_node("AnimatedSprite2D")
		var scale_value = data.scale
		animated_sprite.scale = Vector2(scale_value, scale_value)
		
		# NOUVEAU : Adapter l'ombre au scale
		var shadow_system = character.get_node_or_null("ShadowSystem")
		if shadow_system:
			shadow_system.shadow_scale = Vector2(scale_value, scale_value * 0.6)
			shadow_system.shadow_sprite.scale = shadow_system.shadow_scale
	
	# NOUVEAU : Désactiver ombre si demandé
	if data.has("shadow_enabled") and not data.shadow_enabled:
		var shadow_system = character.get_node_or_null("ShadowSystem")
		if shadow_system:
			shadow_system.hide_shadow()
	
	# Animation initiale
	var animated_sprite = character.get_node("AnimatedSprite2D")
	if data.has("animation"):
		var anim_name = data.animation
		if data.has("direction"):
			anim_name += "_" + data.direction
		
		if animated_sprite.sprite_frames.has_animation(anim_name):
			animated_sprite.play(anim_name)
	
	print("Character entered: ", character_id)

func _handle_character_move(event: Dictionary):
	var data = event.data
	var character_id = data.character
	var character = character_container.get_node_or_null(character_id)
	
	if not character:
		push_error("Character not found: " + character_id)
		return
	
	# Créer tween pour le mouvement
	var tween = create_tween()
	var target_pos = Vector2(data.to.x, data.to.y)
	var current_pos = character.position
	var duration = data.get("duration", 1.0)
	
	# Calculer la direction du mouvement
	var direction = _calculate_direction(current_pos, target_pos)
	
	tween.tween_property(character, "position", target_pos, duration)
	
	# Changer animation avec la bonne direction
	var animated_sprite = character.get_node("AnimatedSprite2D")
	var walk_anim = "walk_" + direction
	if animated_sprite.sprite_frames.has_animation(walk_anim):
		animated_sprite.play(walk_anim)
		print("Playing animation: ", walk_anim)
	elif animated_sprite.sprite_frames.has_animation("walk"):
		animated_sprite.play("walk")
	
	# Revenir à idle à la fin avec la même direction
	tween.tween_callback(func(): 
		var idle_anim = "idle_" + direction
		if animated_sprite.sprite_frames.has_animation(idle_anim):
			animated_sprite.play(idle_anim)
		elif animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
	)
	
	print("Character moving: ", character_id, " direction: ", direction)

func _calculate_direction(from: Vector2, to: Vector2) -> String:
	var diff = to - from
	
	# Si pas de mouvement, garder direction par défaut
	if diff.length() < 1.0:
		return "s"
	
	# Calculer angle en degrés
	var angle = rad_to_deg(diff.angle())
	
	# Normaliser angle entre 0 et 360
	if angle < 0:
		angle += 360
	
	# Mapper aux 4 directions
	if angle >= 315 or angle < 45:
		return "e"  # Est (droite)
	elif angle >= 45 and angle < 135:
		return "s"  # Sud (bas)
	elif angle >= 135 and angle < 225:
		return "w"  # Ouest (gauche)
	else:
		return "n"  # Nord (haut)

func _handle_character_exit(event: Dictionary):
	var data = event.data
	var character_id = data.character
	var character = character_container.get_node_or_null(character_id)
	
	if character:
		character.queue_free()
		print("Character exited: ", character_id)
