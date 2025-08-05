class_name BackgroundManager extends Node

@onready var background_container = get_node("../SceneContainer/Background")
@onready var tilemap_layer = get_node("../SceneContainer/TileMapLayer")

# Cache des backgrounds
var background_cache: Dictionary = {}
var current_background: String = ""

func _ready():
	print("BackgroundManager initialized")

func load_background(background_id: String, transition_duration: float = 0.0):
	if current_background == background_id:
		return  # Déjà chargé
	
	print("Loading background: ", background_id)
	
	# IMPORTANT: Définir current_background AVANT de charger les données
	current_background = background_id
	
	# Charger le nouveau background
	var background_data = _load_background_data(background_id)
	if background_data.is_empty():
		push_error("Background not found: " + background_id)
		current_background = ""  # Reset si échec
		return
	
	if transition_duration > 0:
		_transition_background(background_data, transition_duration)
	else:
		_apply_background_instantly(background_data)
	
	print("Background loaded successfully: ", background_id)

func _load_background_data(background_id: String) -> Dictionary:
	# Vérifier le cache
	if background_cache.has(background_id):
		return background_cache[background_id]
	
	# Chemin du fichier config
	var config_path = "res://assets/tilesets/" + background_id + "/config.json"
	
	# Essayer de charger depuis config.json
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result != OK:
			push_error("Failed to parse background config: " + config_path)
		else:
			var data = json.data.get("background", {})
			background_cache[background_id] = data
			return data
	
	# Fallback 1: Image dans le dossier du background
	var folder_image_path = "res://assets/tilesets/" + background_id + "/" + background_id + ".png"
	if FileAccess.file_exists(folder_image_path):
		var simple_bg = {
			"type": "simple_image",
			"image": folder_image_path
		}
		background_cache[background_id] = simple_bg
		print("Found background image: ", folder_image_path)
		return simple_bg
	
	# Fallback 2: Image directement dans tilesets/
	var direct_image_path = "res://assets/tilesets/" + background_id + ".png"
	if FileAccess.file_exists(direct_image_path):
		var simple_bg = {
			"type": "simple_image",
			"image": direct_image_path
		}
		background_cache[background_id] = simple_bg
		print("Found background image: ", direct_image_path)
		return simple_bg
	
	# Aucun fichier trouvé
	push_error("No background files found for: " + background_id)
	push_error("Searched paths:")
	push_error("  - " + config_path)
	push_error("  - " + folder_image_path)
	push_error("  - " + direct_image_path)
	
	return {}

func _apply_background_instantly(background_data: Dictionary):
	_clear_current_background()
	
	match background_data.get("type", "simple_image"):
		"simple_image":
			_setup_simple_background(background_data)
		"parallax":
			_setup_parallax_background(background_data)
		"tilemap":
			_setup_tilemap_background(background_data)

func _clear_current_background():
	# Nettoyer les layers parallax existants
	for child in background_container.get_children():
		child.queue_free()
	
	# Nettoyer tilemap
	if tilemap_layer.tile_set:
		tilemap_layer.clear()

func _setup_simple_background(data: Dictionary):
	var image_path = data.get("image", "")
	
	print("Setting up simple background with image: ", image_path)
	
	# Si le chemin est déjà absolu, l'utiliser tel quel
	if image_path.begins_with("res://"):
		# Chemin déjà complet, ne rien faire
		pass
	else:
		# Chemin relatif, essayer différentes possibilités
		if current_background != "":
			# Essayer dans le dossier du background
			image_path = "res://assets/tilesets/" + current_background + "/" + image_path
		else:
			# Fallback si current_background est vide
			push_error("current_background is empty, cannot resolve relative path: " + image_path)
			return
	
	print("Final image path: ", image_path)
	
	if not FileAccess.file_exists(image_path):
		push_error("Background image not found: " + image_path)
		return
	
	var texture = load(image_path) as Texture2D
	
	if not texture:
		push_error("Failed to load background texture: " + image_path)
		return
	
	# Créer layer parallax simple
	var parallax_layer = ParallaxLayer.new()
	var sprite = Sprite2D.new()
	
	sprite.texture = texture
	sprite.centered = false
	
	# Scale pour pixel art si spécifié
	var scale = data.get("scale", 1.0)
	sprite.scale = Vector2(scale, scale)
	
	# Position
	var position = data.get("position", {"x": 0, "y": 0})
	sprite.position = Vector2(position.x, position.y)
	
	parallax_layer.add_child(sprite)
	background_container.add_child(parallax_layer)
	
	print("✅ Simple background loaded successfully: ", image_path)
	
func _setup_parallax_background(data: Dictionary):
	var layers = data.get("layers", [])
	
	for layer_data in layers:
		var parallax_layer = ParallaxLayer.new()
		
		# Configuration parallax
		var motion_scale = layer_data.get("motion_scale", {"x": 1.0, "y": 1.0})
		parallax_layer.motion_scale = Vector2(motion_scale.x, motion_scale.y)
		
		var motion_offset = layer_data.get("motion_offset", {"x": 0.0, "y": 0.0})
		parallax_layer.motion_offset = Vector2(motion_offset.x, motion_offset.y)
		
		# Sprite du layer
		var sprite = Sprite2D.new()
		var texture_path = "res://assets/tilesets/" + current_background + "/" + layer_data.image
		var texture = load(texture_path) as Texture2D
		
		if not texture:
			push_error("Failed to load layer texture: " + texture_path)
			continue
		
		sprite.texture = texture
		sprite.centered = false
		
		# Position et scale
		var position = layer_data.get("position", {"x": 0, "y": 0})
		sprite.position = Vector2(position.x, position.y)
		
		var scale = layer_data.get("scale", 1.0)
		sprite.scale = Vector2(scale, scale)
		
		# Répétition si nécessaire
		if layer_data.get("repeat", false):
			var repeat_size = layer_data.get("repeat_size", {"x": 1920, "y": 1080})
			parallax_layer.motion_mirroring = Vector2(repeat_size.x, repeat_size.y)
		
		parallax_layer.add_child(sprite)
		background_container.add_child(parallax_layer)
	
	print("Parallax background loaded with ", layers.size(), " layers")

func _setup_tilemap_background(data: Dictionary):
	var tileset_path = "res://assets/tilesets/" + data.tileset + ".tres"
	
	if not FileAccess.file_exists(tileset_path):
		push_error("Tileset not found: " + tileset_path)
		return
	
	var tileset = load(tileset_path) as TileSet
	tilemap_layer.tile_set = tileset
	
	# Charger la map depuis CSV ou tableau
	var map_data = data.get("map_data", [])
	_load_tilemap_data(map_data)
	
	print("Tilemap background loaded: ", tileset_path)

func _load_tilemap_data(map_data: Array):
	for y in range(map_data.size()):
		var row = map_data[y]
		for x in range(row.size()):
			var tile_id = row[x]
			if tile_id > 0:
				tilemap_layer.set_cell(Vector2i(x, y), 0, Vector2i(tile_id - 1, 0))

func _transition_background(background_data: Dictionary, duration: float):
	# Pour l'instant, transition simple avec fade
	var fade_overlay = ColorRect.new()
	fade_overlay.color = Color.BLACK
	fade_overlay.size = Vector2(1920, 1080)
	fade_overlay.modulate.a = 0.0
	get_tree().current_scene.add_child(fade_overlay)
	
	var tween = create_tween()
	
	# Fade to black
	tween.tween_property(fade_overlay, "modulate:a", 1.0, duration / 2)
	tween.tween_callback(func(): _apply_background_instantly(background_data))
	# Fade from black
	tween.tween_property(fade_overlay, "modulate:a", 0.0, duration / 2)
	tween.tween_callback(func(): fade_overlay.queue_free())

# Fonctions pour la timeline
func change_background(background_id: String, transition_duration: float = 0.0):
	load_background(background_id, transition_duration)

func set_time_of_day(time: String, transition_duration: float = 2.0):
	# Système jour/nuit simple avec overlay
	var overlay = get_tree().current_scene.get_node_or_null("TimeOverlay")
	if not overlay:
		overlay = ColorRect.new()
		overlay.name = "TimeOverlay"
		overlay.size = Vector2(1920, 1080)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		get_tree().current_scene.add_child(overlay)
	
	var target_color = Color.TRANSPARENT
	match time:
		"dawn":
			target_color = Color(1.0, 0.8, 0.6, 0.2)  # Orange léger
		"day":
			target_color = Color.TRANSPARENT
		"dusk":
			target_color = Color(0.8, 0.4, 0.2, 0.3)  # Orange foncé
		"night":
			target_color = Color(0.2, 0.2, 0.4, 0.5)  # Bleu foncé
	
	if transition_duration > 0:
		var tween = create_tween()
		tween.tween_property(overlay, "color", target_color, transition_duration)
	else:
		overlay.color = target_color
	
	print("Time of day changed to: ", time)

# Test function - appelez ça dans _ready pour tester
func test_load_castle_room():
	print("=== TESTING CASTLE ROOM BACKGROUND ===")
	load_background("castle_room", 0.0)
