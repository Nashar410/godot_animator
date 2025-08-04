extends Node2D

@onready var episode_controller = $EpisodeController
@onready var video_exporter = $VideoExporter

func _ready():
	add_to_group("main")
	# Test de chargement d'épisode
	episode_controller.load_episode("res://episodes/test_episode.json")
	
	# Connecter signaux export
	video_exporter.export_started.connect(_on_export_started)
	video_exporter.export_progress.connect(_on_export_progress)
	video_exporter.export_finished.connect(_on_export_finished)

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Barre espace
		episode_controller.play_episode()
	
	if event.is_action_pressed("ui_select"):  # Entrée
		print("Starting video export...")
		video_exporter.quick_export_current_episode()

func _on_export_started():
	print("🎬 Export started!")

func _on_export_progress(percentage: float):
	print("📊 Export progress: ", "%.1f" % percentage, "%")

func _on_export_finished(success: bool, file_path: String):
	if success:
		print("✅ Export finished: ", file_path)
	else:
		print("❌ Export failed: ", file_path)
