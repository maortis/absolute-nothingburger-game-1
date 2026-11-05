@tool
extends Area2D
## "Duri" = thorns. Hurts anything with take_damage() that touches it.
## Drag scenes/duri.tscn into a level; the node's position is the BOTTOM-LEFT corner,
## so put it right on the ground. Change "Length Tiles" in the Inspector to make it longer.

@export_range(1, 30) var length_tiles: int = 3:
	set(v):
		length_tiles = v
		_resize()
@export var damage: int = 15
@export var hit_interval: float = 1.0   # seconds between hits while standing in it

const TILE_W := 16.0
const TILE_H := 12.0

var _timers := {}   # body -> seconds until the next hit


func _ready() -> void:
	_resize()
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _resize() -> void:
	if not is_inside_tree():
		return
	var w := TILE_W * length_tiles
	var sprite: Sprite2D = $Sprite2D
	sprite.region_rect = Rect2(0, 0, w, TILE_H)
	var shape: CollisionShape2D = $CollisionShape2D
	(shape.shape as RectangleShape2D).size = Vector2(w - 4.0, 8.0)
	shape.position = Vector2(w / 2.0, -4.0)


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		_hurt(body)
		_timers[body] = hit_interval


func _on_body_exited(body: Node) -> void:
	_timers.erase(body)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	for body in _timers.keys():
		if not is_instance_valid(body):
			_timers.erase(body)
			continue
		_timers[body] -= delta
		if _timers[body] <= 0.0:
			_hurt(body)
			_timers[body] = hit_interval


func _hurt(body: Node) -> void:
	body.take_damage(damage)
	# little red flash on the thorns
	var t := create_tween()
	t.tween_property($Sprite2D, "modulate", Color(1.6, 0.7, 0.7), 0.05)
	t.tween_property($Sprite2D, "modulate", Color.WHITE, 0.25)
