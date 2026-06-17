extends CharacterBody2D

enum State {
	IDLE,
	RUNNING,
	JUMP,
	FALL,
	LANDING
}

var GroundState = [State.RUNNING,State.IDLE,State.LANDING]

const RunSpeed : float = 160.0
const JumpVelocity : float = -320.0
const FLOOR_ACCELERATION := RunSpeed / 0.2 #  加速度 /s
const AIR_ACCELERATION := RunSpeed / 0.02
var IsFirstTick: bool = false
var DefaultGravity : float = ProjectSettings.get("physics/2d/default_gravity") # 从项目设置里面拿默认重力加速度

func _unhandled_input(event: InputEvent) -> void: # 在落地前0.1内秒按下按键也可以实现跳跃，不用等落地再按
	if event.is_action_pressed("jump"):
		$JumpRequestTimer.start()
	if event.is_action_released("jump"):
		$JumpRequestTimer.stop() # 这样就跟完全没有按过一样，避免因这个时间导致短按促发大跳
		if velocity.y < JumpVelocity / 2:
			velocity.y = JumpVelocity / 2 # 速度是从320一直变小慢慢到0的，如果在我松开按键的瞬间，速度还处于比较大的水平，也就是越早松开，那就直接把速度变为一半，更快回落
		
func tick_physics(state : State, delta: float) -> void: # 根据状态执行动作
	match state:
		State.IDLE:
			move(DefaultGravity,delta)
		State.RUNNING:
			move(DefaultGravity,delta)
		State.JUMP:
			move(0.0 if IsFirstTick else DefaultGravity,delta)
		State.FALL:
			move(DefaultGravity,delta)
		State.LANDING:
			stand(delta)
			
	IsFirstTick = false
			
func move(gravity: float, delta: float) -> void:
	var direction : float = Input.get_axis("move_left","move_right") # 接收两个输入，一个返回负，一个返回正,不按或者同时按左右返回0
	var accleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, direction * RunSpeed, accleration* delta)
	velocity.y += gravity * delta # 每一帧叠加重力，抵消向上的速度
	
	if not is_zero_approx(direction):
		$Sprite2D.flip_h = direction < 0
		
	move_and_slide()

func stand(delta: float) -> void:
	var accleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, 0.0, accleration * delta)
	velocity.y += DefaultGravity * delta
	
	move_and_slide()
	
func get_next_state(state : State) -> State:
	var direction : float = Input.get_axis("move_left","move_right") # 接收两个输入，一个返回负，一个返回正,不按或者同时按左右返回0
	var still = is_zero_approx(direction) and is_zero_approx(velocity.x) # 表示此时是否为站立状态
	
	var CanJump : bool = is_on_floor() or $CoyoteTimer.time_left > 0
	var ShouldJump : bool = CanJump and $JumpRequestTimer.time_left > 0
	if ShouldJump:
		state = State.JUMP
	
	match state:
		State.IDLE:
			if not is_on_floor():
				state = State.FALL
			elif not still:
				state = State.RUNNING
		State.RUNNING:
			if not is_on_floor():
				state = State.FALL
			elif still:
				state = State.IDLE
		State.JUMP:
			if velocity.y > 0:
				state = State.FALL
		State.FALL:
			if is_on_floor():
				if still:
					state = State.LANDING
				else:
					state = State.RUNNING
		State.LANDING:
			if not $AnimationPlayer.is_playing():
				state = State.IDLE
	
	return state
	
func transition_state(from : State, to : State) -> void: # 每次状态转移时调用，每一帧都会检查状态切换，根据状态播放动画
	if from not in GroundState and to in GroundState: # 如果着陆了
		$CoyoteTimer.stop()
		
	match to:
		State.IDLE:
			$AnimationPlayer.play("idle")
		State.RUNNING:
			$AnimationPlayer.play("running")
		State.JUMP:
			$AnimationPlayer.play("jump")
			velocity.y = JumpVelocity
			$CoyoteTimer.stop()
			$JumpRequestTimer.stop()
		State.FALL:
			$AnimationPlayer.play("fall")
			if from in GroundState and to not in GroundState:
				$CoyoteTimer.start()
		State.LANDING:
			$AnimationPlayer.play("landing")
	IsFirstTick = true
