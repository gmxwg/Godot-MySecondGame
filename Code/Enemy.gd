class_name Enemy

extends CharacterBody2D

enum Direction {
	LEFT = -1,
	RIGHT = 1
}

@export var direction := Direction.LEFT:
	set(v):
		direction = v
		if not is_node_ready():
			await ready
		$Graphics.scale.x = direction * -1

@export var MaxSpeed: float = 180
@export var accleration: float = 2000

var DefaultGravity : float = ProjectSettings.get("physics/2d/default_gravity")

func move(speed: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, direction * speed, accleration* delta)
	velocity.y += DefaultGravity * delta # 每一帧叠加重力，抵消向上的速度
	
	move_and_slide()
