extends Node3D

# --- ADJUSTABLE WEAPON PROPERTIES ---
const COOLDOWN_TIME = 0.5         # Time (in seconds) between attacks
const DAMAGE = 10                 # Amount of damage this attack deals
const PUNCH_DEPTH = 0.2           # Distance the fist placeholder moves forward for the animation
const PUNCH_DURATION = 0.08       # Very fast duration for the punch animation (one way)
const PUSH_FORCE = 10.0           # Extra force applied to pushed objects by the punch
var can_attack = true             # Flag indicating whether an attack can be performed

# Node References
@onready var placeholder = $Fist_Placeholder # The visible cube/3D model placeholder
@onready var hitbox = $Hitbox                # The Area3D node used for collision detection

func _ready():
	# 1. Deactivate the Hitbox by default; it should only be active during the punch frame
	hitbox.monitoring = false 
	# 2. Connect the signal: when a body enters the Hitbox, call the interaction function
	hitbox.body_entered.connect(_on_hitbox_body_entered)


# Use '_delta' because we are not using the time delta value in this function.
func _process(_delta):
	# Check if the attack button ("ui_fire") is pressed and we are not on cooldown
	if Input.is_action_just_pressed("ui_fire") and can_attack:
		perform_attack()


func perform_attack():
	if not can_attack:
		return
		
	can_attack = false
	hitbox.monitoring = true # 1. Activate the hitbox right before the punch starts
	
	# Create a Tween object to handle the smooth attack animation
	var tween = create_tween()
	
	# PHASE 1: MOVE FORWARD (The actual punch)
	tween.tween_property(placeholder, "position:z", placeholder.position.z - PUNCH_DEPTH, PUNCH_DURATION)
	
	# PHASE 2: RETURN TO INITIAL POSITION
	tween.tween_property(placeholder, "position:z", placeholder.position.z, PUNCH_DURATION)
	
	print("Hit performed, damage:", DAMAGE)
	
	# Deactivate the hitbox immediately after the animation finishes
	tween.finished.connect(func(): hitbox.monitoring = false)
	
	# 3. START COOLDOWN: Use a timer to wait for the COOLDOWN_TIME before calling reset_attack
	get_tree().create_timer(COOLDOWN_TIME).timeout.connect(reset_attack)


func reset_attack():
	# Allow the player to attack again
	can_attack = true


# --- INTERACTION FUNCTION (THE CORE OF DAMAGE DEALING) ---
func _on_hitbox_body_entered(body: Node3D):
	
	# 1. Push Boxes (RigidBody3D)
	if body is RigidBody3D:
		# Calculate the push direction (from the fist toward the object)
		var push_direction = (body.global_transform.origin - global_transform.origin).normalized()
		# Apply an impulsive force using the weapon's push strength
		body.apply_central_impulse(push_direction * PUSH_FORCE)
		
	# 2. Damage Enemies (Call the health system)
	# Check if the collided object has a 'take_damage' function (making the system modular)
	if body.has_method("take_damage"):
		# Call the enemy's damage function and pass the weapon's damage value
		body.take_damage(DAMAGE)
