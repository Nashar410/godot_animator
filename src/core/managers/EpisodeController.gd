class_name EpisodeController extends Node

signal episode_started
signal episode_finished

var current_episode_data: Dictionary
var is_playing: bool = false

@onready var timeline_manager = get_node("../TimelineController")

func _ready():
	print("EpisodeController initialized")
	
	# Connecter les signaux
	if timeline_manager:
		timeline_manager.timeline_finished.connect(_on_timeline_finished)

func load_episode(json_path: String) -> bool:
	if not FileAccess.file_exists(json_path):
		push_error("Episode file not found: " + json_path)
		return false
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse JSON: " + json_path)
		return false
	
	current_episode_data = json.data
	print("Episode loaded: ", current_episode_data.get("episode", {}).get("title", "Unknown"))
	
	# Charger la première scène
	_load_first_scene()
	return true

func _load_first_scene():
	var episode = current_episode_data.get("episode", {})
	var scenes = episode.get("scenes", [])
	
	if scenes.size() > 0:
		var first_scene = scenes[0]
		var timeline = first_scene.get("timeline", [])
		timeline_manager.load_timeline(timeline)
		print("First scene timeline loaded")

func play_episode():
	if current_episode_data.is_empty():
		push_error("No episode data loaded")
		return
	
	is_playing = true
	episode_started.emit()
	timeline_manager.play_timeline()
	print("Episode playback started")

func _on_timeline_finished():
	is_playing = false
	episode_finished.emit()
	print("Episode finished")
