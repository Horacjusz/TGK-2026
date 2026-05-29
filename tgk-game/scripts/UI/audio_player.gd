extends Node
class_name AudioPlayer

@onready var global_player: AudioStreamPlayer = $GlobalPlayer
@onready var spatial_player: AudioStreamPlayer2D = $SpatialPlayer

var parent: Node = null

var active_player: Node = null
var sound_path: String = ""
var base_volume: float = 100.0
var loop_count: int = -1
var remaining_loops: int = -1

var smooth_loop: bool = true
var smooth_factor: float = 0.05

var volume_tween: Tween = null
var loop_timer: Timer = null

var is_stopping: bool = false

var bus_name: String = "Master"


func set_bus(new_bus_name: String) -> void:
	bus_name = new_bus_name

	global_player.bus = bus_name
	spatial_player.bus = bus_name

func play(
	new_parent: Node,
	new_sound_path: String,
	volume: float = 100.0,
	new_loop_count: int = -1,
	new_smooth_start: bool = false,
	new_smooth_loop: bool = true,
	new_smooth_factor: float = 0.05,
	position = null
) -> void:
	print("Initiating playing audio")
	if active_player != null:
		return

	_play(
		new_parent,
		new_sound_path,
		volume,
		new_loop_count,
		new_smooth_start,
		new_smooth_loop,
		new_smooth_factor,
		position
	)


func _play(
	new_parent: Node,
	new_sound_path: String,
	volume: float = 100.0,
	new_loop_count: int = -1,
	new_smooth_start: bool = false,
	new_smooth_loop: bool = true,
	new_smooth_factor: float = 0.05,
	position = null
) -> void:
	parent = new_parent
	sound_path = new_sound_path
	base_volume = clamp(volume, 0.0, 100.0)
	loop_count = new_loop_count
	remaining_loops = new_loop_count
	smooth_loop = new_smooth_loop
	smooth_factor = clamp(new_smooth_factor, 0.0, 0.5)
	is_stopping = false

	var stream = load(sound_path) as AudioStream

	if stream == null:
		push_warning("AudioPlayer: Could not load sound: " + sound_path)
		return

	_clear_loop_timer()
	_kill_volume_tween()

	global_player.stop()
	spatial_player.stop()

	global_player.stream = stream
	spatial_player.stream = stream

	if position == null:
		active_player = global_player
	else:
		active_player = spatial_player
		spatial_player.global_position = position

	active_player.volume_db = _volume_to_db(
		0.0 if new_smooth_start else base_volume
	)

	active_player.play()

	if new_smooth_start:
		set_volume(base_volume, _get_smooth_time())

	_schedule_smooth_loop()

func set_volume(
	target_value: float,
	time: float = 0.0
) -> void:
	if active_player == null:
		return

	target_value = clamp(target_value, 0.0, 100.0)

	_kill_volume_tween()

	if time <= 0.0:
		base_volume = target_value
		active_player.volume_db = _volume_to_db(base_volume)
		return

	var start_volume = _db_to_volume(active_player.volume_db)

	volume_tween = create_tween()

	volume_tween.tween_method(
		func(value: float):
			base_volume = value

			if active_player != null:
				active_player.volume_db = _volume_to_db(value),
		start_volume,
		target_value,
		time
	)

func stop(time: float = 0.0) -> void:
	if active_player == null:
		queue_free()
		return

	is_stopping = true

	_clear_loop_timer()

	if time <= 0.0:
		active_player.stop()
		active_player = null
		queue_free()
		return

	set_volume(0.0, time)

	await get_tree().create_timer(time).timeout

	if active_player != null:
		active_player.stop()
		active_player = null

	queue_free()

func _ready() -> void:
	global_player.finished.connect(_on_active_player_finished)
	spatial_player.finished.connect(_on_active_player_finished)


func _process(_delta: float) -> void:
	pass


func _schedule_smooth_loop() -> void:
	if active_player == null:
		return

	if not smooth_loop:
		return

	if loop_count == 0:
		return

	var stream = active_player.stream

	if stream == null:
		return

	var length = stream.get_length()

	if length <= 0.0:
		return

	var smooth_time = _get_smooth_time()

	if smooth_time <= 0.0:
		return

	var wait_time = max(length - smooth_time, 0.01)

	_clear_loop_timer()

	loop_timer = Timer.new()

	loop_timer.one_shot = true
	loop_timer.wait_time = wait_time

	loop_timer.timeout.connect(
		_on_smooth_loop_timer_timeout
	)

	add_child(loop_timer)

	loop_timer.start()


func _on_smooth_loop_timer_timeout() -> void:
	if active_player == null:
		return

	if is_stopping:
		return

	if remaining_loops == 0:
		return

	var old_player = active_player
	var new_player = _get_inactive_player()

	if new_player == null:
		return

	if remaining_loops > 0:
		remaining_loops -= 1

	new_player.stream = old_player.stream
	new_player.bus = old_player.bus
	new_player.volume_db = _volume_to_db(0.0)

	if (
		new_player is AudioStreamPlayer2D
		and old_player is AudioStreamPlayer2D
	):
		new_player.global_position = old_player.global_position

	active_player = new_player

	active_player.play()

	var smooth_time = _get_smooth_time()

	_fade_specific_player(
		old_player,
		0.0,
		smooth_time,
		true
	)

	set_volume(base_volume, smooth_time)

	_schedule_smooth_loop()


func _on_active_player_finished() -> void:
	if is_stopping:
		return

	if smooth_loop:
		return

	if remaining_loops == -1:
		active_player.play()
		return

	remaining_loops -= 1

	if remaining_loops > 0:
		active_player.play()
		return

	active_player = null
	queue_free()


func _get_inactive_player() -> Node:
	if active_player == global_player:
		return spatial_player

	return global_player


func _fade_specific_player(
	player: Node,
	target_volume: float,
	time: float,
	stop_after_fade: bool = false
) -> void:
	if player == null:
		return

	var start_volume = _db_to_volume(player.volume_db)

	var tween = create_tween()

	tween.tween_method(
		func(value: float):
			if player != null:
				player.volume_db = _volume_to_db(value),
		start_volume,
		target_volume,
		max(time, 0.01)
	)

	if stop_after_fade:
		tween.finished.connect(
			func():
				if player != null:
					player.stop()
		)


func _get_smooth_time() -> float:
	if active_player == null:
		return 0.0

	if active_player.stream == null:
		return 0.0

	return active_player.stream.get_length() * smooth_factor


func _clear_loop_timer() -> void:
	if (
		loop_timer != null
		and is_instance_valid(loop_timer)
	):
		loop_timer.queue_free()

	loop_timer = null


func _kill_volume_tween() -> void:
	if (
		volume_tween != null
		and is_instance_valid(volume_tween)
	):
		volume_tween.kill()

	volume_tween = null


func _volume_to_db(volume: float) -> float:
	var linear = clamp(volume, 0.0, 100.0) / 100.0

	if linear <= 0.0:
		return -80.0

	return linear_to_db(linear)


func _db_to_volume(db: float) -> float:
	if db <= -80.0:
		return 0.0

	return clamp(
		db_to_linear(db) * 100.0,
		0.0,
		100.0
	)
