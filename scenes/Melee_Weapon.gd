extends Node3D

# --- PROPIEDADES AJUSTABLES ---
const COOLDOWN_TIME = 0.5         # Segundos entre cada ataque
const DAMAGE = 10 
const PUNCH_DEPTH = 0.2           # Distancia que el puño se mueve hacia adelante
const PUNCH_DURATION = 0.08       # Duración muy rápida del golpe (ida o vuelta)
var can_attack = true

# Nodos (Referencia al cubo/placeholder)
@onready var placeholder = $Fist_Placeholder 

# --- FUNCIÓN DE PROCESO ---
# Usamos _delta para ignorar la advertencia de Godot
func _process(_delta):
	# Detecta el clic izquierdo del ratón (acción "ui_fire")
	if Input.is_action_just_pressed("ui_fire") and can_attack:
		perform_attack()

# --- LÓGICA DE ATAQUE ---
func perform_attack():
	if not can_attack:
		return
		
	can_attack = false
	
	# 1. EJECUTAR ANIMACIÓN (Tween)
	var tween = create_tween()
	
	# FASE 1: MOVER HACIA ADELANTE (Ataque)
	# placeholder.position.z es la posición inicial (ej: -0.3)
	tween.tween_property(placeholder, "position:z", placeholder.position.z - PUNCH_DEPTH, PUNCH_DURATION)
	
	# FASE 2: REGRESAR A LA POSICIÓN INICIAL
	# Vuelve a la posición original (-0.3)
	tween.tween_property(placeholder, "position:z", placeholder.position.z, PUNCH_DURATION)
	
	# 2. INDICADOR DE DAÑO (Para la consola)
	print("Golpe efectuado, daño:", DAMAGE)
	
	# 3. INICIAR COOLDOWN
	# Crea un temporizador que llama a reset_attack después del COOLDOWN_TIME
	get_tree().create_timer(COOLDOWN_TIME).timeout.connect(reset_attack)

func reset_attack():
	# Permite un nuevo ataque
	can_attack = true
