class_name VideoExporter extends Node

signal export_started
signal export_progress(percentage: float)
signal export_finished(success: bool, file_path: String)

var is_exporting: bool = false
var export_settings: Dictionary = {}
var original_time_scale: float = 1.0

@onready var episode_controller = get_node("../EpisodeController")
@onready var timeline_manager = get_node("../TimelineController")

func _ready():
	print("VideoExporter initialized")

func export_episode(episode_data: Dictionary, output_path: String = "") -> bool:
	if is_exporting:
		push_error("Export already in progress")
		return false
	
	print("=== Starting Video Export ===")
	
	# Configuration export
	var metadata = episode_data.get("episode", {}).get("metadata", {})
	export_settings = {
		"fps": metadata.get("fps", 30),
		"resolution": metadata.get("resolution", "1920x1080"),
		"duration": metadata.get("duration", 60),
		"output_path": output_path if output_path != "" else _generate_output_path(episode_data)
	}
	
	print("Export settings: ", export_settings)
	
	# Préparer l'environnement pour l'export
	_prepare_export_environment()
	
	# Démarrer l'enregistrement
	_start_recording()
	
	# Lancer l'épisode
	is_exporting = true
	export_started.emit()
	
	# Charger et jouer l'épisode
	_play_episode_for_export(episode_data)
	
	return true

func _generate_output_path(episode_data: Dictionary) -> String:
	var episode_id = episode_data.get("episode", {}).get("id", "episode")
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	return "user://exports/" + episode_id + "_" + timestamp + ".avi"

func _prepare_export_environment():
	# Sauvegarder les paramètres actuels
	original_time_scale = Engine.time_scale
	
	# Créer le dossier d'export si nécessaire
	var export_dir = "user://exports/"
	if not DirAccess.dir_exists_absolute(export_dir):
		DirAccess.open("user://").make_dir("exports")
	
	# Configuration pour export vidéo
	Engine.time_scale = 1.0  # Temps normal pour export
	
	# Désactiver VSync pour export plus rapide
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	print("Export environment prepared")

func _start_recording():
	# Résolution
	var resolution_parts = export_settings.resolution.split("x")
	var width = int(resolution_parts[0])
	var height = int(resolution_parts[1])
	
	# Configuration MovieWriter
	var movie_file = export_settings.output_path
	
	# Paramètres de ligne de commande Godot pour l'export
	# Note: MovieWriter n'est disponible qu'avec des arguments de ligne de commande
	print("To export video, restart Godot with these arguments:")
	print("--headless --movie-file=\"" + movie_file + "\" --fixed-fps=" + str(export_settings.fps))
	print("Then run your scene normally.")
	
	# Pour cette démo, on simule l'export
	_simulate_export()

func _simulate_export():
	print("=== SIMULATION MODE ===")
	print("In production, use Godot command line with --movie-file argument")
	print("Starting episode playback for preview...")

func _play_episode_for_export(episode_data: Dictionary):
	# Connecter aux signaux pour suivre la progression
	if not timeline_manager.timeline_finished.is_connected(_on_export_timeline_finished):
		timeline_manager.timeline_finished.connect(_on_export_timeline_finished)
	
	# Charger et jouer l'épisode
	episode_controller.current_episode_data = episode_data
	episode_controller._load_first_scene()
	episode_controller.play_episode()
	
	# Timer de surveillance pour la progression
	_start_progress_monitoring()

func _start_progress_monitoring():
	var total_duration = export_settings.duration
	var progress_timer = Timer.new()
	progress_timer.wait_time = 0.5  # Update toutes les 0.5s
	progress_timer.timeout.connect(_update_export_progress)
	add_child(progress_timer)
	progress_timer.start()
	
	# Timer pour auto-stop si trop long
	var max_timer = Timer.new()
	max_timer.wait_time = total_duration + 10  # +10s de marge
	max_timer.timeout.connect(func(): _finish_export(false, "Timeout"))
	max_timer.one_shot = true
	add_child(max_timer)
	max_timer.start()

func _update_export_progress():
	if not is_exporting:
		return
	
	var current_time = timeline_manager.current_time
	var total_duration = export_settings.duration
	var percentage = (current_time / total_duration) * 100.0
	
	export_progress.emit(percentage)
	print("Export progress: ", "%.1f" % percentage, "%")

func _on_export_timeline_finished():
	_finish_export(true, export_settings.output_path)

func _finish_export(success: bool, result_path: String):
	if not is_exporting:
		return
	
	is_exporting = false
	
	# Restaurer l'environnement
	_restore_environment()
	
	# Nettoyer les timers
	for child in get_children():
		if child is Timer:
			child.queue_free()
	
	if success:
		print("=== Export Completed Successfully ===")
		print("File saved to: ", result_path)
	else:
		print("=== Export Failed ===")
		print("Reason: ", result_path)
	
	export_finished.emit(success, result_path)

func _restore_environment():
	# Restaurer les paramètres
	Engine.time_scale = original_time_scale
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	
	print("Environment restored")

# Interface simple pour déclencher l'export
func quick_export_current_episode() -> bool:
	if not episode_controller.current_episode_data.is_empty():
		return export_episode(episode_controller.current_episode_data)
	else:
		push_error("No episode loaded for export")
		return false

# Export avec paramètres personnalisés
func export_with_settings(episode_data: Dictionary, custom_settings: Dictionary) -> bool:
	# Merger les settings personnalisés
	var metadata = episode_data.get("episode", {}).get("metadata", {})
	
	if custom_settings.has("fps"):
		metadata.fps = custom_settings.fps
	if custom_settings.has("resolution"):
		metadata.resolution = custom_settings.resolution
	if custom_settings.has("output_path"):
		return export_episode(episode_data, custom_settings.output_path)
	
	return export_episode(episode_data)
