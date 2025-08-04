@tool
extends EditorScript

func _run():
	print("=== Generating Main Scene Structure ===")
	
	# Créer la scène principale
	var main_scene = Node2D.new()
	main_scene.name = "Main"
	
	# EpisodeController
	var episode_controller = Node.new()
	episode_controller.name = "EpisodeController"
	main_scene.add_child(episode_controller)
	episode_controller.owner = main_scene
	
	# SceneContainer
	var scene_container = Node2D.new()
	scene_container.name = "SceneContainer"
	main_scene.add_child(scene_container)
	scene_container.owner = main_scene
	
	# Background (enfant de SceneContainer)
	var background = ParallaxBackground.new()
	background.name = "Background"
	scene_container.add_child(background)
	background.owner = main_scene
	
	# TileMapLayer (enfant de SceneContainer)
	var tilemap_layer = TileMapLayer.new()
	tilemap_layer.name = "TileMapLayer"
	scene_container.add_child(tilemap_layer)
	tilemap_layer.owner = main_scene
	
	# CharacterContainer (enfant de SceneContainer)
	var character_container = Node2D.new()
	character_container.name = "CharacterContainer"
	scene_container.add_child(character_container)
	character_container.owner = main_scene
	
	# EffectsContainer (enfant de SceneContainer)
	var effects_container = Node2D.new()
	effects_container.name = "EffectsContainer"
	scene_container.add_child(effects_container)
	effects_container.owner = main_scene
	
	# UIContainer (enfant de SceneContainer)
	var ui_container = CanvasLayer.new()
	ui_container.name = "UIContainer"
	scene_container.add_child(ui_container)
	ui_container.owner = main_scene
	
	# DialogueSystem (enfant de UIContainer)
	var dialogue_system = Control.new()
	dialogue_system.name = "DialogueSystem"
	ui_container.add_child(dialogue_system)
	dialogue_system.owner = main_scene
	
	# CameraSystem
	var camera_system = Camera2D.new()
	camera_system.name = "CameraSystem"
	camera_system.enabled = true
	camera_system.zoom = Vector2(4, 4)
	camera_system.position_smoothing_enabled = false
	main_scene.add_child(camera_system)
	camera_system.owner = main_scene
	
	# AudioSystem
	var audio_system = Node.new()
	audio_system.name = "AudioSystem"
	main_scene.add_child(audio_system)
	audio_system.owner = main_scene
	
	# MusicPlayer (enfant d'AudioSystem)
	var music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	audio_system.add_child(music_player)
	music_player.owner = main_scene
	
	# SFXPool (enfant d'AudioSystem)
	var sfx_pool = Node.new()
	sfx_pool.name = "SFXPool"
	audio_system.add_child(sfx_pool)
	sfx_pool.owner = main_scene
	
	# VoicePlayer (enfant d'AudioSystem)
	var voice_player = AudioStreamPlayer.new()
	voice_player.name = "VoicePlayer"
	audio_system.add_child(voice_player)
	voice_player.owner = main_scene
	
	# TimelineController
	var timeline_controller = Node.new()
	timeline_controller.name = "TimelineController"
	main_scene.add_child(timeline_controller)
	timeline_controller.owner = main_scene
	
	# Sauvegarder la scène
	var packed_scene = PackedScene.new()
	packed_scene.pack(main_scene)
	
	var result = ResourceSaver.save(packed_scene, "res://Main.tscn")
	
	if result == OK:
		print("✅ Main.tscn created successfully!")
		print("✅ Scene structure with all nodes generated")
		print("✅ Camera configured for pixel art (4x zoom)")
	else:
		print("❌ Error creating Main.tscn")
	
	# Nettoyer
	main_scene.queue_free()
