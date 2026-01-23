extends CharacterBody2D

const SPEED := 300.0

@onready var spawner := $BulletSpawner   # Your child node that handles bullets

func _physics_process(delta: float) -> void:
	# --- Movement ---
	var direction := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)

	if direction != Vector2.ZERO:
		velocity = direction.normalized() * SPEED
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# --- Shooting ---
	if Input.is_action_just_pressed("fire"):   # fire = spacebar in Input Map
		spawner.shoot()
