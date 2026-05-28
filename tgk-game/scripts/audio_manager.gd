extends Node
class_name AudioManager


const MASTER_BUS = "Master"
const MUSIC_BUS = "Music"
const SFX_BUS = "SFX"


const audio_player_scene = preload("res://scenes/UI/audio_player.tscn")


@onready var owned_audio_players: Node = $OwnedAudioPlayers


var master_volume: float = 100.0:
	set(value):
		master_volume = clamp(value, 0.0, 100.0)
		_set_bus_volume(MASTER_BUS, master_volume)


var music_volume: float = 100.0:
	set(value):
		music_volume = clamp(value, 0.0, 100.0)
		_set_bus_volume(MUSIC_BUS, music_volume)


var sfx_volume: float = 100.0:
	set(value):
		sfx_volume = clamp(value, 0.0, 100.0)
		_set_bus_volume(SFX_BUS, sfx_volume)

func loop_music(
	parent: Node,
	path: String,
	volume: float = 100.0,
	loop_count: int = -1,
	smooth_start: bool = false,
	smooth_loop: bool = false,
	smooth_factor: float = 0.05
) -> AudioPlayer:
	return _create_audio_player(
		parent,
		path,
		volume,
		loop_count,
		smooth_start,
		smooth_loop,
		smooth_factor,
		null,
		MUSIC_BUS
	)

func play_music(
	parent: Node,
	path: String,
	volume: float = 100.0,
	loop_count: int = 1,
	smooth_start: bool = false,
	smooth_loop: bool = false,
	smooth_factor: float = 0.05
) -> AudioPlayer:
	return _create_audio_player(
		parent,
		path,
		volume,
		loop_count,
		smooth_start,
		smooth_loop,
		smooth_factor,
		null,
		MUSIC_BUS
	)


func loop_music_at(
	parent: Node,
	path: String,
	position: Vector2,
	volume: float = 100.0,
	loop_count: int = -1,
	smooth_start: bool = false,
	smooth_loop: bool = false,
	smooth_factor: float = 0.05
) -> AudioPlayer:
	return _create_audio_player(
		parent,
		path,
		volume,
		loop_count,
		smooth_start,
		smooth_loop,
		smooth_factor,
		position,
		MUSIC_BUS
	)

func play_music_at(
	parent: Node,
	path: String,
	position: Vector2,
	volume: float = 100.0,
	loop_count: int = 1,
	smooth_start: bool = false,
	smooth_loop: bool = false,
	smooth_factor: float = 0.05
) -> AudioPlayer:
	return _create_audio_player(
		parent,
		path,
		volume,
		loop_count,
		smooth_start,
		smooth_loop,
		smooth_factor,
		position,
		MUSIC_BUS
	)

func loop_sound(
	parent: Node,
	path: String,
	volume: float = 100.0,
	loop_count: int = -1,
	smooth_start: bool = false,
	smooth_loop: bool = false,
	smooth_factor: float = 0.05
) -> AudioPlayer:
	return _create_audio_player(
		parent,
		path,
		volume,
		loop_count,
		smooth_start,
		smooth_loop,
		smooth_factor,
		null,
		SFX_BUS
	)

func play_sound(
	parent: Node,
	path: String,
	volume: float = 100.0,
	loop_count: int = 1,
	smooth_start: bool = false,
	smooth_loop: bool = false,
	smooth_factor: float = 0.05
) -> AudioPlayer:
	return _create_audio_player(
		parent,
		path,
		volume,
		loop_count,
		smooth_start,
		smooth_loop,
		smooth_factor,
		null,
		SFX_BUS
	)

func loop_sound_at(
	parent: Node,
	path: String,
	position: Vector2,
	volume: float = 100.0,
	loop_count: int = -1,
	smooth_start: bool = false,
	smooth_loop: bool = false,
	smooth_factor: float = 0.05
) -> AudioPlayer:
	return _create_audio_player(
		parent,
		path,
		volume,
		loop_count,
		smooth_start,
		smooth_loop,
		smooth_factor,
		position,
		SFX_BUS
	)

func play_sound_at(
	parent: Node,
	path: String,
	position: Vector2,
	volume: float = 100.0,
	loop_count: int = 1,
	smooth_start: bool = false,
	smooth_loop: bool = false,
	smooth_factor: float = 0.05
) -> AudioPlayer:
	return _create_audio_player(
		parent,
		path,
		volume,
		loop_count,
		smooth_start,
		smooth_loop,
		smooth_factor,
		position,
		SFX_BUS
	)


func _create_audio_player(
	parent: Node,
	path: String,
	volume: float,
	loop_count: int,
	smooth_start: bool,
	smooth_loop: bool,
	smooth_factor: float,
	position,
	bus_name: String
) -> AudioPlayer:
	if audio_player_scene == null:
		push_warning("AudioManager: audio_player_scene is not assigned.")
		return null

	var audio_player = audio_player_scene.instantiate() as AudioPlayer

	if audio_player == null:
		push_warning("AudioManager: audio_player_scene does not instantiate AudioPlayer.")
		return null

	var actual_parent = parent

	if actual_parent == null:
		actual_parent = owned_audio_players

	actual_parent.add_child(audio_player)

	audio_player.set_bus(bus_name)
	
	audio_player.play(
		actual_parent,
		path,
		volume,
		loop_count,
		smooth_start,
		smooth_loop,
		smooth_factor,
		position
	)


	return audio_player


func _set_bus_volume(bus_name: String, value: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		push_warning("AudioManager: Bus does not exist: " + bus_name)
		return

	var linear = clamp(value, 0.0, 100.0) / 100.0

	if linear <= 0.0:
		AudioServer.set_bus_volume_db(bus_index, -80.0)
	else:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear))
