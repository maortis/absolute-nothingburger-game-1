extends Control
## Start menu (Inmost-style): pixel-art night scene, the hero idling on a floating ledge
## in the middle, text-only menu underneath.

const IDLE_SHEET := preload("res://assets/sprite/Luneblade - Little Axion (Free)/Sprite Sheet/Idle.png")
const FRAME := 144

@onready var world: Node2D = $World
@onready var bg: Sprite2D = $World/Bg
@onready var far_tree: Sprite2D = $World/FarTree
@onready var big_tree: Sprite2D = $World/BigTree
@onready var fog: Sprite2D = $World/Fog
@onready var ground: Sprite2D = $World/Ground
@onready var ledge: Sprite2D = $World/Ledge
@onready var hero: AnimatedSprite2D = $World/Hero
@onready var fireflies: CPUParticles2D = $World/Fireflies

@onready var start_button: Button = %StartButton
@onready var save_load_button: Button = %SaveLoadButton
@onready var exit_button: Button = %ExitButton
@onready var save_load_panel = $SaveLoadPanel
@onready var fade: ColorRect = $Fade


func _ready() -> void:
	hero.sprite_frames = _make_idle_frames()
	hero.play("idle")

	start_button.pressed.connect(_on_start)
	save_load_button.pressed.connect(_on_save_load)
	exit_button.pressed.connect(get_tree().quit)
	exit_button.visible = not OS.has_feature("web")   # browsers can't "quit"
	save_load_panel.closed.connect(save_load_button.grab_focus)

	get_viewport().size_changed.connect(_layout)
	_layout()
	start_button.grab_focus()

	fade.color.a = 1.0
	create_tween().tween_property(fade, "color:a", 0.0, 0.8)


## Pixel-perfect layout: everything in World is drawn at native pixel size and scaled
## by a whole number, so the art stays crisp at any window size.
func _layout() -> void:
	var vp := get_viewport_rect().size
	var s := maxf(1.0, floorf(vp.y / 160.0))
	world.scale = Vector2(s, s)
	var w := vp.x / s
	var h := vp.y / s

	# background: cover the screen
	var tex_size := bg.texture.get_size()
	var cover := ceilf(maxf(w / tex_size.x, h / tex_size.y))
	bg.scale = Vector2(cover, cover)
	bg.position = Vector2(w / 2.0, h - tex_size.y * cover / 2.0)

	var ground_top := h - 16.0
	ground.region_rect = Rect2(0, 0, w + 16.0, 20)
	ground.position = Vector2(0, h - 20.0)

	far_tree.position = Vector2(-8.0, ground_top + 3.0 - far_tree.texture.get_height() * far_tree.scale.y)
	big_tree.position = Vector2(w - big_tree.texture.get_width() * 0.78, ground_top + 4.0 - big_tree.texture.get_height())

	fog.scale = Vector2(w + 2.0, h / 64.0)
	fog.position = Vector2.ZERO

	# hero on a floating ledge in the centre
	var ledge_top := roundf(h * 0.46)
	ledge.position = Vector2(roundf(w / 2.0 - ledge.texture.get_width() / 2.0), ledge_top)
	hero.position = Vector2(roundf(w / 2.0) + 4.0, ledge_top - 6.0)

	fireflies.position = Vector2(w / 2.0, h / 2.0)
	fireflies.emission_rect_extents = Vector2(w / 2.0, h / 2.0)


func _make_idle_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 5.0)
	frames.set_animation_loop("idle", true)
	for i in IDLE_SHEET.get_width() / FRAME:
		var at := AtlasTexture.new()
		at.atlas = IDLE_SHEET
		at.region = Rect2(i * FRAME, 0, FRAME, FRAME)
		frames.add_frame("idle", at)
	return frames


func _on_start() -> void:
	_set_menu_enabled(false)
	var t := create_tween()
	t.tween_property(fade, "color:a", 1.0, 0.5)
	t.tween_callback(SaveManager.new_game)


func _on_save_load() -> void:
	save_load_panel.open("load", "Tip: save while playing from the pause menu (Esc).")


func _set_menu_enabled(on: bool) -> void:
	for b in [start_button, save_load_button, exit_button]:
		b.disabled = not on
