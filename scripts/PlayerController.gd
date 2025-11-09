extends CharacterBody3D

# --- ADJUSTABLE PLAYER PROPERTIES ---
const SPEED = 5.0                # Base movement speed of the player
const JUMP_VELOCITY = 4.5        # Jump impulse velocity
const MOUSE_SENSITIVITY = 0.002  # Sensitivity for camera rotation
const CAMERA_VERTICAL_LIMIT = 75 # Limit for looking up/down (in degrees)
const PUSH_FORCE = 1.0           # Force to push physics bodies (boxes) upon contact

# --- NODE AND PHYSICS REFERENCES ---
@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") 
@onready var camera = $Camera3D 

var camera_rotation_x = 0.0 

# --- INITIAL SETUP ---
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# --- PLAYER INPUT (Camera and Mouse) ---
func _input(event):
	if event is InputEventMouseMotion:
		# 1. HORIZONTAL ROTATION (Y-Axis)
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		
		# 2. VERTICAL ROTATION (X-Axis) - Only moves the camera
		camera_rotation_x += -event.relative.y * MOUSE_SENSITIVITY
		camera_rotation_x = clamp(camera_rotation_x, deg_to_rad(-CAMERA_VERTICAL_LIMIT), deg_to_rad(CAMERA_VERTICAL_LIMIT))
		camera.rotation.x = camera_rotation_x

# --- PLAYER PHYSICS (Movement, Gravity, Jump) ---
func _physics_process(delta):
	# 1. APPLY GRAVITY
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. JUMP
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. MOVEMENT (WASD)
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction_wasd = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction_wasd:
		velocity.x = direction_wasd.x * SPEED
		velocity.z = direction_wasd.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# 4. FINAL MOVEMENT AND COLLISION DETECTION
	move_and_slide()

	# --- PUSH LOGIC (CONTACT INTERACTION) ---
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		
		# Check if the collided object is a RigidBody3D (a pushable box)
		if collision.get_collider() is RigidBody3D:
			var body_to_push = collision.get_collider()
			
			# Calculate the push direction (opposite to the collision normal)
			var push_direction = -collision.get_normal() 
			
			# Apply an instantaneous impulse force to the object
			body_to_push.apply_central_impulse(push_direction * PUSH_FORCE)
