extends CharacterBody2D
 
signal health_changed(new_health: int)
signal died
 
#movement
const SPEED = 200.0
const JUMP_VELOCITY = -300.0
 
#health
@export var max_health: int = 100
 
#fall damage (distances are in pixels)
const SAFE_FALL_DISTANCE = 60.0   # falls shorter than this do no damage
const DAMAGE_PER_PIXEL = 0.5       # damage for every pixel beyond the safe distance
 
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var healthBar = $healthbar
@onready var sfx_jump: AudioStreamPlayer2D = $sfx_jump

var health: int
var highest_y: float   # highest point reached during the current airtime (smaller y = higher)
var is_dead := false
var is_hurt := false
 
 
func _ready() -> void:
	health = max_health
	highest_y = global_position.y
	healthBar.max_value = max_health
	healthBar.value = health
 
 
func _physics_process(delta: float) -> void:
	if is_dead or is_hurt:
		return
 
	var was_on_floor := is_on_floor()
 
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
 
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
 
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
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
		sfx_jump.play()
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
		# In the air: remember the highest point (so jumping up and then falling counts correctly).
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
