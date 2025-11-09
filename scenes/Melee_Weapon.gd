extends Node3D

# --- PROPIEDADES AJUSTABLES ---
const COOLDOWN_TIME = 0.5         
const DAMAGE = 10                 
const PUNCH_DEPTH = 0.2           
const PUNCH_DURATION = 0.08       
const PUSH_FORCE = 400.0          # ¡VALOR ALTO RESTAURADO!
var can_attack = true             

# Referencia al puño (Area3D que se mueve y detecta)
@onready var placeholder = $Fist_Placeholder 

func _ready():
	# Conectamos la señal de detección de cuerpos (Area3D)
	placeholder.body_entered.connect(_on_fist_body_entered)
	placeholder.monitoring = false # Desactivamos la detección por defecto


func _process(_delta):
	if Input.is_action_just_pressed("ui_fire") and can_attack:
		perform_attack()


func perform_attack():
	if not can_attack:
		return
		
	can_attack = false
	placeholder.monitoring = true # 1. ACTIVAR DETECCIÓN
	
	var tween = create_tween()
	
	# FASE 1: MOVER HACIA ADELANTE
	tween.tween_property(placeholder, "position:z", placeholder.position.z - PUNCH_DEPTH, PUNCH_DURATION)
	
	# FASE 2: REGRESAR A LA POSICIÓN INICIAL
	tween.tween_property(placeholder, "position:z", placeholder.position.z, PUNCH_DURATION)
	
	# Desactivar la detección cuando la animación termina
	tween.finished.connect(func(): placeholder.monitoring = false)
	
	print("Golpe efectuado, daño:", DAMAGE)
	get_tree().create_timer(COOLDOWN_TIME).timeout.connect(reset_attack)


func reset_attack():
	can_attack = true


# --- FUNCIÓN DE INTERACCIÓN (EL DAÑO Y EMPUJE) ---
func _on_fist_body_entered(body: Node3D):
	
	# 1. Empujar Cajas (RigidBody3D)
	if body is RigidBody3D:
		
		# *** Solución Clave: Forzar el despertar del cuerpo ***
		body.set_sleeping(false) 
		
		# Calcular la dirección y aplicar la fuerza (usando apply_force)
		var push_direction = (body.global_transform.origin - global_transform.origin).normalized()
		var push_vector = push_direction * PUSH_FORCE 
		body.apply_force(push_vector, Vector3.ZERO)
		
	# 2. Dañar Enemigos (CharacterBody3D con script Enemy.gd)
	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)
