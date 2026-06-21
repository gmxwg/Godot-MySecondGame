extends Enemy

enum State {
	IDLE,
	WALK,
	RUN
}

func tick_physics(state : State, delta: float) -> void:
	match state:
		State.IDLE:
			move(0.0,delta)
		State.WALK:
			move(MaxSpeed / 3, delta)
		State.RUN:
			if $Graphics/WallChecker.is_colliding() or not $Graphics/FloorChecker.is_colliding():
				direction *= -1
			move(MaxSpeed, delta)
			if $Graphics/PlayerChecker.is_colliding():
				$CalmDownTimer.start()
			
func get_next_state(state: State) -> State:
	if $Graphics/PlayerChecker.is_colliding():
		return State.RUN
		
	match state:
		State.IDLE:
			if $StateMechine.StateTime > 2:
				return State.WALK
		
		State.WALK:
			if $Graphics/WallChecker.is_colliding() or not $Graphics/FloorChecker.is_colliding():
				return State.IDLE
		
		State.RUN:
			if $CalmDownTimer.is_stopped():
				return State.WALK
				
	return state

func transition_state(from : State, to : State) -> void:
	print(from,"->",to)
	match to:
		State.IDLE:
			$AnimationPlayer.play("idle")
			if $Graphics/WallChecker.is_colliding():
				direction *= -1
		State.WALK:
			$AnimationPlayer.play("walk")
			if not $Graphics/FloorChecker.is_colliding():
				direction *= -1
				$Graphics/FloorChecker.force_raycast_update()
				
		State.RUN:
			$AnimationPlayer.play("run")
			
