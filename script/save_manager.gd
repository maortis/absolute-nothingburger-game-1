extends Node
## Autoload "SaveManager": starting the game, going back to the menu, and 3 save slots.
## Saves live in user://save_1.cfg ... save_3.cfg (works on PC and in web builds).

const GAME_SCENE := "res://scenes/game.tscn"
const MENU_SCENE := "res://ui/start_menu.tscn"
const SLOT_COUNT := 3

var _pending := {}   # save data waiting to be applied after a scene loads


func _ready() -> void:
	get_tree().scene_changed.connect(_apply_pending)


# ---------- scene flow ----------

func new_game() -> void:
	_pending = {}
	_change(GAME_SCENE)


func go_to_menu() -> void:
	_pending = {}
	_change(MENU_SCENE)


func _change(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)


# ---------- slots ----------

func slot_path(i: int) -> String:
	return "user://save_%d.cfg" % (i + 1)


func has_save(i: int) -> bool:
	return FileAccess.file_exists(slot_path(i))


func read_slot(i: int) -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(slot_path(i)) != OK:
		return {}
	var d := {}
	for key in cfg.get_section_keys("save"):
		d[key] = cfg.get_value("save", key)
	return d


## Short text for a slot button, e.g. "Slot 1   05 Nov 21:30   HP 85/100"
func slot_label(i: int) -> String:
	var d := read_slot(i)
	if d.is_empty():
		return "Slot %d   - empty -" % (i + 1)
	return "Slot %d   %s   HP %d/%d" % [i + 1, d.get("saved_at", "?"), d.get("health", 0), d.get("max_health", 0)]


## Saves the player in the current scene. Returns false if there is no player.
func save_to_slot(i: int) -> bool:
	var p := find_player()
	if p == null:
		return false
	var cfg := ConfigFile.new()
	cfg.set_value("save", "scene", get_tree().current_scene.scene_file_path)
	cfg.set_value("save", "x", p.global_position.x)
	cfg.set_value("save", "y", p.global_position.y)
	cfg.set_value("save", "health", p.health)
	cfg.set_value("save", "max_health", p.max_health)
	cfg.set_value("save", "saved_at", Time.get_datetime_string_from_system(false, true).substr(5, 11).replace("T", " "))
	return cfg.save(slot_path(i)) == OK


func load_slot(i: int) -> void:
	var d := read_slot(i)
	if d.is_empty():
		return
	_pending = d
	_change(d.get("scene", GAME_SCENE))


func delete_slot(i: int) -> void:
	if has_save(i):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(i)))


# ---------- helpers ----------

## Finds the player: the first CharacterBody2D that has a "health" variable.
func find_player() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	for n in scene.find_children("*", "CharacterBody2D", true, false):
		if "health" in n:
			return n
	return null


func _apply_pending() -> void:
	if _pending.is_empty():
		return
	var d := _pending
	_pending = {}
	var p := find_player()
	if p == null:
		return
	p.global_position = Vector2(d.get("x", 0.0), d.get("y", 0.0))
	p.velocity = Vector2.ZERO
	p.health = int(d.get("health", p.max_health))
	if "highest_y" in p:
		p.highest_y = p.global_position.y   # so loading doesn't count as a fall
	if "healthBar" in p and p.healthBar:
		p.healthBar.value = p.health
	if p.has_signal("health_changed"):
		p.health_changed.emit(p.health)
