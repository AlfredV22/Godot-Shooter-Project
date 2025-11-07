extends CharacterBody3D

# Adjust these settings as needed
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002 
const CAMERA_VERTICAL_LIMIT = 75 # Camera threshold

@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var camera = $Camera3D
var camera_rotation_x = 0

# Startup
func _ready():
	# Mouse lock in
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Physics
func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Horizontal move
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# De acceleration --For smoothness-
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	#Move model
	move_and_slide()

# Mouse Control Input
func _input(event):
	if event is InputEventMouseMotion:
		# Camera Rotation
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		
		# Camera rotation
		camera_rotation_x += -event.relative.y * MOUSE_SENSITIVITY
		camera_rotation_x = clamp(camera_rotation_x, deg_to_rad(-CAMERA_VERTICAL_LIMIT), deg_to_rad(CAMERA_VERTICAL_LIMIT))
		camera.rotation.x = camera_rotation_x
