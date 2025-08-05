extends Node2D

@onready var episode_controller = $EpisodeController
@onready var video_exporter = $VideoExporter
@onready var background_manager = $BackgroundManager

func _ready():
	add_to_group("main")
	
	# DEBUG: Tester le background directement
	print("=== TESTING BACKGROUND LOADING ===")
	
	# Attendre 1 seconde puis tester
	await get_tree().create_timer(1.0).timeout
	background_manager.test_load_castle_room()
	
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
	
	# DEBUG: Tester background avec T
	if Input.is_action_just_pressed("ui_cancel"):  # Escape
		print("Manual background test...")
		background_manager.load_background("castle_room", 0.0)

func _on_export_started():
	print("🎬 Export started!")

func _on_export_progress(percentage: float):
	print("📊 Export progress: ", "%.1f" % percentage, "%")

func _on_export_finished(success: bool, file_path: String):
	if success:
		print("✅ Export finished: ", file_path)
	else:
		print("❌ Export failed: ", file_path)
