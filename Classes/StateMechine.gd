class_name StateMechine

extends Node

var CurrentState : int = -1:
	set(v):
		owner.transition_state(CurrentState, v)
		CurrentState = v
		StateTime = 0

var StateTime : float

func _ready() -> void:
	await owner.ready
	CurrentState = 0

func _physics_process(delta: float) -> void:
	while true:
		var next := owner.get_next_state(CurrentState) as int
		if next == CurrentState:
			break # 状态稳定后退出
		else:
			CurrentState = next

	owner.tick_physics(CurrentState,delta) # 状态稳定后执行对应动作
	StateTime += delta
