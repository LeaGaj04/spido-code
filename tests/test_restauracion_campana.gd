extends SceneTree
## Godot --headless --path . --script tests/test_restauracion_campana.gd
## Solo memoria: no carga HTTP, no cuenta autenticada y UI sin guardado.
## Sale con código 1 si una expectativa falla, incluidos los bugs conocidos.
## COMPORTAMIENTO LEGADO y AMBIGUO se informan aparte; no se omiten tests.

class AdaPrueba extends Node:
	func mostrar_mensaje(_texto: String, _tipo: String, _duracion: float) -> void:
		pass


class ContadoresEscena extends Node:
	var interfaz: Node
	# MissionService consulta CanvasLayer de current_scene. El adaptador lee
	# los contadores de la UI real sin montar sus nodos ni disparar su _ready().
	var minerales_nave: int:
		get:
			return interfaz.minerales_nave


class MundoPrueba extends Node:
	var map_tier := 0
	func get_map_tier() -> int:
		return map_tier


var misiones: Node
var progreso: Node
var sintaxis: Node
var ui: Node
var ada: AdaPrueba
var mundo: MundoPrueba
var totales := {"PASS": 0, "BUG CONFIRMADO": 0, "COMPORTAMIENTO LEGADO": 0, "AMBIGUO": 0}
var nombre_caso := ""
var problemas: Array[String] = []
var comprobaciones := 0


func _initialize() -> void:
	call_deferred("ejecutar_suite")


func ejecutar_suite() -> void:
	misiones = root.get_node("MissionService")
	progreso = root.get_node("ProgressService")
	sintaxis = root.get_node("GestorSintaxis")
	ui = load("res://tests/fixtures/interfaz_sin_guardado.gd").new()
	ada = AdaPrueba.new()
	ui.transmision_ada = ada
	mundo = MundoPrueba.new()
	var contadores := ContadoresEscena.new()
	contadores.name = "CanvasLayer"
	contadores.interfaz = ui
	mundo.add_child(contadores)
	root.add_child(mundo)
	current_scene = mundo

	_inicio("aislamiento: sesión invitada y servicios sin operaciones")
	_esperar(not root.get_node("Supabase").is_authenticated(), "la ejecución debe ser invitada")
	_esperar(progreso.pending_operation == "", "no debe haber peticiones de progreso")
	_fin()

	# Expectativas funcionales: un ID incompleto debe restaurar su estado activo.
	var activas := [
		["recolectar_primer_mineral", 0, "BUSCAR_MINERAL"],
		["ruta_calibracion", 1, "BUSCAR_MINERAL"],
		["trabajo_continuo", 1, "TRABAJO_CONTINUO"],
		["cuota_suministro", 1, "CUOTA_SUMINISTRO"],
		["senales_inciertas", 2, "SENALES_INCIERTAS"],
		["comprar_mapa_3x3", 2, "COMPRAR_MAPA_3X3"],
		["ciclo_recoleccion", 3, "CICLO_RECOLECCION"],
		["exploracion_3x3", 3, "EXPLORACION_3X3"],
		["camino_largo", 3, "CAMINO_LARGO"],
		["variables", 3, "VARIABLES"],
		["retorno_base", 3, "RETORNO_BASE"],
	]
	for activa in activas:
		_inicio("misión incompleta: " + activa[0])
		var datos := _datos(activa[0], activa[1])
		var actual := _restaurar(datos)
		_esperar(actual["id"] == activa[0], "ID no debe cambiar: " + _detalle(actual))
		_esperar(actual["estado"] == activa[2], "esperado %s; %s" % [activa[2], _detalle(actual)])
		_esperar(not actual["completada"], "debe seguir activa: " + _detalle(actual))
		_esperar(actual["completadas"].is_empty(), "no debe introducir misiones completadas")
		_esperar(not misiones.get_objetivo_actual().is_empty(), "descriptor de misión disponible")
		_esperar(not ui._get_objetivo_panel(activa[0]).is_empty(), "descriptor del panel disponible sin UI real")
		if activa[0] == "recolectar_primer_mineral":
			_esperar("muestra" in misiones.get_objetivo_actual().to_lower(), "descriptor corresponde a Primera Muestra")
			_esperar("muestra" in ui._get_objetivo_panel(activa[0]).to_lower(), "panel corresponde a Primera Muestra")
		_esperar(progreso.get_current_progress() == datos, "restaurar misión no debe alterar la caché")
		_fin()

	# Regresión: el enum específico no depende de la carga del robot.
	for id in ["variables", "retorno_base"]:
		_inicio(id + " incompleta con carga en robot")
		var datos := _datos(id, 3)
		datos["minerals_spid"] = 1
		var actual := _restaurar(datos)
		_esperar(actual["id"] == id, "conservar ID")
		_esperar(actual["estado"] == id.to_upper(), "esperado %s; %s" % [id.to_upper(), _detalle(actual)])
		_esperar(not actual["completada"], "no debe completarse")
		_fin()

	for caso in [["variables", 0, 0], ["variables", 1, 1], ["retorno_base", 0, 2], ["retorno_base", 1, 3]]:
		_inicio("invariantes de %s: carga=%d mapa=%d" % [caso[0], caso[1], caso[2]])
		var datos := _datos(caso[0], caso[2])
		datos["minerals_spid"] = caso[1]
		datos["minerals_ship"] = 23
		datos["completed_missions"] = ["recolectar_primer_mineral"]
		datos["unlocked_syntax"] = {"for": true, "while": true, "if": true, "else": true, "in range": true}
		datos["unlocked_knowledge"] = ["objeto", "metodo", "condicional_if", "bucle_for", "parametro"]
		var actual := _restaurar(datos)
		_esperar(actual["id"] == caso[0] and actual["estado"] == caso[0].to_upper() and not actual["completada"], _detalle(actual))
		_esperar(actual["completadas"] == datos["completed_missions"], "completed_missions intacto")
		_esperar(sintaxis.get_sintaxis_desbloqueada() == datos["unlocked_syntax"], "unlocked_syntax intacto")
		_esperar(misiones.unlocked_knowledge == datos["unlocked_knowledge"], "unlocked_knowledge intacto")
		_esperar(mundo.get_map_tier() == caso[2], "map_tier aplicado intacto")
		_esperar(progreso.get_current_progress() == datos, "fila en memoria intacta")
		_fin()

	_inicio("Ruta de Calibración con carga: fase genérica")
	var ruta := _datos("ruta_calibracion", 1)
	ruta["minerals_spid"] = 1
	var ruta_actual := _restaurar(ruta)
	_esperar(ruta_actual["id"] == "ruta_calibracion" and not ruta_actual["completada"], "no saltar ni completar Ruta")
	_esperar(ruta_actual["estado"] == "TRANSFERIR_MINERAL", "caracterización de fase con carga: " + _detalle(ruta_actual))
	_fin("AMBIGUO", "sin enum exclusivo: con carga usa TRANSFERIR_MINERAL; su inicializador usa BUSCAR_MINERAL")

	# Caracterización: ambas etapas comparten ID, enum y textos del sector 2x3.
	var compra_inicial := _datos("comprar_casillas", 0)
	compra_inicial["completed_missions"] = ["recolectar_primer_mineral"]
	compra_inicial["minerals_ship"] = 1
	_inicio("Comprar Casillas A: corredor inicial")
	var compra_a := _restaurar(compra_inicial)
	var descriptor_a: String = misiones.get_objetivo_actual()
	var panel_a: String = ui._get_objetivo_panel("comprar_casillas")
	_esperar(compra_a["id"] == "comprar_casillas" and compra_a["estado"] == "COMPRAR_CASILLAS", _detalle(compra_a))
	_esperar(not compra_a["completada"], "primera compra sigue pendiente")
	_esperar("2x3" in descriptor_a and "+3 CASILLAS" in panel_a, "caracterización: el objetivo de ambas etapas es el sector 2x3")
	_fin("AMBIGUO", "map_tier=0 y primera muestra completada, pero descriptor anuncia +3 casillas / 2x3")

	_inicio("Comprar Casillas B: sector 2x3")
	var compra_sector := _datos("comprar_casillas", 1)
	compra_sector["completed_missions"] = ["recolectar_primer_mineral", "ruta_calibracion", "trabajo_continuo", "cuota_suministro"]
	compra_sector["minerals_ship"] = 10
	var compra_b := _restaurar(compra_sector)
	_esperar(compra_b["id"] == compra_a["id"] and compra_b["estado"] == compra_a["estado"], "ambas etapas restauran el mismo ID y enum")
	_esperar(descriptor_a == misiones.get_objetivo_actual() and panel_a == ui._get_objetivo_panel("comprar_casillas"), "los descriptores tampoco distinguen etapas")
	_esperar(not compra_b["completada"], "segunda compra sigue pendiente")
	_fin("AMBIGUO", "datos diferentes, mismo objetivo visible; el mapa es el único contexto externo de etapa")

	var legados := [
		["comprar_if", 2, "senales_inciertas", "SENALES_INCIERTAS"],
		["comprar_while", 2, "comprar_mapa_3x3", "COMPRAR_MAPA_3X3"],
		["ciclo_autonomo", 2, "comprar_mapa_3x3", "COMPRAR_MAPA_3X3"],
		["comprar_while", 3, "ciclo_recoleccion", "CICLO_RECOLECCION"],
		["ciclo_autonomo", 3, "ciclo_recoleccion", "CICLO_RECOLECCION"],
	]
	for legado in legados:
		_inicio("legado %s con map_tier=%d" % [legado[0], legado[1]])
		var actual := _restaurar(_datos(legado[0], legado[1]))
		_esperar(actual["id"] == legado[2] and actual["estado"] == legado[3], _detalle(actual))
		_esperar(not actual["completada"], "misión reinterpretada sigue activa")
		_fin("COMPORTAMIENTO LEGADO", "MIGRACIÓN INTENCIONAL: " + _detalle(actual))

	_inicio("ID desconocido")
	var desconocida := _restaurar(_datos("mision_que_no_existe", 0))
	_esperar(desconocida["id"] != "mision_que_no_existe", "ID sin catálogo conserva estado genérico y no tiene fallback: " + _detalle(desconocida))
	_esperar(not desconocida["completada"], "no debe figurar completada")
	print("CARACTERIZACIÓN desconocida: ", _detalle(desconocida), "; descriptor=", misiones.get_objetivo_actual())
	_fin()

	_inicio("completed_missions: lista vacía y misión activa")
	var vacia := _restaurar(_datos("camino_largo", 3))
	_esperar(vacia["completadas"].is_empty() and not vacia["completada"], "sin finalización accidental")
	_fin()

	_inicio("completed_missions: varias entradas, recarga y copia independiente")
	var varias := _datos("camino_largo", 3)
	var lista := ["recolectar_primer_mineral", "ruta_calibracion", "trabajo_continuo"]
	varias["completed_missions"] = lista.duplicate()
	_restaurar(varias)
	misiones.aplicar_progreso(progreso.get_current_progress())
	_esperar(misiones.completed_missions == lista, "recargar no introduce duplicados ni pierde entradas")
	_esperar(not misiones.objective_completed, "la lista no completa Camino Largo")
	misiones.completed_missions.append("solo_local")
	_esperar(progreso.get_current_progress()["completed_missions"] == lista and varias["completed_missions"] == lista, "la lista cargada no comparte memoria con caché ni entrada")
	_fin()

	_inicio("completed_missions: duplicados preexistentes")
	var duplicadas := _datos("camino_largo", 3)
	duplicadas["completed_missions"] = ["ruta_calibracion", "ruta_calibracion"]
	var duplicada_actual := _restaurar(duplicadas)
	_esperar(duplicada_actual["completadas"] == duplicadas["completed_missions"], "la carga conserva exactamente los duplicados existentes")
	_fin("AMBIGUO", "MissionService no deduplica la entrada; tampoco añade duplicados nuevos")

	_inicio("completed_missions: misión actual incluida accidentalmente")
	var incluida := _datos("ciclo_recoleccion", 3)
	incluida["completed_missions"] = ["ciclo_recoleccion"]
	var incluida_actual := _restaurar(incluida)
	_esperar(incluida_actual["id"] == "exploracion_3x3" and incluida_actual["estado"] == "EXPLORACION_3X3", _detalle(incluida_actual))
	_esperar(incluida_actual["completadas"] == ["ciclo_recoleccion"] and not incluida_actual["completada"], "solo la misión indicada se considera completada")
	_fin("AMBIGUO", "se confía en completed_missions: no puede distinguir una entrada accidental de una finalización válida")

	_inicio("Variables ya completada")
	var terminada := _datos("variables", 3)
	terminada["completed_missions"] = ["variables"]
	var terminada_actual := _restaurar(terminada)
	_esperar(terminada_actual["id"] == "variables" and terminada_actual["estado"] == "COMPLETADA" and terminada_actual["completada"], _detalle(terminada_actual))
	_fin()

	_inicio("Retorno Base completada conserva transición existente a Variables")
	var retorno_completado := _datos("retorno_base", 3)
	retorno_completado["completed_missions"] = ["retorno_base"]
	var retorno_siguiente := _restaurar(retorno_completado)
	_esperar(retorno_siguiente["id"] == "variables" and retorno_siguiente["estado"] == "VARIABLES" and not retorno_siguiente["completada"], _detalle(retorno_siguiente))
	_esperar(retorno_siguiente["completadas"] == ["retorno_base"], "finalización de Retorno Base conservada")
	_fin()

	_inicio("conocimientos y sintaxis guardados no se pierden")
	var conocimiento := _datos("camino_largo", 2)
	conocimiento["unlocked_knowledge"] = ["objeto", "metodo", "secuencia", "parametro"]
	conocimiento["unlocked_syntax"] = {"while": true, "for": true, "in range": true, "if": true, "else": true}
	_restaurar(conocimiento)
	for clave in conocimiento["unlocked_knowledge"]:
		_esperar(clave in misiones.unlocked_knowledge, "conocimiento conservado: " + clave)
	for clave in conocimiento["unlocked_syntax"]:
		_esperar(sintaxis.get_sintaxis_desbloqueada().get(clave, false), "sintaxis conservada: " + clave)
	_esperar(progreso.get_current_progress() == conocimiento, "enriquecimiento local no reescribe progreso guardado")
	_fin()

	for mapa in [[0, "recolectar_primer_mineral"], [1, "trabajo_continuo"], [2, "senales_inciertas"]]:
		_inicio("map_tier=%d conserva etapa y dato de mapa" % mapa[0])
		var datos := _datos(mapa[1], mapa[0])
		var actual := _restaurar(datos)
		_esperar(actual["id"] == mapa[1], "sin salto inesperado: " + _detalle(actual))
		_esperar(mundo.get_map_tier() == mapa[0] and progreso.get_current_progress()["map_tier"] == mapa[0], "MissionService no degrada el mapa aplicado ni la caché")
		_fin()

	_inicio("compra 2x3 ya aplicada: transición por map_tier")
	var comprada := _restaurar(_datos("comprar_casillas", 2))
	_esperar(comprada["id"] == "senales_inciertas" and comprada["estado"] == "SENALES_INCIERTAS", _detalle(comprada))
	_fin()

	# Caracterización con aplicar_progreso REAL de interfaz y guardado sobrescrito.
	_inicio("orden real de UI: recursos anteriores cambian la transición")
	var orden := _datos("trabajo_continuo", 1)
	orden["completed_missions"] = ["ruta_calibracion", "trabajo_continuo"]
	orden["minerals_ship"] = 12
	var antes := _restaurar_desde_ui(orden, 0)
	var despues := _restaurar_desde_ui(orden, 12)
	_esperar(antes["nave"] == 12 and despues["nave"] == 12, "ambos órdenes terminan con los recursos guardados")
	_esperar(antes["id"] == despues["id"] and antes["estado"] == despues["estado"] and antes["completada"] == despues["completada"], "mismo progreso debe producir misma misión; UI previa=0: %s; UI previa=12: %s" % [_detalle(antes), _detalle(despues)])
	print("CARACTERIZACIÓN orden: previa=0 ", _detalle(antes), "; previa=12 ", _detalle(despues))
	_fin()

	_inicio("aislamiento final: ningún guardado ni petición pendiente")
	_esperar(progreso.pending_operation == "" and progreso.pending_save_progress.is_empty(), "sin operaciones de progreso")
	_esperar(not root.get_node("AttemptService").request_in_flight and root.get_node("AttemptService").pending_attempts.is_empty(), "sin intentos remotos")
	_esperar(not root.get_node("Supabase").is_authenticated(), "sesión sigue invitada")
	_fin()
	_limpiar()
	current_scene = null
	mundo.free()
	ui.free()
	ada.free()
	print("RESUMEN RESTAURACIÓN: ", totales, "; comprobaciones=", comprobaciones)
	quit(1 if totales["BUG CONFIRMADO"] > 0 else 0)


func _datos(id: String, tier: int) -> Dictionary:
	return {"current_mission_id": id, "completed_missions": [], "minerals_ship": 0, "minerals_spid": 0, "map_tier": tier, "unlocked_knowledge": ["objeto", "metodo"], "unlocked_syntax": {}, "hardware_upgrades": {}}


func _limpiar() -> void:
	progreso.clear_progress()
	ui.minerales_nave = 0
	ui.minerales_spid = 0
	ui.mineria_rapida_desbloqueada = false
	mundo.map_tier = 0
	misiones.aplicar_progreso({})
	sintaxis.aplicar_sintaxis_desbloqueada({})


func _preparar(datos: Dictionary) -> void:
	_limpiar()
	# Simula exclusivamente la fila ya cargada; nunca invoca load/save_progress.
	progreso.current_progress = datos.duplicate(true)
	mundo.map_tier = int(datos.get("map_tier", 0))
	sintaxis.aplicar_sintaxis_desbloqueada(datos.get("unlocked_syntax", {}))


func _restaurar(datos: Dictionary) -> Dictionary:
	_preparar(datos)
	ui.minerales_nave = int(datos.get("minerals_ship", 0))
	ui.minerales_spid = int(datos.get("minerals_spid", 0))
	misiones.aplicar_progreso(progreso.get_current_progress())
	return _instantanea()


func _restaurar_desde_ui(datos: Dictionary, minerales_previos: int) -> Dictionary:
	_preparar(datos)
	ui.minerales_nave = minerales_previos
	ui.aplicar_progreso(progreso.get_current_progress())
	return _instantanea()


func _instantanea() -> Dictionary:
	return {"id": misiones.objective_id, "estado": misiones.EstadoMision.find_key(misiones.estado_actual), "completada": misiones.objective_completed, "completadas": misiones.get_completed_missions(), "nave": ui.minerales_nave}


func _detalle(actual: Dictionary) -> String:
	return "id=%s estado=%s completada=%s nave=%d" % [actual["id"], actual["estado"], actual["completada"], actual["nave"]]


func _inicio(nombre: String) -> void:
	nombre_caso = nombre
	problemas.clear()


func _esperar(condicion: bool, detalle: String) -> void:
	comprobaciones += 1
	if not condicion:
		problemas.append(detalle)


func _fin(clasificacion: String = "PASS", nota: String = "") -> void:
	if not problemas.is_empty():
		clasificacion = "BUG CONFIRMADO"
		for problema in problemas:
			print("  EXPECTATIVA INCUMPLIDA: ", problema)
	totales[clasificacion] += 1
	print("[", clasificacion, "] ", nombre_caso, ": ", nota)
