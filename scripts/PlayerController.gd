extends CharacterBody3D

# --- PLAYER PROPERTIES ---
const SPEED = 5.0                
const JUMP_VELOCITY = 4.5        
const MOUSE_SENSITIVITY = 0.002  
const CAMERA_VERTICAL_LIMIT = 75 
const PUSH_FORCE = 5.0           
const PLAYER_COLLISION_LAYER = 1 # Assuming Player is on Collision Layer 1

# --- NODE REFERENCES ---
@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") 
@onready var camera = $Camera3D 
@onready var grab_ray_cast = $Camera3D/GrabRayCast
@onready var grab_point = $Camera3D/GrabPoint     
# Robust search for the HUD label
@onready var grab_indicator = get_tree().root.find_child("GrabLabel", true, false) 

# --- STATE VARIABLES ---
var camera_rotation_x = 0.0 
var held_object: RigidBody3D = null 
var can_grab: bool = true # Flag to prevent immediate re-grabbing after release


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if is_instance_valid(grab_indicator):
		grab_indicator.hide() 


func _input(event):
	# Mouse look control
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_rotation_x += -event.relative.y * MOUSE_SENSITIVITY
		camera_rotation_x = clamp(camera_rotation_x, deg_to_rad(-CAMERA_VERTICAL_LIMIT), deg_to_rad(CAMERA_VERTICAL_LIMIT))
		camera.rotation.x = camera_rotation_x 

	# GRAB/RELEASE LOGIC
	if event.is_action_pressed("grab"):
		if held_object:
			release_object()
		else:
			grab_object()


func _physics_process(delta):
	# Movement Logic (Gravity and Jumping)
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction_wasd = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction_wasd:
		velocity.x = direction_wasd.x * SPEED
		velocity.z = direction_wasd.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	# PUSH LOGIC (Apply impulse to RigidBodies the player collides with)
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		
		if collision.get_collider() is RigidBody3D:
			var body_to_push = collision.get_collider()
			var push_direction = -collision.get_normal() 
			
			body_to_push.apply_central_impulse(push_direction * PUSH_FORCE)
	
	# DRAGGING LOGIC (Position and Rotation update for the held object)
	if held_object:
		# Force the object position to the grab point (teleport)
		held_object.global_position = grab_point.global_position
		# Zero out velocities to prevent jittering or momentum build-up
		held_object.linear_velocity = Vector3.ZERO
		held_object.angular_velocity = Vector3.ZERO
		
		# ROTATION CORRECTION: Lock X and Z rotation (pitch and roll) but allow Y (yaw)
		# 1. Get the ideal transform to look at the player
		var target_transform = held_object.global_transform.looking_at(global_position, Vector3.UP)
		
		# 2. Extract only the Y-axis rotation (horizontal turning)
		var target_rotation_y = target_transform.basis.get_euler().y
		
		# 3. Force the object's rotation, setting X and Z to 0.0 (neutral pitch/roll).
		held_object.global_rotation = Vector3(0.0, target_rotation_y, 0.0)
		
		if is_instance_valid(grab_indicator):
			grab_indicator.show()
			grab_indicator.text = "Press E to RELEASE"
	else:
		# Check if there is a grabbable object in front of the player
		check_grabbable_target()


# --- GRAB / RELEASE FUNCTIONS ---

func check_grabbable_target():
	
	var show_indicator = false
	
	# Check if RayCast hit a RigidBody3D
	if grab_ray_cast.is_colliding():
		var collider = grab_ray_cast.get_collider()
		
		if collider is RigidBody3D:
			show_indicator = true
			
	if is_instance_valid(grab_indicator):
		if show_indicator:
			grab_indicator.show()
			grab_indicator.text = "Press E to GRAB"
		else:
			grab_indicator.hide()


func grab_object():
	if not can_grab: # Block grabbing if the flag is false (right after releasing)
		return
		
	if grab_ray_cast.is_colliding():
		var collider = grab_ray_cast.get_collider()
		
		if collider is RigidBody3D:
			
			held_object = collider
			
			# 1. Disable gravity (Keeps it floating)
			held_object.gravity_scale = 0.0
			
			# 2. DISABLE COLLISION: Set the object to ignore the Player's layer (Layer 1).
			held_object.set_collision_mask_value(PLAYER_COLLISION_LAYER, false) 
			
			# 3. Temporarily disable the object's collision layer so it doesn't affect other RigidBodies
			# while it's being manually controlled (optional, but robust).
			held_object.set_collision_layer_value(PLAYER_COLLISION_LAYER, false)

			# 4. Move the object to the grab point
			held_object.global_position = grab_point.global_position

func release_object():
	if held_object:
		
		# 1. Set flag to false to prevent immediate re-grabbing
		can_grab = false
		
		# 2. Restore gravity
		held_object.gravity_scale = 1.0
		
		# 3. Apply player's velocity to simulate a throw/release
		held_object.linear_velocity = velocity * 1.5 
		
		# 4. Hide the HUD indicator
		if is_instance_valid(grab_indicator):
			grab_indicator.hide()
			
		var temp_object = held_object 
		held_object = null 
		
		# 5. Wait one physics frame to allow the object to receive the impulse/velocity
		# before restoring collisions.
		await get_tree().physics_frame
		
		# 6. RESTORE COLLISION: Restore the object's ability to collide with the player and others.
		temp_object.set_collision_mask_value(PLAYER_COLLISION_LAYER, true) 
		temp_object.set_collision_layer_value(PLAYER_COLLISION_LAYER, true) # Restore collision layer

		# 7. Wait a short time (0.2s) to guarantee the object has physically left the RayCast area.
		await get_tree().create_timer(0.2).timeout 
		
		# 8. Restore grab flag
		can_grab = true
