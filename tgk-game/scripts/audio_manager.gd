extends Node

const MASTER_BUS = "Master"
const MUSIC_BUS = "Music"
const SFX_BUS = "SFX"

const INITIAL_GLOBAL_MUSIC = 4
const INITIAL_SPATIAL_MUSIC = 4
const INITIAL_GLOBAL_SFX = 16
const INITIAL_SPATIAL_SFX = 16

const PLAYER_KEEPALIVE_MAX = 10.0
const PLAYER_KEEPALIVE_STREAM_MULTIPLIER = 2.0
const CLEANUP_INTERVAL = 2.0


var master_volume = 100.0:
	set(value):
		master_volume = clamp(value, 0.0, 100.0)
		_set_bus_volume(MASTER_BUS, master_volume)
var music_volume = 100.0:
	set(value):
		music_volume = clamp(value, 0.0, 100.0)
		_set_bus_volume(MUSIC_BUS, music_volume)
var sfx_volume = 100.0:
	set(value):
		sfx_volume = clamp(value, 0.0, 100.0)
		_set_bus_volume(SFX_BUS, sfx_volume)


@onready var global_music: Node = $GlobalMusic
@onready var global_sfx: Node = $GlobalSFX
@onready var spatial_music: Node = $SpatialMusic
@onready var spatial_sfx: Node = $SpatialSFX


func _ready() -> void:
	_create_global_players(global_music, INITIAL_GLOBAL_MUSIC)
	_create_global_players(global_sfx, INITIAL_GLOBAL_SFX)

	_create_spatial_players(spatial_music, INITIAL_SPATIAL_MUSIC)
	_create_spatial_players(spatial_sfx, INITIAL_SPATIAL_SFX)

	var cleanup_timer = Timer.new()

	cleanup_timer.wait_time = CLEANUP_INTERVAL
	cleanup_timer.timeout.connect(_cleanup_unused_players)
	cleanup_timer.autostart = true

	add_child(cleanup_timer)


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


func loop_music(path: String, volume: float = 100.0) -> void :
	play_music(
		path,
		volume,
		-1
	)

func play_music(path: String, volume: float = 100.0, loop_count: int = 1) -> void:
	_play_audio(
		path,
		global_music,
		null,
		MUSIC_BUS,
		volume,
		loop_count
	)

func loop_music_at(path: String, position: Vector2, volume: float = 100.0) -> void :
	play_music_at(
		path,
		position,
		volume,
		-1
	)

func play_music_at(path: String, position: Vector2, volume: float = 100.0, loop_count: int = 1) -> void:
	_play_audio(
		path,
		spatial_music,
		position,
		MUSIC_BUS,
		volume,
		loop_count
	)

func loop_sound(path: String, volume: float = 100.0) -> void :
	play_sound(
		path,
		volume,
		-1
	)

func play_sound(path: String, volume: float = 100.0, loop_count: int = 1) -> void:
	_play_audio(
		path,
		global_sfx,
		null,
		SFX_BUS,
		volume,
		loop_count
	)

func loop_sound_at(path: String, position: Vector2, volume: float = 100.0) -> void :
	play_sound_at(
		path,
		position,
		volume,
		-1
	)

func play_sound_at(path: String, position: Vector2, volume: float = 100.0, loop_count: int = 1) -> void:
	_play_audio(
		path,
		spatial_sfx,
		position,
		SFX_BUS,
		volume,
		loop_count
	)


func _play_audio(
	path: String,
	container: Node,
	position: Variant,
	bus_name: String,
	volume: float,
	loop_count: int
) -> void:
	var stream = load(path) as AudioStream

	if stream == null:
		push_warning("AudioManager: Could not load audio stream: " + path)
		return

	var is_spatial = position != null
	var player = _request_player(container, is_spatial)
	var final_volume = _get_final_volume(bus_name, volume)

	player.stream = stream
	player.bus = bus_name
	player.volume_db = _linear_volume_to_db(final_volume)
	player.set_meta("busy", true)
	player.set_meta("remaining_loops", loop_count)
	player.set_meta("last_stream_length", stream.get_length())

	if player is AudioStreamPlayer2D:
		player.global_position = position

	player.play()


func _request_player(container: Node, is_spatial: bool) -> Node:
	for child in container.get_children():
		if not child.get_meta("busy", false):
			return child

	var player: Node

	if is_spatial:
		player = AudioStreamPlayer2D.new()
	else:
		player = AudioStreamPlayer.new()

	player.set_meta("busy", false)
	player.set_meta("remaining_loops", 0)
	player.set_meta("expires_at", 0.0)
	player.set_meta("last_stream_length", 0.0)

	container.add_child(player)

	_connect_player_finished_signal(player)

	return player


func _create_global_players(container: Node, amount: int) -> void:
	for i in amount:
		var player = AudioStreamPlayer.new()

		player.set_meta("busy", false)
		player.set_meta("remaining_loops", 0)
		player.set_meta("expires_at", 0.0)
		player.set_meta("last_stream_length", 0.0)

		container.add_child(player)
		_connect_player_finished_signal(player)


func _create_spatial_players(container: Node, amount: int) -> void:
	for i in amount:
		var player = AudioStreamPlayer2D.new()

		player.set_meta("busy", false)
		player.set_meta("remaining_loops", 0)
		player.set_meta("expires_at", 0.0)
		player.set_meta("last_stream_length", 0.0)

		container.add_child(player)
		_connect_player_finished_signal(player)


func _connect_player_finished_signal(player: Node) -> void:
	if player is AudioStreamPlayer:
		player.finished.connect(_on_player_finished.bind(player))

	elif player is AudioStreamPlayer2D:
		player.finished.connect(_on_player_finished.bind(player))


func _on_player_finished(player: Node) -> void:
	var remaining_loops: int = player.get_meta("remaining_loops", 1)

	if remaining_loops == -1:
		player.play()
		return

	remaining_loops -= 1

	if remaining_loops > 0:
		player.set_meta("remaining_loops", remaining_loops)
		player.play()
		return

	_reset_player(player)


func _reset_player(player: Node) -> void:
	var stream_length: float = player.get_meta("last_stream_length", 0.0)

	var keepalive = min(
		PLAYER_KEEPALIVE_MAX,
		stream_length * PLAYER_KEEPALIVE_STREAM_MULTIPLIER
	)

	if player is AudioStreamPlayer:
		player.stop()
		player.stream = null
		player.volume_db = 0.0
		player.pitch_scale = 1.0

	elif player is AudioStreamPlayer2D:
		player.stop()
		player.stream = null
		player.global_position = Vector2.ZERO
		player.volume_db = 0.0
		player.pitch_scale = 1.0

	player.set_meta("busy", false)
	player.set_meta("remaining_loops", 0)
	player.set_meta("expires_at", Time.get_ticks_msec() / 1000.0 + keepalive)


func _cleanup_unused_players() -> void:
	var now = Time.get_ticks_msec() / 1000.0

	_cleanup_container(global_music, now)
	_cleanup_container(global_sfx, now)
	_cleanup_container(spatial_music, now)
	_cleanup_container(spatial_sfx, now)


func _cleanup_container(container: Node, now: float) -> void:
	for child in container.get_children():
		if child.get_meta("busy", false):
			continue

		var expires_at: float = child.get_meta("expires_at", 0.0)

		if expires_at > 0.0 and now >= expires_at:
			child.queue_free()


func _get_final_volume(bus_name: String, sound_volume: float) -> float:
	var master = master_volume / 100.0
	var bus = 1.0
	var local = clamp(sound_volume, 0.0, 100.0) / 100.0

	match bus_name:
		MUSIC_BUS:
			bus = music_volume / 100.0

		SFX_BUS:
			bus = sfx_volume / 100.0

		_:
			bus = 1.0

	return clamp(master * bus * local, 0.0, 1.0)


func _linear_volume_to_db(value: float) -> float:
	if value <= 0.0:
		return -80.0

	return linear_to_db(value)
