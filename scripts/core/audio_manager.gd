extends Node
# Autoload "Audio": música de fundo + efeitos sonoros.
# Para trocar os sons por um pacote online, basta colocar os arquivos novos em
# assets/audio/ com os MESMOS nomes (ou editar MUSIC_PATH / SFX abaixo).
# Arquivos que não existirem são ignorados, então nada quebra.

const MUSIC_PATH := "res://assets/audio/music_town.ogg"
const SFX := {
	"attack": "res://assets/audio/sfx_attack.ogg",
	"hurt": "res://assets/audio/sfx_hurt.ogg",
	"death": "res://assets/audio/sfx_death.ogg",
	"revive": "res://assets/audio/sfx_revive.ogg",
	"levelup": "res://assets/audio/sfx_levelup.ogg",
	"step": "res://assets/audio/sfx_step.ogg",
	"click": "res://assets/audio/sfx_click.ogg",
	"open": "res://assets/audio/sfx_open.ogg",
	"close": "res://assets/audio/sfx_close.ogg"
}
const SFX_VOICES := 6

var _music: AudioStreamPlayer
var _voices: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}
var _next_voice: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")

	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)

	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_voices.append(p)

	apply_volumes()
	play_music()


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func apply_volumes() -> void:
	_set_bus_volume("Music", Game.music_volume)
	_set_bus_volume("SFX", Game.sfx_volume)


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.001)))


func play_music() -> void:
	var stream := _load(MUSIC_PATH)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamMP3:
		stream.loop = true
	_music.stream = stream
	_music.play()


func play_sfx(sfx_name: String, pitch_jitter: float = 0.0) -> void:
	if not SFX.has(sfx_name):
		return
	var stream := _load(SFX[sfx_name])
	if stream == null:
		return
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = stream
	voice.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	voice.play()


func _load(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		_cache[path] = null
		return null
	var res := load(path)
	_cache[path] = res
	return res