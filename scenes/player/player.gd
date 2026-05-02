class_name Player extends CharacterBody3D

enum State {NORMAL, SPRINT, CROUCH, AIRBORNE, IDLE}
var state: State = State.NORMAL

@onready var fps_cam: Camera3D = $CameraHolder/Camera3D
@onready var anim_tree: AnimationTree = $AnimationTree

@export_group("Speeds", "sp")
@export_range(1.0, 20.0, 0.5) var sp_normal: float = 6.5
@export_range(1.0, 20.0, 0.5) var sp_sprint: float = 12.5
@export_range(1.0, 20.0, 0.5) var sp_crouch: float = 2.5
@export_range(1.0, 20.0, 0.5) var sp_change: float = 1.0

@export_subgroup("Anims", "anim")
@export_range(0.0, 2.0, 0.05) var anim_normal: float = 0.4
@export_range(0.0, 2.0, 0.05) var anim_sprint: float = 0.3
@export_range(0.0, 2.0, 0.05) var anim_crouch: float = 0.5
var sp_last: float
@export_group("Jump", "jump")
@export_range(1.0, 20.0, 0.5, "or_greater") var jump_strength: float = 10.0
@export_range(1, 2, 1, "or_greater") var jump_count: int = 2
var jumps_remaining: int = jump_count
@export_group("Camera", "cam")
@export_range(0.001, 0.05, 0.001) var cam_x_sens: float = 0.01
@export_range(0.001, 0.05, 0.001) var cam_y_sens: float = 0.01
var cam_lock: bool = true
@export_range(0.1, 10.0, 0.1) var density: float = 1.0

func _ready() -> void:
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if !cam_lock: return
		rotate_y(-event.relative.x * cam_x_sens)
		fps_cam.rotation.x = clampf(fps_cam.rotation.x - event.relative.y * cam_y_sens, 0.0001-PI/2, PI/2-0.0001)

func _physics_process(delta: float) -> void:
	if is_on_floor(): jumps_remaining = jump_count
	else: velocity += get_gravity() * delta * density
	state = get_state()
	get_state_speed()
	var direction: = Input.get_vector("Left Strafe", "Right Strafe", "Backward Run", "Forward Run").normalized()
	anim_tree["parameters/add_movement/add_amount"] = 2.5 if direction else 0.0
	var dir_localised = Vector3(direction.x, 0, direction.y) * basis.orthonormalized() * Basis.FLIP_Z
	var old_velocity = velocity
	var new_velocity = dir_localised * sp_last
	if Input.is_action_just_pressed("Jump") and can_jump():
		velocity = jump_strength * basis.orthonormalized().y
	velocity.x = move_toward(old_velocity.x, new_velocity.x, sp_change)
	velocity.z = move_toward(old_velocity.z, new_velocity.z, sp_change)
	move_and_slide()
	if Input.is_action_just_pressed("ui_cancel"):
		if DisplayServer.mouse_get_mode() == DisplayServer.MOUSE_MODE_CAPTURED:
			DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
			cam_lock = false
		else: 
			DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
			cam_lock = true
	tilt_head()

func tilt_head():
	var blend_head = Input.get_axis("Left Tilt", "Right Tilt")
	var blend_walk = Input.get_axis("Left Strafe", "Right Strafe") if !state == State.AIRBORNE else 0.0
	if !anim_tree["parameters/tilt_head/blend_position"] == blend_head:
		var blend_tween = create_tween()
		blend_tween.tween_property(anim_tree, "parameters/tilt_head/blend_position", blend_head, 0.1)
	if !anim_tree["parameters/tilt_walk/blend_position"] == blend_walk:
		var blend_tween = create_tween()
		blend_tween.tween_property(anim_tree, "parameters/tilt_walk/blend_position", blend_walk, 0.1)
	if !anim_tree["parameters/tilt_blend/blend_amount"] == abs(blend_walk):
		var blend_tween = create_tween()
		blend_tween.tween_property(anim_tree, "parameters/tilt_blend/blend_amount", abs(blend_walk), 0.1)

func get_state() -> State:
	anim_tree["parameters/crouch_check/transition_request"] = "RESET"
	if not (is_on_wall() or is_on_floor()): return State.AIRBORNE
	if Input.is_action_pressed("Crouch"): 
		anim_tree["parameters/crouch_check/transition_request"] = "Crouch"
		return State.CROUCH
	if Input.is_action_pressed("Sprint"): return State.SPRINT
	return State.NORMAL

func get_state_speed():
	match state:
		State.NORMAL: 
			sp_last = sp_normal
			anim_tree.tree_root.get_node("Movement").timeline_length = anim_normal
		State.SPRINT: 
			sp_last = sp_sprint
			anim_tree.tree_root.get_node("Movement").timeline_length = anim_sprint
		State.CROUCH: 
			sp_last = sp_crouch
			anim_tree.tree_root.get_node("Movement").timeline_length = anim_crouch

func can_jump() -> bool:
	if jumps_remaining > 0:
		jumps_remaining -= 1
		state = State.AIRBORNE
		return true
	return false
