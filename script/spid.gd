extends CharacterBody3D

signal mineral_recolectado(cantidad)
signal mineral_minado(celda: Vector3i)

# Distancia de cada paso en unidades 3D (el tamaño de tu casilla)
var paso_distancia: float = 2.0

# Control de la cola de movimiento
var cola_instrucciones: Array = []
var esta_moviendose: bool = false
var tiempo_minado: float = 3.0
var animation_player: AnimationPlayer


func _ready() -> void:
	animation_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation_player:
		var anim_idle = animation_player.get_animation("idle")
		if anim_idle:
			anim_idle.loop_mode = Animation.LOOP_LINEAR
		var anim_walk = animation_player.get_animation("caminar")
		if anim_walk:
			anim_walk.loop_mode = Animation.LOOP_LINEAR
		var anim_minar = animation_player.get_animation("minar")
		if anim_minar:
			anim_minar.loop_mode = Animation.LOOP_LINEAR
		if animation_player.has_animation("idle"):
			animation_player.play("idle")


# --- FUNCIONES DE MOVIMIENTO (Aceptan cantidad de pasos) ---

func norte(pasos: int = 1) -> Dictionary:
	for i in range(pasos):
		cola_instrucciones.append(Vector3.FORWARD)

	return await _intentar_mover()


func sur(pasos: int = 1) -> Dictionary:
	for i in range(pasos):
		cola_instrucciones.append(Vector3.BACK)

	return await _intentar_mover()


func oeste(pasos: int = 1) -> Dictionary:
	for i in range(pasos):
		cola_instrucciones.append(Vector3.LEFT)

	return await _intentar_mover()


func este(pasos: int = 1) -> Dictionary:
	for i in range(pasos):
		cola_instrucciones.append(Vector3.RIGHT)

	return await _intentar_mover()


func _intentar_mover() -> Dictionary:
	var pasos_completados := 0

	if esta_moviendose:
		return {
			"ok": false,
			"error_type": "ejecucion",
			"message": "Spid ya está ejecutando otro movimiento.",
			"steps_completed": pasos_completados
		}

	esta_moviendose = true
	if animation_player and animation_player.has_animation("caminar"):
		animation_player.play("caminar")

	while cola_instrucciones.size() > 0:
		var direccion: Vector3 = cola_instrucciones.pop_front()
		var destino := global_position + direccion * paso_distancia

		if not _destino_esta_desbloqueado(destino):
			cola_instrucciones.clear()
			esta_moviendose = false
			if animation_player and animation_player.has_animation("idle"):
				animation_player.play("idle")

			return {
				"ok": false,
				"error_type": "ejecucion",
				"message": (
					"Movimiento bloqueado: esa casilla todavía no está disponible."
				),
				"steps_completed": pasos_completados
			}

		var tween := create_tween()
		tween.tween_property(
			self,
			"global_position",
			destino,
			0.4
		)

		await tween.finished
		pasos_completados += 1

	esta_moviendose = false
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")

	return {
		"ok": true,
		"error_type": "",
		"message": "",
		"steps_completed": pasos_completados
	}


func _destino_esta_desbloqueado(destino_global: Vector3) -> bool:
	var grid_map := get_parent() as GridMap
	if grid_map == null:
		push_warning("El Spid debe ser hijo de un GridMap para validar sus límites.")
		return false

	var destino_local := grid_map.to_local(destino_global)
	var casilla := grid_map.local_to_map(destino_local)
	# El movimiento es horizontal; ignoramos cualquier variación de altura del modelo.
	casilla.y = 0
	return grid_map.get_cell_item(casilla) != GridMap.INVALID_CELL_ITEM

# --- SENSORES ---
func hay_mineral() -> bool:
	var grid_map := get_parent() as GridMap
	if grid_map == null:
		return false
	var posicion_spid_local := grid_map.to_local(global_position)
	var casilla_spid := grid_map.local_to_map(posicion_spid_local)
	casilla_spid.y = 0
	var minerales_en_mapa := get_tree().get_nodes_in_group("minerales")
	for mineral in minerales_en_mapa:
		var nodo_mineral := mineral.get_parent() as Node3D
		if nodo_mineral == null or nodo_mineral.is_queued_for_deletion():
			continue
		var posicion_mineral_local := grid_map.to_local(nodo_mineral.global_position)
		var casilla_mineral := grid_map.local_to_map(posicion_mineral_local)
		casilla_mineral.y = 0
		if casilla_spid == casilla_mineral:
			return true
	return false

func tiene_espacio() -> bool:
	var interfaz := get_tree().current_scene.get_node_or_null("CanvasLayer")
	if interfaz != null:
		return int(interfaz.minerales_spid) < int(interfaz.CAPACIDAD_SPID)
	return true

func en_base() -> bool:
	var mundo := get_parent()
	if mundo != null and mundo.has_method("spid_esta_en_casilla_transferencia"):
		return mundo.spid_esta_en_casilla_transferencia(self)
	return false

func minerales_en_nave() -> int:
	var interfaz := get_tree().current_scene.get_node_or_null("CanvasLayer")
	if interfaz != null:
		return int(interfaz.minerales_nave)
	return 0

func minerales_en_rover() -> int:
	var interfaz := get_tree().current_scene.get_node_or_null("CanvasLayer")
	if interfaz != null:
		return int(interfaz.minerales_spid)
	return 0

func minar() -> Dictionary:
	var grid_map := get_parent() as GridMap
	if grid_map == null:
		return {
			"ok": false,
			"error_type": "ejecucion",
			"message": "No se pudo comprobar la casilla actual dspid.",
			"minerals_collected": 0,
			"steps_completed": 0
		}

	var posicion_spid_local := grid_map.to_local(global_position)
	var casilla_spid := grid_map.local_to_map(posicion_spid_local)
	casilla_spid.y = 0
	var minerales_en_mapa := get_tree().get_nodes_in_group("minerales")

	for mineral in minerales_en_mapa:
		var nodo_mineral := mineral.get_parent() as Node3D
		if nodo_mineral == null:
			continue

		var posicion_mineral_local := grid_map.to_local(
			nodo_mineral.global_position
		)
		var casilla_mineral := grid_map.local_to_map(posicion_mineral_local)
		casilla_mineral.y = 0

		if casilla_spid == casilla_mineral:
			print("Spid posicionado. Iniciando protocolo de minería...")
			if animation_player and animation_player.has_animation("minar"):
				animation_player.play("minar")
				await get_tree().create_timer(tiempo_minado).timeout
				if animation_player.has_animation("idle"):
					animation_player.play("idle")
			else:
				await get_tree().create_timer(tiempo_minado).timeout

			if is_instance_valid(nodo_mineral):
				nodo_mineral.queue_free()
			mineral_minado.emit(casilla_spid)
			mineral_recolectado.emit(1)
			MissionService.evaluar_objetivo(1)

			print("Mineral recolectado correctamente.")

			return {
				"ok": true,
				"error_type": "",
				"message": "",
				"minerals_collected": 1,
				"steps_completed": 0
			}

	print("Error: No hay ningún mineral en esta casilla.")

	return {
		"ok": false,
		"error_type": "ejecucion",
		"message": "No existe un mineral en la casilla actual.",
		"minerals_collected": 0,
		"steps_completed": 0
	}


func resetear_a_base(posicion_global: Vector3) -> void:
	cola_instrucciones.clear()
	esta_moviendose = false
	rotation = Vector3.ZERO
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")
	var tween := create_tween()
	tween.tween_property(self, "global_position", posicion_global, 0.35)
	await tween.finished


func animar_transferencia() -> void:
	if animation_player and animation_player.has_animation("transferir"):
		animation_player.play("transferir")
		await animation_player.animation_finished
		if animation_player.has_animation("idle"):
			animation_player.play("idle")
	else:
		await get_tree().create_timer(2.5).timeout


func transferir() -> void:
	await animar_transferencia()
