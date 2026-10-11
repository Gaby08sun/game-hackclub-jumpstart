class_name Player
extends CharacterBody2D

signal died

const SPEED: float = 260.0
const JUMP_VELOCITY: float = -460.0
const COYOTE_TIME: float = 0.12
const JUMP_BUFFER_TIME: float = 0.12
const DEATH_Y: float = 1000.0

@export var character_texture: Texture2D

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0


func _ready() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	var visual := get_node_or_null("Visual") as CanvasItem
	if character_texture != null and sprite != null:
		sprite.texture = character_texture
	if sprite != null and sprite.texture != null:
		var tex_size := sprite.texture.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			sprite.scale = Vector2(28.0 / tex_size.x, 28.0 / tex_size.y)
		if visual != null:
			visual.visible = false


func _physics_process(delta: float) -> void:
	# Gravity and Coyote Time
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)
		velocity.y += gravity * delta

	# Jump Buffer (Space, Up Arrow, W)
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)

	# Single jump
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	# Horizontal movement (Arrows and A/D)
	var dir := Input.get_axis("ui_left", "ui_right")
	if dir == 0.0:
		dir = Input.get_axis("left", "right")
	velocity.x = dir * SPEED

	move_and_slide()

	if global_position.y > DEATH_Y:
		die()


func die() -> void:
	died.emit()


func reset_to(spawn_position: Vector2) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
