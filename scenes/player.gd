extends CharacterBody2D

signal health_changed(new_health: int)
signal died

#movement
const SPEED = 150.0
const JUMP_VELOCITY = -300.0

#coyote time
const COYOTE_TIME = 0.1

#health
@export var max_health: int = 100

#fall damage (distances are in pixels)
const SAFE_FALL_DISTANCE = 60.0
const DAMAGE_PER_PIXEL = 0.5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var healthBar = $healthbar
@onready var sfx_jump: AudioStreamPlayer2D = $sfx_jump
@onready var ray_left: RayCast2D = $RayLeft
@onready var ray_right: RayCast2D = $RayRight

var health: int
var highest_y: float
var is_dead := false
var is_hurt := false
var coyote_timer := 0.0


func _ready() -> void:
	health = max_health
	highest_y = global_position.y
	healthBar.max_value = max_health
	healthBar.value = health


func _is_grounded_ray() -> bool:
	ray_left.force_raycast_update()
	ray_right.force_raycast_update()
	return ray_left.is_colliding() or ray_right.is_colliding()


func _physics_process(delta: float) -> void:
	if is_dead or is_hurt:
		return

	var was_on_floor := is_on_floor()

	# Gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Coyote timer: isi ulang saat di tanah (dan tidak sedang naik),
	# kurangi saat di udara.
	var grounded := (is_on_floor() or _is_grounded_ray()) and velocity.y >= 0.0
	if grounded:
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	# Jump: pakai coyote_timer, bukan is_on_floor().
	if Input.is_action_just_pressed("jump") and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0
		sfx_jump.play()

	var direction := Input.get_axis("move_left", "move_right")
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	_handle_fall_damage(was_on_floor)


func _handle_fall_damage(was_on_floor: bool) -> void:
	if is_on_floor():
		# Just landed this frame: measure how far we fell.
		if not was_on_floor:
			var fall_distance := global_position.y - highest_y
			if fall_distance > SAFE_FALL_DISTANCE:
				take_damage(int((fall_distance - SAFE_FALL_DISTANCE) * DAMAGE_PER_PIXEL))
		highest_y = global_position.y
	else:
		# In the air: remember the highest point.
		highest_y = min(highest_y, global_position.y)


func take_damage(amount: int) -> void:
	if is_dead or is_hurt or amount <= 0:
		return
	health = max(health - amount, 0)
	healthBar.value = health
	health_changed.emit(health)
	if health == 0:
		die()
	else:
		is_hurt = true
		animated_sprite.play("hurt")
		await animated_sprite.animation_finished
		is_hurt = false


func heal(amount: int) -> void:
	if is_dead:
		return
	health = min(health + amount, max_health)
	healthBar.value = health
	health_changed.emit(health)


func die() -> void:
	is_dead = true
	died.emit()
	velocity = Vector2.ZERO
	animated_sprite.play("death")
	await animated_sprite.animation_finished
	# Simple respawn: reload the level after a short delay.
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()
