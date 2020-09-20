extends KinematicBody2D

export var MAX_SPEED = 500.0
export var ACCELERATION = 1000.0
export var FRICTION = 10000.0
export var BOOST_FORCE = 1000
export var GRAVITY = Vector2(0, 50)
export var TERMINAL_VELOCITY = 10000.0

enum PlayerCommand {
	Boost,
	BoostEnd,
	Attack,
	None
}

enum PlayerStatus {
	Idle,
	Attack,
	Boost
}

class PlayerState:
	var velocity = Vector2.ZERO
	var state = PlayerStatus.Idle
	var direction = 1.0
	var last_floor = -1.0
	func clone():
		var retval = PlayerState.new()
		retval.velocity = self.velocity
		retval.state = self.state
		retval.direction = self.direction
		retval.last_floor = self.last_floor
		return retval

var state = PlayerState.new()
var cmd_queue = []

onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback");

signal status_changed(status)
signal direction_changed(direction)

func _ready() -> void:
	animationTree.active = true
	
func get_input_vector(): 
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	#input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_vector = input_vector.clamped(1.0)
	return input_vector
	
func get_command():
	if Input.is_action_just_pressed("ui_accept"):
		return PlayerCommand.Attack
	elif Input.is_action_just_pressed("ui_cancel"):
		return PlayerCommand.Boost
	elif cmd_queue.size() > 0:
		return cmd_queue.pop_front()
	else:
		return PlayerCommand.None
	
func _physics_process(delta):
	# Get all inputs
	var input = get_input_vector()
	var cmd = get_command();
	
	# compute changes to state
	state = apply_cmd(delta, cmd, input, state)
		
	# apply new state
	state.velocity = move_and_slide(state.velocity, Vector2(0, -1))
	update_animation()

func queue_cmd(cmd): 
	cmd_queue.push_back(cmd)

func apply_cmd(delta, cmd, input, current_state):
	var new_state = current_state.clone()
	new_state.last_floor = new_state.last_floor + 1 if !is_on_floor() else 0
	match cmd:
		PlayerCommand.Attack: 
			pass
		PlayerCommand.Boost:
			if state.state != PlayerStatus.Boost && new_state.last_floor < 10:
				new_state.velocity.y = -BOOST_FORCE
				new_state.state = PlayerStatus.Boost
			else: 
				continue
		PlayerCommand.None:
			# allow input to influence velocity --if not boosting and not falling
			if input != Vector2.ZERO:
				# use friction if input is against current velocity
				if input.x * current_state.velocity.x < 0:
					new_state.velocity = current_state.velocity.move_toward(input * MAX_SPEED, FRICTION * delta)
				# use acceleration if input is in the same direction as current velocity
				else:
					new_state.velocity = current_state.velocity.move_toward(input * MAX_SPEED, ACCELERATION * delta)
					
				# compute new direction
				new_state.direction = Vector2(new_state.velocity.x, 0).normalized().x
				
				# check if direction has changed and emit signal
				if new_state.direction * current_state.direction < 0:
					emit_signal("direction_changed", new_state.direction)
			# dampen velocity
			else:
				new_state.velocity = current_state.velocity.move_toward(Vector2(0.0, current_state.velocity.y), FRICTION * delta)
				
			# deactivate boost if player is falling
			if new_state.state == PlayerStatus.Boost && (new_state.velocity.y > 0):
				new_state.state = PlayerStatus.Idle
			new_state.velocity = new_state.velocity + GRAVITY
	return new_state

func update_animation():
	match state.state:
		PlayerStatus.Attack:
			pass
		PlayerStatus.Boost:
			emit_signal("status_changed", "Boosting")
			update_direction("Boosting")
			animationState.travel("Boosting")
		PlayerStatus.Idle:
			var animation = "Idle"
			if !is_on_floor() && state.velocity.y > 0:
				animation = "Falling"
			elif abs(state.velocity.x) > 0:
				animation = "Moving"
			emit_signal("status_changed", animation)
			update_direction(animation)
			animationState.travel(animation)
				
func update_direction(animation):
	animationTree.set("parameters/Landing/blend_position", state.direction)
	if animation == "Moving":
		animationTree.set("parameters/%s/blend_position" % animation, Vector2(state.direction,0.0))
	else:
		animationTree.set("parameters/%s/blend_position" % animation, state.direction)
