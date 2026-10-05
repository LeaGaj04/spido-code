extends Node3D

@export var mineral_scene : PackedScene
@onready var grid_map: GridMap = $GridMap

# Esta es la casilla cuyo centro queda junto a la nave.
const CASILLA_INICIAL := Vector3i.ZERO
const CASILLA_TRANSFERENCIA := CASILLA_INICIAL

# Nivel de expansión del mismo mapa.
# 0 = zona inicial 1x1
# 1 = corredor 1x3
# 2 = sector 2x3 (tres casillas adicionales)
# 3 = sector 3x3, reservado para una expansión futura
var radio_mapa_desbloqueado: int = 0
var max_minerales: int = 1
var corredor_1x3_desbloqueado: bool = false
var mapa_3x3_desbloqueado: bool = false
var casillas_extra_desbloqueadas: bool = false
var ultima_celda_minada: Vector3i = Vector3i(9999, 9999, 9999)

func _ready():
	var map_tier := 0
	var progreso: Dictionary = {}
	var restaurar_progreso := false
	# El autoload conserva su vida entre escenas; cada entrada al mundo parte
	# explícitamente de la sintaxis inicial antes de restaurar un usuario.
	GestorSintaxis.aplicar_sintaxis_desbloqueada({})

	if Supabase.is_authenticated():
		if ProgressService.has_loaded_progress():
			progreso = ProgressService.get_current_progress()
			map_tier = int(progreso.get("map_tier", 0))
			restaurar_progreso = true
		else:
			push_error("Sesión autenticada sin progreso cargado. Se inicia un mundo seguro sin restaurar datos.")

	aplicar_progreso_mapa(map_tier)
	_posicionar_spid_en_casilla_inicial()
	_resaltar_casilla_principal()
	generar_minerales_iniciales()
	var spid := grid_map.get_node_or_null("Spid")
	if spid != null and spid.has_signal("mineral_minado"):
		spid.mineral_minado.connect(_on_mineral_minado)

	if restaurar_progreso:
		var sintaxis = progreso.get("unlocked_syntax", {})
		if typeof(sintaxis) != TYPE_DICTIONARY:
			push_error("El progreso cargado contiene unlocked_syntax inválido; se usarán sintaxis bloqueadas.")
			sintaxis = {}
		GestorSintaxis.aplicar_sintaxis_desbloqueada(sintaxis)

	var interfaz := get_node_or_null("CanvasLayer")
	if interfaz != null:
		interfaz.aplicar_progreso(progreso)

func _on_mineral_minado(celda: Vector3i) -> void:
	ultima_celda_minada = celda
	spawn_mineral_aleatorio()

# Reconstruye el mapa desde el tier persistido. No valida costos ni emite
# efectos de compra, por lo que también se puede usar al restaurar progreso.
func aplicar_progreso_mapa(map_tier: int) -> void:
	radio_mapa_desbloqueado = maxi(0, map_tier)

	corredor_1x3_desbloqueado = (
		radio_mapa_desbloqueado >= 1
	)

	mapa_3x3_desbloqueado = (
		radio_mapa_desbloqueado >= 3
	)
	casillas_extra_desbloqueadas = radio_mapa_desbloqueado >= 2
	if mapa_3x3_desbloqueado:
		max_minerales = 3
	elif casillas_extra_desbloqueadas:
		max_minerales = 2
	else:
		max_minerales = 1

	grid_map.clear()

	# Sector 3x3: tres columnas y tres filas.
	if mapa_3x3_desbloqueado:
		for x in range(
			CASILLA_INICIAL.x - 1,
			CASILLA_INICIAL.x + 2
		):
			for z in range(
				CASILLA_INICIAL.z - 1,
				CASILLA_INICIAL.z + 2
			):
				var tipo_casilla := (
					1 if (x + z) % 2 == 0 else 2
				)

				grid_map.set_cell_item(
					Vector3i(x, 0, z),
					tipo_casilla
				)

		return

	if casillas_extra_desbloqueadas:
		for x in range(0, 2):
			for z in range(-1, 2):
				var casilla := CASILLA_INICIAL + Vector3i(x, 0, z)
				grid_map.set_cell_item(casilla, 1 if (x + z) % 2 == 0 else 2)
		return

	# Corredor 1x3: comienza en la nave y avanza hacia el norte.
	if corredor_1x3_desbloqueado:
		for z in range(
			CASILLA_INICIAL.z - 1,
			CASILLA_INICIAL.z + 2
		):
			var posicion := Vector3i(
				CASILLA_INICIAL.x,
				0,
				z
			)

			var tipo_casilla := (
				1 if (
				posicion.x + posicion.z
				) % 2 == 0 else 2
			)

			grid_map.set_cell_item(
				posicion,
				tipo_casilla
			)

		return

	# Nivel inicial: solamente la casilla de transferencia.
	grid_map.set_cell_item(
			CASILLA_INICIAL,
			1
		)

func _posicionar_spid_en_casilla_inicial() -> void:
	var spid := grid_map.get_node_or_null("Spid") as Node3D
	if spid == null:
		return

	var centro: Vector3 = grid_map.map_to_local(CASILLA_INICIAL)
	spid.position.x = centro.x
	spid.position.z = centro.z


func resetear_posicion_spid() -> void:
	var spid := grid_map.get_node_or_null("Spid") as Node3D
	if spid == null:
		return
	var centro_local: Vector3 = grid_map.map_to_local(CASILLA_INICIAL)
	var centro_global: Vector3 = grid_map.to_global(centro_local)
	centro_global.y = spid.global_position.y
	if spid.has_method("resetear_a_base"):
		spid.resetear_a_base(centro_global)
	else:
		spid.global_position = centro_global
		spid.rotation = Vector3.ZERO

func generar_minerales_iniciales():
	# Si el radio es 0 (solo 1 casilla), solo hacemos aparecer 1 mineral
	if radio_mapa_desbloqueado == 0:
		max_minerales = 1
	
	for i in range(max_minerales):
		spawn_mineral_aleatorio()

func spawn_mineral_aleatorio() -> void:
	var ocupadas: Array[Vector3i] = []
	for mineral in get_tree().get_nodes_in_group("minerales"):
		var objeto := mineral.get_parent() as Node3D
		if objeto == null or objeto.get_parent() != self or objeto.is_queued_for_deletion():
			continue
		var celda := grid_map.local_to_map(grid_map.to_local(objeto.global_position))
		celda.y = 0
		ocupadas.append(celda)

	if ocupadas.size() >= max_minerales:
		return

	var casilla_mineral := CASILLA_INICIAL

	# 1. Sector expandido 2x3 (map_tier >= 2)
	if casillas_extra_desbloqueadas:
		var candidatas: Array[Vector3i] = []
		for celda in grid_map.get_used_cells():
			var celda_2d := Vector3i(celda.x, 0, celda.z)
			# REGLA A: Nunca en la casilla de transferencia / nave (0, 0, 0)
			if celda_2d == CASILLA_TRANSFERENCIA:
				continue
			# REGLA B: Nunca en una celda que ya tenga mineral
			if celda_2d in ocupadas:
				continue
			candidatas.append(celda_2d)

		if candidatas.is_empty():
			return

		# REGLA C: Evitar la última celda minada si hay otra alternativa disponible
		var candidatas_sin_repetir: Array[Vector3i] = []
		for c in candidatas:
			if c != ultima_celda_minada:
				candidatas_sin_repetir.append(c)

		if not candidatas_sin_repetir.is_empty():
			casilla_mineral = candidatas_sin_repetir.pick_random()
		else:
			# Si no hay alternativa, permitimos repetir
			casilla_mineral = candidatas.pick_random()

	# 2. Corredor 1x3 (map_tier 1)
	elif corredor_1x3_desbloqueado:
		casilla_mineral = CASILLA_INICIAL + Vector3i(0, 0, -1)

	# 3. Zona inicial 1x1 (map_tier 0)
	else:
		casilla_mineral = CASILLA_INICIAL

	# Instanciar el mineral visualmente centrado en la casilla elegida
	var centro_local := grid_map.map_to_local(casilla_mineral)
	var centro_global := grid_map.to_global(centro_local)

	var nuevo_mineral = mineral_scene.instantiate()
	add_child(nuevo_mineral)
	nuevo_mineral.global_position = centro_global + Vector3(0, -0.4, 0.3)

func reubicar_mineral_para_corredor() -> void:
	var minerales := get_tree().get_nodes_in_group("minerales")
	var padres_eliminados: Dictionary = {}

	for mineral in minerales:
		var objeto_mineral := mineral.get_parent() as Node

		if objeto_mineral == null:
			continue

		var id_objeto := objeto_mineral.get_instance_id()

		if padres_eliminados.has(id_objeto):
			continue

		padres_eliminados[id_objeto] = true
		objeto_mineral.queue_free()

	# Esperamos a que Godot elimine el mineral anterior.
	call_deferred("generar_minerales_iniciales")

func spid_esta_en_casilla_transferencia(spid: Node3D) -> bool:
	if spid == null:
		return false

	var posicion_local := grid_map.to_local(spid.global_position)
	var casilla_actual := grid_map.local_to_map(posicion_local)

	# El movimiento ocurre horizontalmente.
	casilla_actual.y = CASILLA_TRANSFERENCIA.y

	return casilla_actual == CASILLA_TRANSFERENCIA

func expandir_corredor_1x3() -> bool:
	if corredor_1x3_desbloqueado:
		return false

	aplicar_progreso_mapa(1)
	reubicar_mineral_para_corredor()

	print(
		"Corredor adquirido: terreno expandido a 1x3."
	)

	return true


func expandir_tres_casillas() -> bool:
	if casillas_extra_desbloqueadas or not corredor_1x3_desbloqueado:
		return false
	aplicar_progreso_mapa(2)
	reubicar_mineral_para_corredor()
	return true


func expandir_mapa_3x3() -> bool:
	if mapa_3x3_desbloqueado or not casillas_extra_desbloqueadas:
		return false

	aplicar_progreso_mapa(3)
	reubicar_mineral_para_corredor()

	print(
		"Sector adquirido: terreno expandido a 3x3."
	)

	return true

func get_map_tier() -> int:
	return radio_mapa_desbloqueado


func _resaltar_casilla_principal() -> void:
	var resaltador = grid_map.get_node_or_null("ResaltadorBase")
	if resaltador == null:
		resaltador = MeshInstance3D.new()
		resaltador.name = "ResaltadorBase"
		var malla = PlaneMesh.new()
		malla.size = Vector2(1.8, 1.8)
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.2, 0.8, 0.3, 0.35)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.emission_enabled = true
		material.emission = Color(0.2, 0.8, 0.3)
		material.emission_energy_multiplier = 1.5
		malla.material = material
		resaltador.mesh = malla
		grid_map.add_child(resaltador)
	
	var centro_local = grid_map.map_to_local(CASILLA_INICIAL)
	resaltador.position = centro_local + Vector3(0, 0.02, 0)
