extends Node
## 音频占位实现：BGM 与一次性音效。正式资源到位后替换 play_sfx 的调用点即可。

var music_volume: float = 0.8
var sfx_volume: float = 1.0

var _music_player: AudioStreamPlayer


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	add_child(_music_player)


func play_music(stream: AudioStream) -> void:
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.volume_db = linear_to_db(clampf(music_volume, 0.001, 1.0))
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db + linear_to_db(clampf(sfx_volume, 0.001, 1.0))
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

