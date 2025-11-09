extends CharacterBody3D

# --- ADJUSTABLE PLAYER PROPERTIES ---
const SPEED = 5.0                # Base movement speed of the player
const JUMP_VELOCITY = 4.5        # Jump impulse velocity
const MOUSE_SENSITIVITY = 0.002  # Sensitivity for camera rotation
const CAMERA_VERTICAL_LIMIT = 75 # Limit for looking up/down (in degrees)
const PUSH_FORCE = 5.0           # Force to push physics bodies (boxes) upon contact

# --- NODE AND PHYSICS REFERENCES ---
# Get the project's default gravity value
@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") 
# Direct reference to the Camera3D node
@onready var camera = $Camera3D 

# Variable to track the vertical rotation of the camera (look up/down)
var camera_rotation_x = 0.0 

# --- INITIAL SETUP ---
func _ready():
	# Capture the cursor to keep it centered and hidden (essential for an FPS)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# --- PLAYER INPUT (Camera and Mouse) ---
# Handles mouse movement events for camera rotation
func _input(event):
	if event is InputEventMouseMotion:
		# 1. HORIZONTAL ROTATION (Y-Axis) - Rotates the entire CharacterBody3D
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		
		# 2. VERTICAL ROTATION (X-Axis) - Only moves the camera
		camera_rotation_x += -event.relative.y * MOUSE_SENSITIVITY
		
		# Clamp the vertical rotation to prevent the player from looking 360 degrees
		camera_rotation_x = clamp(camera_rotation_x, deg_to_rad(-CAMERA_VERTICAL_LIMIT), deg_to_rad(CAMERA_VERTICAL_LIMIT))
		
		# Apply the vertical rotation only to the camera node
		camera.rotation.x = camera_rotation_x

# --- PLAYER PHYSICS (Movement, Gravity, Jump) ---
# Executes at a fixed rate for stable physics (uses 'delta')
func _physics_process(delta):
	# 1. APPLY GRAVITY
	# If the player is not on the floor, apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. JUMP
	# If "ui_accept" (Spacebar) is pressed and the player is on the ground, apply jump impulse
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. MOVEMENT (WASD)
	# Get the input direction vector (WASD)
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# Transform the 2D input into 3D direction, relative to where the camera is facing
	var direction_wasd = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction_wasd:
		# Apply the speed to the calculated direction
		velocity.x = direction_wasd.x * SPEED
		velocity.z = direction_wasd.z * SPEED
	else:
		# If no key is pressed, slowly stop the horizontal movement (friction)
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# 4. FINAL MOVEMENT AND COLLISION DETECTION
	# Executes movement and stores information about detected collisions
	move_and_slide()

	# --- PUSH LOGIC (CONTACT INTERACTION) ---
	# After moving, check if we collided with anything that can be pushed.
	# 'get_slide_collision_count' returns the number of collisions that happened this frame.
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		
		# Check if the collided object is a RigidBody3D (like a box)
		if collision.get_collider() is RigidBody3D:
			var body_to_push = collision.get_collider()
			
			# Calculate the push direction: it's opposite to the collision normal.
			# Using 'push_direction' prevents variable name warnings.
			var push_direction = -collision.get_normal() 
			
			# Apply an instantaneous impulse force to the object to push it.
			body_to_push.apply_central_impulse(push_direction * PUSH_FORCE)
