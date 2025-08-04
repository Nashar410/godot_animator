class_name AudioManager extends Node

# Pool de players SFX pour jouer plusieurs sons simultanément
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_pool_size: int = 10

@onready var music_player = get_node("MusicPlayer")
@onready var voice_player = get_node("VoicePlayer")

# Cache des resources audio
var audio_cache: Dictionary = {}

func _ready():
	print("AudioManager initialized")
	_create_sfx_pool()

func _create_sfx_pool():
	# Créer un pool de AudioStreamPlayer pour les SFX
	var sfx_pool_node = get_node("SFXPool")  # SFXPool est frère d'AudioManager, pas oncle
	
	for i in range(sfx_pool_size):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer_" + str(i)
		sfx_pool_node.add_child(player)
		sfx_players.append(player)
	
	print("SFX pool created with ", sfx_pool_size, " players")

func play_music(music_file: String, fade_in: float = 0.0, loop: bool = true):
	var audio_stream = _load_audio(music_file)
	if not audio_stream:
		return
	
	# Arrêter musique actuelle si fade_in
	if fade_in > 0.0 and music_player.playing:
		_fade_out_music(fade_in / 2)
		await get_tree().create_timer(fade_in / 2).timeout
	
	music_player.stream = audio_stream
	music_player.volume_db = -80 if fade_in > 0 else 0
	music_player.play()
	
	# Fade in
	if fade_in > 0.0:
		_fade_in_music(fade_in)
	
	print("Music playing: ", music_file)

func _fade_in_music(duration: float):
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", 0, duration)

func _fade_out_music(duration: float):
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80, duration)

func stop_music(fade_out: float = 0.0):
	if fade_out > 0.0:
		_fade_out_music(fade_out)
		await get_tree().create_timer(fade_out).timeout
	
	music_player.stop()
	print("Music stopped")

func play_sfx(sfx_file: String, volume: float = 1.0):
	var audio_stream = _load_audio(sfx_file)
	if not audio_stream:
		return
	
	# Trouver un player libre
	var available_player = _get_available_sfx_player()
	if not available_player:
		print("Warning: All SFX players busy, skipping: ", sfx_file)
		return
	
	available_player.stream = audio_stream
	available_player.volume_db = linear_to_db(volume)
	available_player.play()
	
	print("SFX playing: ", sfx_file)

func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	return null

func play_voice(voice_file: String, volume: float = 1.0):
	var audio_stream = _load_audio(voice_file)
	if not audio_stream:
		return
	
	# Arrêter voix précédente
	if voice_player.playing:
		voice_player.stop()
	
	voice_player.stream = audio_stream
	voice_player.volume_db = linear_to_db(volume)
	voice_player.play()
	
	print("Voice playing: ", voice_file)

func stop_voice():
	voice_player.stop()
	print("Voice stopped")

func _load_audio(file_path: String) -> AudioStream:
	# Chemin relatif depuis assets/audio/
	var full_path = "res://assets/audio/" + file_path
	
	# Vérifier cache
	if audio_cache.has(full_path):
		return audio_cache[full_path]
	
	# Charger depuis le disque
	if not FileAccess.file_exists(full_path):
		# Essayer différentes extensions
		var extensions = [".ogg", ".wav", ".mp3"]
		var base_path = full_path.get_basename()
		
		for ext in extensions:
			var test_path = base_path + ext
			if FileAccess.file_exists(test_path):
				full_path = test_path
				break
		
		if not FileAccess.file_exists(full_path):
			push_error("Audio file not found: " + file_path)
			return null
	
	var audio_stream = load(full_path) as AudioStream
	if audio_stream:
		audio_cache[full_path] = audio_stream
		print("Audio cached: ", full_path)
	else:
		push_error("Failed to load audio: " + full_path)
	
	return audio_stream

# Fonctions utilitaires pour la timeline
func set_master_volume(volume: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume))

func set_music_volume(volume: float):
	music_player.volume_db = linear_to_db(volume)

func set_sfx_volume(volume: float):
	for player in sfx_players:
		player.volume_db = linear_to_db(volume)

func set_voice_volume(volume: float):
	voice_player.volume_db = linear_to_db(volume)
