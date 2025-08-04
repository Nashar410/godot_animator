class_name CameraController extends Camera2D

# Limites de la caméra
var camera_bounds: Rect2 = Rect2(-1000, -1000, 2000, 2000)

# Variables pour le follow
var follow_target: Node2D = null
var follow_offset: Vector2 = Vector2.ZERO
var follow_smoothing: float = 0.0

# Variables pour les transitions
var is_transitioning: bool = false

func _ready():
	print("CameraController initialized")
	
	# Configuration pixel-perfect par défaut
	enabled = true
	zoom = Vector2(4, 4)
	position_smoothing_enabled = false

func _process(delta):
	if follow_target and not is_transitioning:
		_update_follow_camera(delta)

func _update_follow_camera(delta):
	var target_pos = follow_target.global_position + follow_offset
	
	if follow_smoothing > 0:
		global_position = global_position.lerp(target_pos, follow_smoothing * delta)
	else:
		global_position = target_pos
	
	_apply_camera_bounds()

func _apply_camera_bounds():
	# Contraindre la position dans les limites
	if camera_bounds != Rect2():
		global_position.x = clamp(global_position.x, camera_bounds.position.x, camera_bounds.position.x + camera_bounds.size.x)
		global_position.y = clamp(global_position.y, camera_bounds.position.y, camera_bounds.position.y + camera_bounds.size.y)

# === FONCTIONS TIMELINE ===

func camera_move_to(target_pos: Vector2, duration: float, easing: String = "ease_in_out"):
	if is_transitioning:
		return
	
	is_transitioning = true
	follow_target = null  # Arrêter le follow pendant transition
	
	var tween = create_tween()
	
	# Appliquer easing
	var ease_type = Tween.EASE_IN_OUT  # Par défaut
	match easing:
		"ease_in":
			ease_type = Tween.EASE_IN
		"ease_out":
			ease_type = Tween.EASE_OUT
		"ease_in_out":
			ease_type = Tween.EASE_IN_OUT
		"linear":
			ease_type = Tween.EASE_IN_OUT  # Fallback sur ease_in_out

	if easing != "linear":
		tween.set_ease(ease_type)
	
	tween.tween_property(self, "global_position", target_pos, duration)
	tween.tween_callback(func(): is_transitioning = false)
	
	print("Camera moving to: ", target_pos)

func camera_zoom_to(target_zoom: float, duration: float, easing: String = "ease_in_out"):
	var tween = create_tween()
	
	# Appliquer easing
	var ease_type = Tween.EASE_IN_OUT  # Par défaut
	match easing:
		"ease_in":
			ease_type = Tween.EASE_IN
		"ease_out":
			ease_type = Tween.EASE_OUT
		"ease_in_out":
			ease_type = Tween.EASE_IN_OUT
		"linear":
			ease_type = Tween.EASE_IN_OUT  # Fallback sur ease_in_out

	if easing != "linear":
		tween.set_ease(ease_type)
	
	tween.tween_property(self, "zoom", Vector2(target_zoom, target_zoom), duration)
	
	print("Camera zooming to: ", target_zoom)

func camera_follow_character(character_id: String, offset: Vector2 = Vector2.ZERO, smoothing: float = 5.0):
	var character_container = get_node("../SceneContainer/CharacterContainer")
	var character = character_container.get_node_or_null(character_id)
	
	if not character:
		push_error("Character not found for camera follow: " + character_id)
		return
	
	follow_target = character
	follow_offset = offset
	follow_smoothing = smoothing
	is_transitioning = false
	
	print("Camera following: ", character_id)

func camera_stop_follow():
	follow_target = null
	print("Camera stopped following")

func camera_shake(intensity: float, duration: float):
	var original_pos = global_position
	var shake_tween = create_tween()
	
	for i in range(int(duration * 30)):  # 30 secousses par seconde
		var shake_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		shake_tween.parallel().tween_property(self, "global_position", original_pos + shake_offset, 1.0/30.0)
	
	shake_tween.tween_property(self, "global_position", original_pos, 0.1)
	
	print("Camera shake: intensity=", intensity, " duration=", duration)

func set_camera_bounds(bounds: Rect2):
	camera_bounds = bounds
	_apply_camera_bounds()
	print("Camera bounds set: ", bounds)

func camera_pan_between_points(points: Array, duration_per_segment: float, easing: String = "ease_in_out"):
	if points.size() < 2:
		return
	
	is_transitioning = true
	follow_target = null
	
	var tween = create_tween()
	
	# Appliquer easing
	var ease_type = Tween.EASE_IN_OUT  # Par défaut
	match easing:
		"ease_in":
			ease_type = Tween.EASE_IN
		"ease_out":
			ease_type = Tween.EASE_OUT
		"ease_in_out":
			ease_type = Tween.EASE_IN_OUT
		"linear":
			ease_type = Tween.EASE_IN_OUT  # Fallback sur ease_in_out

	if easing != "linear":
		tween.set_ease(ease_type)

	for i in range(points.size()):
		var point = Vector2(points[i].x, points[i].y)
		tween.tween_property(self, "global_position", point, duration_per_segment)
	
	tween.tween_callback(func(): is_transitioning = false)
	
	print("Camera panning through ", points.size(), " points")
