extends KinematicBody2D

const MAX_SPEED = 500.0
const ACCELERATION = 1000.0
const FRICTION = 10000.0
const BOOST_FORCE = 1000
const GRAVITY = Vector2(0, 50)
const TERMINAL_VELOCITY = 10000.0

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
	pass

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
		PlayerCommand.None:
			# allow input to influence velocity --if not boosting and not falling
			if input != Vector2.ZERO:
				if input.x * new_state.velocity.x < 0:
					new_state.velocity = current_state.velocity.move_toward(input * MAX_SPEED, FRICTION * delta)
				else:
					new_state.velocity = current_state.velocity.move_toward(input * MAX_SPEED, ACCELERATION * delta)
				new_state.direction = new_state.velocity.x
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
			animationTree.set("parameters/Boosting/blend_position", state.direction)
			animationState.travel("Boosting")
		PlayerStatus.Idle:
			var animation = "Idle"
			if !is_on_floor() && state.velocity.y > 0:
				animation = "Falling"
			elif abs(state.velocity.x) > 0:
				animation = "Moving"
			emit_signal("status_changed", animation)
			animationTree.set("parameters/Landing/blend_position", state.direction)
			animationTree.set("parameters/%s/blend_position" % animation, state.direction)
			animationState.travel(animation)
				
		
#	match state:
#		MOVING:
#			move_process(cmd, delta, input)
#		ATTACKING:
#			attack_process(cmd, delta, input)
#		DASHING:
#			dash_process(cmd, delta, input)
#		FALLING:
#			fall_process(cmd, delta, input)
#		IDLE:
#			idle_process(cmd, delta, input)
#
#	if state != ATTACK && Input.is_action_just_pressed("ui_accept"):
#		if input != Vector2.ZERO:
#			pass #animationTree.set("parameters/Attack/blend_position", input)
#		velocity = Vector2.ZERO
#		state = ATTACK
#
#	velocity = move_and_slide(velocity + GRAVITY)
#
#	if state != ROLL && Input.is_action_just_pressed("ui_cancel") && input.length() > 0:
#		pass #animationTree.set("parameters/Roll/blend_position", input)
#		velocity = input * MAX_SPEED * ROLL_MULTIPLIER
#		state = ROLL
#
#func idle_process(cmd, delta, input):
#	state = IDLE
#func attack_state(cmd, delta, input):
#	state = IDLE
#
#func roll_state(cmd, delta, input):
#	pass
#
#func move_state(cmd, delta, input):
#	if input != Vector2.ZERO:
#		animationTree.set("parameters/Idle/blend_position", input.x)
#		animationTree.set("parameters/Moving/blend_position", input.x)
#		#animationTree.set("parameters/Attack/blend_position", input)
#		animationState.travel("Moving")
#		velocity = velocity.move_toward(input * MAX_SPEED, ACCELERATION * delta)
#	else:
#		animationState.travel("Idle")
#		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
