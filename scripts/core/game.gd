extends Node

signal profile_changed

const GAME_NAME := "Eternal Legends"
const VERSION := "0.2.0"
const SAVE_PATH := "user://profile.cfg"

# Classes disponíveis: "frame" é o índice da peça em assets/characters/tiny_dungeon.png.
const CLASSES := [
	{"name": "Guerreiro", "frame": 96},
	{"name": "Arqueiro", "frame": 112},
	{"name": "Mago", "frame": 84}
]

var player_name: String = "Herói"
var class_frame: int = 96
var level: int = 1
var xp: int = 0
var music_volume: float = 0.7
var sfx_volume: float = 0.9


func _ready() -> void:
	load_profile()


func class_name_of(frame: int) -> String:
	for c in CLASSES:
		if c["frame"] == frame:
			return c["name"]
	return "Aventureiro"


func xp_to_next() -> int:
	return 40 + level * 20


# Retorna true se subiu de nível.
func add_xp(amount: int) -> bool:
	xp += amount
	var leveled := false
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		leveled = true
	profile_changed.emit()
	save_profile()
	return leveled


func save_profile() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "name", player_name)
	cfg.set_value("profile", "class_frame", class_frame)
	cfg.set_value("profile", "level", level)
	cfg.set_value("profile", "xp", xp)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.save(SAVE_PATH)


func load_profile() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	player_name = cfg.get_value("profile", "name", player_name)
	class_frame = cfg.get_value("profile", "class_frame", class_frame)
	level = cfg.get_value("profile", "level", level)
	xp = cfg.get_value("profile", "xp", xp)
	music_volume = cfg.get_value("audio", "music", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)