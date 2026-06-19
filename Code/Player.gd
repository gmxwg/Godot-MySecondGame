extends CharacterBody2D

enum State {
	IDLE,
	RUNNING,
	JUMP,
	FALL,
	LANDING,
	WALL_SLIDING,
	WALL_JUMP
}

var GroundState = [State.RUNNING,State.IDLE,State.LANDING]

const RunSpeed : float = 160.0
const JumpVelocity : float = -320.0
const FLOOR_ACCELERATION := RunSpeed / 0.2 #  加速度 /s
const AIR_ACCELERATION := RunSpeed / 0.1
var IsFirstTick: bool = false
var DefaultGravity : float = ProjectSettings.get("physics/2d/default_gravity") # 从项目设置里面拿默认重力加速度
var WallJumpVelocity := Vector2(380,-300)

func _unhandled_input(event: InputEvent) -> void: # 在落地前0.1内秒按下按键也可以实现跳跃，不用等落地再按
	if event.is_action_pressed("jump"):
		$JumpRequestTimer.start()
	if event.is_action_released("jump"):
		$JumpRequestTimer.stop() # 这样就跟完全没有按过一样，避免因这个时间导致短按促发大跳
		if velocity.y < JumpVelocity / 2:
			velocity.y = JumpVelocity / 2 # 速度是从320一直变小慢慢到0的，如果在我松开按键的瞬间，速度还处于比较大的水平，也就是越早松开，那就直接把速度变为一半，更快回落
		
func tick_physics(state : State, delta: float) -> void: # 根据状态执行对应物理动作
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
			stand(DefaultGravity,delta)
		State.WALL_SLIDING:
			move(DefaultGravity / 3,delta)
			
		State.WALL_JUMP:
			if $StateMechine.StateTime < 0.1: # 在蹬墙的前0.1秒忽略角色方向,即保证刚跳的方向和墙壁一致
				$Graphics.scale.x = get_wall_normal().x # 如果在0.1秒内撞到别的墙就会调转方向
				stand(0.0 if IsFirstTick else DefaultGravity, delta)
			else:
				move(0.0 if IsFirstTick else DefaultGravity,delta)
			
	IsFirstTick = false
			
func move(gravity: float, delta: float) -> void:
	var direction : float = Input.get_axis("move_left","move_right") # 接收两个输入，一个返回负，一个返回正,不按或者同时按左右返回0
	var accleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, direction * RunSpeed, accleration* delta)
	velocity.y += gravity * delta # 每一帧叠加重力，抵消向上的速度
	
	if not is_zero_approx(direction):
		$Graphics.scale.x = -1 if direction < 0 else 1
		
	move_and_slide()

func stand(gravity: float, delta: float) -> void:
	var accleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, 0.0, accleration * delta)
	velocity.y += gravity * delta
	
	move_and_slide()

func can_wall_slide() -> bool:
	return is_on_wall() and $Graphics/HandChecker.is_colliding() and $Graphics/FootChecker.is_colliding()
func get_next_state(state : State) -> State: # 判断状态是否转移
	var direction : float = Input.get_axis("move_left","move_right") # 接收两个输入，一个返回负，一个返回正,不按或者同时按左右返回0
	var still = is_zero_approx(direction) and is_zero_approx(velocity.x) # 表示此时是否为站立状态
	
	var CanJump : bool = is_on_floor() or $CoyoteTimer.time_left > 0
	var ShouldJump : bool = CanJump and $JumpRequestTimer.time_left > 0
	if ShouldJump:
		return State.JUMP
	
	match state:
		State.IDLE:
			if not is_on_floor():
				return State.FALL
			elif not still:
				return State.RUNNING
		State.RUNNING:
			if not is_on_floor():
				return State.FALL
			elif still:
				return State.IDLE
		State.JUMP:
			if velocity.y >= 0:
				return State.FALL
		State.FALL:
			if is_on_floor():
				if still:
					return State.LANDING
				else:
					return State.RUNNING
			if $WallJumpTimer.time_left > 0 and $JumpRequestTimer.time_left > 0:
				return State.WALL_JUMP
			if can_wall_slide():
				return State.WALL_SLIDING
		State.LANDING:
			if not still:
				return State.RUNNING
			if not $AnimationPlayer.is_playing():
				return State.IDLE
		State.WALL_SLIDING:
			if $JumpRequestTimer.time_left > 0:
				return State.WALL_JUMP
			if is_on_floor():
				return State.IDLE
			if not is_on_wall():
				return State.FALL
				$Graphics.scale.x = get_wall_normal().x
		State.WALL_JUMP:
			if can_wall_slide() and not IsFirstTick: # 要持续两帧状态才会切换，所以切换到第一帧不会切换到WALL_JUMP，此时会重复触发Isonwall
				return State.WALL_SLIDING # 蹬墙跳不需要下落才能滑墙
			if velocity.y > 0:
				return State.FALL
	return state
	
func transition_state(from : State, to : State) -> void: # 每次状态转移时调用，每一帧都会检查状态切换，根据状态播放动画
	if from not in GroundState and to in GroundState: # 如果着陆了
		$CoyoteTimer.stop()
		$WallJumpTimer.stop()
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
			if from == State.WALL_SLIDING:
				$WallJumpTimer.start()
				
		State.LANDING:
			$AnimationPlayer.play("landing")
		State.WALL_SLIDING:
			$AnimationPlayer.play("wall_sliding")
		State.WALL_JUMP:
			$AnimationPlayer.play("jump")
			velocity = WallJumpVelocity
			velocity.x *= get_wall_normal().x # 根据墙来决定跳跃方向
			$JumpRequestTimer.stop()
			
	#if to == State.WALL_JUMP:
		#Engine.time_scale = 0.3
	#if from == State.WALL_JUMP:
		#Engine.time_scale = 1
		
	IsFirstTick = true # 判断是否是第一帧
