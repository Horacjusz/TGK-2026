extends VBoxContainer

@onready var master: HSlider = $Master
@onready var music: HSlider = $Music
@onready var sfx: HSlider = $SFX


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	master.value_changed.connect(_on_master_value_changed)
	music.value_changed.connect(_on_music_value_changed)
	sfx.value_changed.connect(_on_sfx_value_changed)
	pass # Replace with function body.

func set_sliders() :
	#if Globals.audio == null : return
	master.value = Globals.audio.master_volume
	music.value = Globals.audio.music_volume
	sfx.value = Globals.audio.sfx_volume

func _on_master_value_changed(value: float) -> void:
	Globals.audio.master_volume = value

func _on_music_value_changed(value: float) -> void:
	Globals.audio.music_volume = value

func _on_sfx_value_changed(value: float) -> void:
	Globals.audio.sfx_volume = value

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
