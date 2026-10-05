extends Node

signal mision_iniciada(mision_id: String)
signal objetivo_actualizado(mision_id: String, objetivo: String)
signal mision_completada(mision_id: String)
signal conocimiento_desbloqueado(conocimiento_id: String)

enum EstadoMision {
	SIN_INICIAR,
	BUSCAR_MINERAL,
	TRANSFERIR_MINERAL,
	COMPLETADA,
	COMPRAR_CASILLAS,
	CICLO_RECOLECCION,
	TRABAJO_CONTINUO,
	CUOTA_SUMINISTRO,
	CAMINO_LARGO,
	RETORNO_BASE,
	VARIABLES,
	COMPRAR_IF,
	SENALES_INCIERTAS,
	COMPRAR_WHILE,
	CICLO_AUTONOMO,
	COMPRAR_MAPA_3X3,
	EXPLORACION_3X3,
}

var objective_id: String = "recolectar_primer_mineral"
var objective_completed: bool = false
var estado_actual: EstadoMision = EstadoMision.SIN_INICIAR

var completed_missions: Array = []
var unlocked_knowledge: Array = [
	"objeto",
	"metodo"
]


func _ready() -> void:
	iniciar_mision()


func iniciar_mision() -> void:
	objective_completed = false
	estado_actual = EstadoMision.BUSCAR_MINERAL

	mision_iniciada.emit(objective_id)

	objetivo_actualizado.emit(
		objective_id,
		"Encuentra una muestra y ejecuta spid.minar()."
	)
	
func iniciar_ruta_calibracion() -> void:
	objective_id = "ruta_calibracion"
	objective_completed = false
	estado_actual = EstadoMision.BUSCAR_MINERAL

	mision_iniciada.emit(objective_id)

	objetivo_actualizado.emit(
		objective_id,
		"RUTA DE CALIBRACION\n" +
		"Programa una secuencia para avanzar al mineral, " +
        "extraerlo, regresar a la casilla inicial y transferirlo."
	)

	print("Mision iniciada: ruta_calibracion")


func reiniciar_mision() -> void:
	iniciar_mision()


func preparar_mision_expansion() -> void:
	if not objective_completed:
		return

	if objective_id == "ruta_calibracion":
		iniciar_trabajo_continuo()
		return

	if objective_id == "trabajo_continuo":
		iniciar_cuota_suministro()
		return

	if objective_id == "cuota_suministro":
		iniciar_mision_comprar_casillas()
		return

	if objective_id == "comprar_casillas":
		iniciar_senales_inciertas()
		return

	if objective_id == "senales_inciertas":
		iniciar_mision_comprar_mapa_3x3()
		return

	if objective_id == "comprar_mapa_3x3":
		iniciar_ciclo_recoleccion()
		return

	if objective_id == "ciclo_recoleccion":
		iniciar_exploracion_3x3()
		return

	if objective_id == "exploracion_3x3":
		iniciar_camino_largo()
		return

	if objective_id == "camino_largo":
		iniciar_variables()
		return

	if objective_id == "retorno_base":
		iniciar_variables()
		return


func iniciar_mision_comprar_casillas() -> void:
	objective_id = "comprar_casillas"
	var map_tier: int = int(ProgressService.get_current_progress().get("map_tier", 0))
	objective_completed = "comprar_casillas" in completed_missions or map_tier >= 2
	if objective_completed:
		iniciar_senales_inciertas()
		return
	estado_actual = EstadoMision.COMPRAR_CASILLAS
	mision_iniciada.emit(objective_id)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	print("Misión iniciada: comprar_casillas")


func registrar_compra_casillas() -> void:
	if "comprar_casillas" not in completed_missions:
		completed_missions.append("comprar_casillas")

	# DESBLOQUEO DE FASE 3: IF y ELSE al expandir a 2x3
	GestorSintaxis.desbloquear_sintaxis("if")
	GestorSintaxis.desbloquear_sintaxis("else")
	desbloquear_conocimiento("condicional_if")

	if objective_id == "comprar_casillas":
		objective_completed = true
		estado_actual = EstadoMision.COMPLETADA
		mision_completada.emit("comprar_casillas")
		iniciar_senales_inciertas()
	else:
		mision_completada.emit("compra_temprana_casillas")


func evaluar_objetivo(minerales_recolectados: int) -> void:
	registrar_mineral_recolectado(minerales_recolectados)


func registrar_mineral_recolectado(cantidad: int) -> void:
	if estado_actual != EstadoMision.BUSCAR_MINERAL:
		return

	if cantidad <= 0:
		return

	estado_actual = EstadoMision.TRANSFERIR_MINERAL

	objetivo_actualizado.emit(
		objective_id,
		"Buen trabajo. La muestra fue extraida correctamente. " +
		"Progreso 1 de 2: ahora ejecuta spid.transferir() " +
		"para enviarla a la nave."
	)

	print("Mision actualizada: transferir el mineral.")


func registrar_transferencia(cantidad: int) -> void:
	if estado_actual != EstadoMision.TRANSFERIR_MINERAL:
		return

	if cantidad <= 0:
		return

	if objective_id == "ruta_calibracion":
		return

	var mision_completada_id := objective_id

	estado_actual = EstadoMision.COMPLETADA
	objective_completed = true

	if mision_completada_id not in completed_missions:
		completed_missions.append(mision_completada_id)

	desbloquear_conocimiento("secuencia")

	# Después de la primera muestra, el siguiente objetivo es ampliar el mapa.
	if mision_completada_id == "recolectar_primer_mineral":
		objective_id = "comprar_casillas"
		objective_completed = "comprar_casillas" in completed_missions
		estado_actual = (
			EstadoMision.COMPLETADA
			if objective_completed
			else EstadoMision.COMPRAR_CASILLAS
		)
	mision_completada.emit(mision_completada_id)

	if mision_completada_id == "recolectar_primer_mineral":
		mision_iniciada.emit(objective_id)
		objetivo_actualizado.emit(
			objective_id,
			"Has almacenado tu primera muestra. " +
			"Ahora amplía el sector desde el Centro de Mejoras."
		)

	print("Misión completada: ", mision_completada_id)
	print("Conocimiento desbloqueado: secuencia")


func desbloquear_conocimiento(conocimiento_id: String) -> void:
	if conocimiento_id in unlocked_knowledge:
		return

	unlocked_knowledge.append(conocimiento_id)
	conocimiento_desbloqueado.emit(conocimiento_id)
	
func aplicar_progreso(progress: Dictionary) -> void:
	objective_id = str(
		progress.get(
			"current_mission_id",
			"recolectar_primer_mineral"
		)
	)
	
	var misiones_guardadas = progress.get(
		"completed_missions",
		[]
	)

	if typeof(misiones_guardadas) == TYPE_ARRAY:
		completed_missions = misiones_guardadas.duplicate()
	else:
		completed_missions = []

	var conocimientos_guardados = progress.get(
		"unlocked_knowledge",
		["objeto", "metodo"]
	)

	if typeof(conocimientos_guardados) == TYPE_ARRAY:
		unlocked_knowledge = conocimientos_guardados.duplicate()
	else:
		unlocked_knowledge = [
			"objeto",
			"metodo"
		]

	var tier_guardado: int = int(progress.get("map_tier", 0))
	if tier_guardado >= 2:
		GestorSintaxis.desbloquear_sintaxis("if")
		GestorSintaxis.desbloquear_sintaxis("else")
		desbloquear_conocimiento("condicional_if")
	if tier_guardado >= 3:
		GestorSintaxis.desbloquear_sintaxis("for")
		GestorSintaxis.desbloquear_sintaxis("in range")
		desbloquear_conocimiento("bucle_for")

	objective_completed = objective_id in completed_missions
	preparar_mision_expansion()

	if (
		(objective_id == "trabajo_continuo" and objective_completed)
		or (objective_id == "trabajo_continuo" and "trabajo_continuo" in completed_missions)
	):
		iniciar_cuota_suministro()
		return
	if objective_id == "trabajo_continuo":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.TRABAJO_CONTINUO
		return

	if (
		(objective_id == "cuota_suministro" and objective_completed)
		or (objective_id == "cuota_suministro" and "cuota_suministro" in completed_missions)
	):
		iniciar_mision_comprar_casillas()
		return
	if objective_id == "cuota_suministro":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.CUOTA_SUMINISTRO
		return

	if (
		(objective_id == "comprar_casillas" and objective_completed)
		or (objective_id == "comprar_casillas" and "comprar_casillas" in completed_missions)
		or (objective_id == "comprar_casillas" and tier_guardado >= 2)
	):
		iniciar_senales_inciertas()
		return
	if objective_id == "comprar_casillas":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.COMPRAR_CASILLAS
		return

	if (
		(objective_id == "senales_inciertas" and objective_completed)
		or (objective_id == "senales_inciertas" and "senales_inciertas" in completed_missions)
	):
		iniciar_mision_comprar_mapa_3x3()
		return
	if objective_id == "senales_inciertas":
		if tier_guardado < 2 and "comprar_casillas" not in completed_missions:
			iniciar_mision_comprar_casillas()
		else:
			estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.SENALES_INCIERTAS
		return

	# Compatibilidad con partidas antiguas
	if objective_id == "comprar_if":
		iniciar_senales_inciertas()
		return
	if objective_id in ["comprar_while", "ciclo_autonomo"]:
		iniciar_mision_comprar_mapa_3x3()
		return

	if (
		objective_id == "comprar_mapa_3x3"
		and (objective_completed or tier_guardado >= 3 or "comprar_mapa_3x3" in completed_missions)
	):
		iniciar_ciclo_recoleccion()
		return
	if objective_id == "comprar_mapa_3x3":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.COMPRAR_MAPA_3X3
		return

	if (
		(objective_id == "ciclo_recoleccion" and objective_completed)
		or (objective_id == "ciclo_recoleccion" and "ciclo_recoleccion" in completed_missions)
	):
		iniciar_exploracion_3x3()
		return
	if objective_id == "ciclo_recoleccion":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.CICLO_RECOLECCION
		return

	if (
		(objective_id == "exploracion_3x3" and objective_completed)
		or (objective_id == "exploracion_3x3" and "exploracion_3x3" in completed_missions)
	):
		iniciar_camino_largo()
		return
	if objective_id == "exploracion_3x3":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.EXPLORACION_3X3
		return

	if (
		(objective_id == "camino_largo" and objective_completed)
		or (objective_id == "camino_largo" and "camino_largo" in completed_missions)
	):
		iniciar_variables()
		return
	if objective_id == "camino_largo":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.CAMINO_LARGO
		return
	if (
		objective_id == "recolectar_primer_mineral"
		and objective_completed
		and int(progress.get("map_tier", 0)) >= 1
	):
		iniciar_ruta_calibracion()
		return
	if objective_completed:
		estado_actual = EstadoMision.COMPLETADA
	elif int(progress.get("minerals_spid", 0)) > 0:
		# Permite continuar si el jugador cerró el juego después de minar.
		estado_actual = EstadoMision.TRANSFERIR_MINERAL
	else:
		estado_actual = EstadoMision.BUSCAR_MINERAL

	print(
		"Progreso de misión cargado: ",
		objective_id,
		" | Completada: ",
		objective_completed
	)


func get_objetivo_actual() -> String:
	if objective_completed:
		return "Misión completada."
	if objective_id == "trabajo_continuo":
		return (
			"AUTOMATIZACIÓN CONTINUA (WHILE TRUE)\n" +
			"Un bucle 'while True:' repite instrucciones indefinidamente.\n\n" +
			"while True:\n" +
			"    spid.norte()\n" +
			"    spid.minar()\n" +
			"    spid.sur()\n" +
			"    spid.transferir()\n\n" +
			"Tu desafío: programa a spid para abastecer la nave de forma continua. " +
			"Deja que complete al menos 2 ciclos de recolección."
		)

	if objective_id == "cuota_suministro":
		return (
			"CUOTA DE SUMINISTRO (CONDICIÓN WHILE)\n" +
			"La nave nodriza necesita 10 minerales para fabricar el nuevo Sector 2x3.\n" +
			"Usa una condición de parada para que spid se detenga al alcanzar la cuota:\n\n" +
			"while spid.minerales_en_nave() < 10:\n" +
			"    spid.norte()\n" +
			"    spid.minar()\n" +
			"    spid.sur()\n" +
			"    spid.transferir()\n\n" +
			"Tu desafío: acumula 10 minerales en la nave nodriza usando un bucle condicional."
		)

	if objective_id == "comprar_casillas":
		return (
			"EXPANSIÓN DE SECTOR (+3 CASILLAS)\n" +
			"Reúne 10 minerales y adquiere [ +3 CASILLAS ] " +
			"en el Centro de Mejoras para expandir el terreno a 2x3."
		)

	if objective_id == "comprar_if":
		return (
			"ADQUISICIÓN DE SENSOR (CONDICIONAL IF)\n" +
			"Reúne 10 minerales en la nave y adquiere el [ CONDICIONAL IF ] " +
			"en el Centro de Mejoras para habilitar el sensor spid.hay_mineral()."
		)

	if objective_id == "ciclo_recoleccion":
		return (
			"CICLO DE RECOLECCIÓN (BUCLE FOR)\n" +
			"Un bucle for repite instrucciones un número exacto de veces: for ciclo in range(N):\n\n" +
			"for ciclo in range(3):\n" +
			"    spid.norte()\n" +
			"    spid.minar()\n" +
			"    spid.sur()\n" +
			"    spid.transferir()\n\n" +
			"Tu desafío: en el nuevo sector 3x3, usa 'for' y 'range()' para recolectar al menos 2 minerales " +
			"y transferirlos a la nave en la base."
		)

	if objective_id == "ruta_calibracion":
		return (
			"Ejecuta norte, minar, sur y transferir " +
			"una sola vez, en ese orden y en un mismo programa."
		)

	if objective_id == "senales_inciertas":
		return (
			"SEÑALES INCIERTAS (CONDICIONAL IF / ELSE)\n" +
			"Las lecturas minerales en el nuevo Sector 2x3 son inestables y variables.\n" +
			"Spid debe censar el terreno antes de actuar. Puedes resolverlo de dos formas:\n\n" +
			"• Opción 1: Plan de contingencia (IF / ELSE):\n" +
			"spid.norte()\n" +
			"if spid.hay_mineral():\n" +
			"    spid.minar()\n" +
			"else:\n" +
			"    spid.este()\n" +
			"    spid.minar()\n" +
			"    spid.oeste()\n" +
			"spid.sur()\n" +
			"spid.transferir()\n\n" +
			"• Opción 2: Patrulla continua (WHILE con IF / ELSE):\n" +
			"Recorre el sector combinando while con if (o if/else) para censar casillas.\n\n" +
			"Tu desafío: extrae al menos 1 mineral usando condicionales y transfiérelo a la nave."
		)

	if objective_id == "comprar_while":
		return (
			"AUTOMATIZACIÓN AVANZADA (BUCLE WHILE)\n" +
			"Reúne 15 minerales en la nave y adquiere el [ BUCLE WHILE ] " +
			"en el Centro de Mejoras para desbloquear ciclos condicionales continuos."
		)
	if objective_id == "ciclo_autonomo":
		return (
			"CICLO AUTÓNOMO (BUCLE WHILE)\n" +
			"A diferencia de for, un bucle while repite instrucciones mientras una condición sea verdadera.\n\n" +
			"Por ejemplo:\n" +
			"while spid.tiene_espacio():\n" +
			"    # patrulla y mina\n" +
			"spid.transferir()\n\n" +
			"Tu desafío: programa un ciclo while que patrulle y extraiga recursos hasta " +
			"recolectar al menos 3 minerales y transferirlos a la nave."
		)
	if objective_id == "comprar_mapa_3x3":
		return (
			"EXPANSIÓN DE SECTOR (SECTOR 3X3)\n" +
			"Reúne 20 minerales en la nave y adquiere el [ SECTOR 3X3 ] " +
			"en el Centro de Mejoras para ampliar el terreno e instalar el módulo BUCLE FOR."
		)
	if objective_id == "exploracion_3x3":
		return (
			"BARRIDO DE CUADRANTE (SECTOR 3X3)\n" +
			"El nuevo sector contiene múltiples depósitos de mineral simultáneos.\n\n" +
			"Tu desafío: programa una rutina combinando bucles 'for' y el sensor condicional " +
			"'if spid.hay_mineral():' para barrer las casillas, recolectar al menos 3 minerales y transferirlos a la base."
		)
	if objective_id == "retorno_base":
		return (
			"RETORNO A BASE (CONDICIÓN NOT)\n" +
			"Haz que spid regrese de forma autónoma usando:\n\n" +
			"while not spid.en_base():\n" +
			"    spid.sur()\n\n" +
			"El ciclo debe detenerse al detectar que spid llegó a la base."
		)

	if objective_id == "variables":
		return (
			"VARIABLES DINÁMICAS (ASIGNACIÓN Y USO)\n" +
			"Una variable almacena datos en memoria para reutilizarlos:\n\n" +
			"pasos = 2\n" +
			"spid.norte(pasos)\n\n" +
			"Tu desafío: define una variable con un valor numérico (ej. pasos = 2), " +
			"utilízala como argumento en los comandos dspid o en range(), extrae un mineral " +
			"y transfírelo a la nave en la base."
		)

	match estado_actual:
		EstadoMision.BUSCAR_MINERAL:
			return "Minar la primera muestra."
		EstadoMision.TRANSFERIR_MINERAL:
			return "Transferir la primera muestra."
		_:
			return "Misión sin iniciar."


func get_completed_missions() -> Array:
	return completed_missions.duplicate()


func get_unlocked_knowledge() -> Array:
	return unlocked_knowledge.duplicate()

func _obtener_minerales_nave() -> int:
	var root := Engine.get_main_loop() as SceneTree
	if root != null and root.current_scene != null:
		var interfaz = root.current_scene.get_node_or_null("CanvasLayer")
		if interfaz != null and "minerales_nave" in interfaz:
			return int(interfaz.minerales_nave)
	var progreso_actual: Dictionary = ProgressService.get_current_progress()
	return int(progreso_actual.get("minerals_ship", 0))

func evaluar_programa(resultado: Dictionary) -> void:
	if objective_completed:
		return

	if not resultado.get("success", false):
		return

	if objective_id == "exploracion_3x3":
		_evaluar_exploracion_3x3(resultado)
		return

	if objective_id == "comprar_mapa_3x3":
		var minerales_nave: int = _obtener_minerales_nave()
		if minerales_nave >= 20:
			objetivo_actualizado.emit(
				objective_id,
				"¡Ya tienes los 20 minerales necesarios! Ve al menú MEJORAS y adquiere el [ SECTOR 3X3 ] para continuar."
			)
		else:
			objetivo_actualizado.emit(
				objective_id,
				"Tienes %d de 20 minerales en la nave. Sigue recolectando y luego adquiere el [ SECTOR 3X3 ] en MEJORAS." % minerales_nave
			)
		return

	if objective_id == "ciclo_autonomo":
		_evaluar_ciclo_autonomo(resultado)
		return

	if objective_id == "comprar_while":
		return

	if objective_id == "senales_inciertas":
		_evaluar_senales_inciertas(resultado)
		return

	if objective_id == "comprar_if":
		_evaluar_comprar_if(resultado)
		return

	if objective_id == "camino_largo":
		_evaluar_camino_largo(resultado)
		return

	if objective_id == "retorno_base":
		_evaluar_retorno_base(resultado)
		return

	if objective_id == "variables":
		_evaluar_variables(resultado)
		return
	
	if objective_id == "cuota_suministro":
		_evaluar_cuota_suministro(resultado)
		return

	if objective_id == "trabajo_continuo":
		_evaluar_trabajo_continuo(resultado)
		return

	if objective_id == "ciclo_recoleccion":
		_evaluar_ciclo_recoleccion(resultado)
		return

	if objective_id != "ruta_calibracion":
		return

	var comandos: Array = resultado.get("commands_used", [])
	var secuencia_esperada: Array = [
		"norte",
		"minar",
		"sur",
		"transferir"
	]

	if comandos == secuencia_esperada:
		estado_actual = EstadoMision.COMPLETADA
		objective_completed = true

		if objective_id not in completed_missions:
			completed_missions.append(objective_id)

		mision_completada.emit(objective_id)
		print("Misión completada con la secuencia correcta.")
		iniciar_trabajo_continuo()
		return

	if "transferir" in comandos:
		estado_actual = EstadoMision.BUSCAR_MINERAL
		objetivo_actualizado.emit(
			objective_id,
			"Para calibrar, ejecuta una sola vez y en este orden: " +
			"norte, minar, sur y transferir, dentro del mismo programa."
		)

func _evaluar_trabajo_continuo(resultado: Dictionary) -> void:
	var codigo: String = str(resultado.get("code", "")).to_lower().replace(" ", "")
	var comandos: Array = resultado.get("commands_used", [])
	var bucle_detectado: int = int(resultado.get("loop_count", 0))
	var iteraciones: int = int(resultado.get("loop_iterations", 0))

	var usa_while_true: bool = codigo.contains("whiletrue:") or codigo.contains("while1:")

	if not usa_while_true or bucle_detectado < 1:
		objetivo_actualizado.emit(
			objective_id,
			"Para esta misión de automatización continua debes usar 'while True:'."
		)
		return

	var cumple_objetivo: bool = (
		iteraciones >= 2
		and comandos.count("norte") >= 2
		and comandos.count("minar") >= 2
		and comandos.count("sur") >= 2
		and comandos.count("transferir") >= 2
	)

	if not cumple_objetivo:
		objetivo_actualizado.emit(
			objective_id,
			"El ciclo todavía está incompleto. " +
			"Spid debe repetir al menos dos veces la rutina " +
			"norte, minar, sur y transferir usando 'while True:'."
		)
		return

	objective_completed = true
	estado_actual = EstadoMision.COMPLETADA

	if objective_id not in completed_missions:
		completed_missions.append(objective_id)

	mision_completada.emit(objective_id)
	print("Misión de automatización (while True) completada.")
	iniciar_cuota_suministro()

func _evaluar_ciclo_recoleccion(resultado: Dictionary) -> void:
	var comandos: Array = resultado.get("commands_used", [])
	var bucle_detectado: int = int(resultado.get("loop_count", 0))
	var iteraciones: int = int(resultado.get("loop_iterations", 0))
	var recolectados: int = int(resultado.get("minerals_collected", 0))
	var transferidos: int = int(resultado.get("minerals_transferred", 0))

	var _termina_transfiriendo: bool = false
	if not comandos.is_empty():
		_termina_transfiriendo = comandos.back() == "transferir"

	if bucle_detectado < 1 and iteraciones < 1:
		objetivo_actualizado.emit(
			objective_id,
			"Debes usar la estructura 'for <variable> in range(<N>):' para automatizar la repetición."
		)
		return

	if recolectados < 2 or transferidos < 2:
		objetivo_actualizado.emit(
			objective_id,
			"Programa terminado. Recogiste %d minerales y transferiste %d. " % [recolectados, transferidos] +
			"El desafío requiere recoger al menos 2 minerales usando for y transferirlos a la base."
		)
		return

	objective_completed = true
	estado_actual = EstadoMision.COMPLETADA

	if objective_id not in completed_missions:
		completed_missions.append(objective_id)

	mision_completada.emit(objective_id)
	print("Ciclo de recolección completado.")
	iniciar_exploracion_3x3()

	
func desbloquear_modulo_for() -> void:
	GestorSintaxis.desbloquear_sintaxis("for")
	GestorSintaxis.desbloquear_sintaxis("in range")
	desbloquear_conocimiento("bucle_for")
	
func desbloquear_modulo_while() -> void:
	GestorSintaxis.desbloquear_sintaxis("while")
	desbloquear_conocimiento("bucle_while")

func iniciar_ciclo_recoleccion() -> void:
	objective_id = "ciclo_recoleccion"
	objective_completed = "ciclo_recoleccion" in completed_missions
	estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.CICLO_RECOLECCION

	desbloquear_modulo_for()
	mision_iniciada.emit(objective_id)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	print("Misión iniciada: ciclo_recoleccion")

func iniciar_trabajo_continuo() -> void:
	objective_id = "trabajo_continuo"
	objective_completed = "trabajo_continuo" in completed_missions
	estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.TRABAJO_CONTINUO

	desbloquear_modulo_while()
	mision_iniciada.emit(objective_id)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	print("Misión iniciada: trabajo_continuo")


func iniciar_cuota_suministro() -> void:
	objective_id = "cuota_suministro"
	var minerales_nave: int = _obtener_minerales_nave()
	objective_completed = "cuota_suministro" in completed_missions or minerales_nave >= 10
	estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.CUOTA_SUMINISTRO

	mision_iniciada.emit(objective_id)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	print("Misión iniciada: cuota_suministro")


func _evaluar_cuota_suministro(resultado: Dictionary) -> void:
	var codigo: String = str(resultado.get("code", "")).to_lower().replace(" ", "")
	var iteraciones: int = int(resultado.get("loop_iterations", 0))
	var minerales_nave: int = _obtener_minerales_nave()

	if codigo.contains("whiletrue:") or codigo.contains("while1:"):
		objetivo_actualizado.emit(
			objective_id,
			"En esta misión no debes usar un bucle infinito 'while True:'. " +
			"Usa una condición de parada lógica, como 'while spid.minerales_en_nave() < 10:'."
		)
		return

	if iteraciones < 1:
		if codigo.contains("while") and (codigo.contains("<10") or codigo.contains("<=10")) and minerales_nave >= 10:
			objetivo_actualizado.emit(
				objective_id,
				"¡Ya tienes %d minerales en la nave! " % minerales_nave +
				"Como ya superaste 10, la condición '< 10' fue falsa desde el inicio y el bucle no arrancó. " +
				"Prueba con una meta más alta (ej: 'while spid.minerales_en_nave() < %d:') para ver a Spid trabajar y frenar solo." % (minerales_nave + 4)
			)
			return
		objetivo_actualizado.emit(
			objective_id,
			"Debes usar un bucle 'while' con una condición de comparación " +
			"(ej: 'while spid.minerales_en_nave() < %d:')." % (maxi(10, minerales_nave + 4))
		)
		return

	if minerales_nave < 10:
		objetivo_actualizado.emit(
			objective_id,
			"Tienes %d de 10 minerales en la nave. " % minerales_nave +
			"Deja que el bucle continúe recolectando hasta alcanzar la meta de 10 minerales."
		)
		return

	objective_completed = true
	estado_actual = EstadoMision.COMPLETADA

	if objective_id not in completed_missions:
		completed_missions.append(objective_id)

	mision_completada.emit(objective_id)
	print("Misión cuota_suministro completada.")
	iniciar_mision_comprar_casillas()

func iniciar_camino_largo() -> void:
	objective_id = "camino_largo"
	objective_completed = "camino_largo" in completed_missions
	estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.CAMINO_LARGO

	mision_iniciada.emit(objective_id)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	print("Misión iniciada: camino_largo")


func _evaluar_camino_largo(resultado: Dictionary) -> void:
	var comandos_data: Array = resultado.get("commands_data", [])
	var recolectados: int = int(resultado.get("minerals_collected", 0))
	var transferidos: int = int(resultado.get("minerals_transferred", 0))

	# 1. Comprobar si usó al menos un parámetro numérico > 1
	var uso_parametro := false
	for cmd in comandos_data:
		if int(cmd.get("steps", 1)) > 1:
			uso_parametro = true
			break

	if not uso_parametro:
		objetivo_actualizado.emit(
			objective_id,
			"Para completar esta misión debes usar parámetros numéricos mayores a 1. " +
			"Por ejemplo: spid.norte(2) o spid.sur(2) en lugar de dar pasos individuales."
		)
		return

	# 2. Comprobar que haya minado y transferido
	if recolectados < 1 or transferidos < 1:
		objetivo_actualizado.emit(
			objective_id,
			"Buen uso de parámetros, pero debes extraer al menos 1 mineral " +
			"y transferirlo a la nave en la casilla inicial para completar la misión."
		)
		return

	objective_completed = true
	estado_actual = EstadoMision.COMPLETADA

	if objective_id not in completed_missions:
		completed_missions.append(objective_id)

	desbloquear_conocimiento("parametro")
	mision_completada.emit(objective_id)
	iniciar_variables()
	print("Misión camino_largo completada!")


func iniciar_retorno_base() -> void:
	objective_id = "retorno_base"
	objective_completed = "retorno_base" in completed_missions
	estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.RETORNO_BASE
	mision_iniciada.emit(objective_id)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	print("Misión iniciada: retorno_base")


func _evaluar_retorno_base(resultado: Dictionary) -> void:
	var codigo: String = str(resultado.get("code", "")).to_lower().replace(" ", "")
	var iteraciones: int = int(resultado.get("loop_iterations", 0))
	if not codigo.contains("whilenotspid.en_base():") or iteraciones < 1:
		objetivo_actualizado.emit(
			objective_id,
			"Debes usar 'while not spid.en_base():' para que spid regrese " +
			"de forma autónoma y se detenga al llegar a la base."
		)
		return

	objective_completed = true
	estado_actual = EstadoMision.COMPLETADA
	if objective_id not in completed_missions:
		completed_missions.append(objective_id)
	desbloquear_conocimiento("condicion_not")
	mision_completada.emit(objective_id)
	iniciar_variables()
	print("Misión retorno_base completada!")


func iniciar_variables() -> void:
	objective_id = "variables"
	objective_completed = "variables" in completed_missions
	estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.VARIABLES
	mision_iniciada.emit(objective_id)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	print("Misión iniciada: variables")


func _evaluar_variables(resultado: Dictionary) -> void:
	var variables_definidas: Array = resultado.get("variables_defined", [])
	var variables_usadas: Array = resultado.get("variables_used", [])
	var recolectados: int = int(resultado.get("minerals_collected", 0))
	var transferidos: int = int(resultado.get("minerals_transferred", 0))

	if variables_definidas.is_empty():
		objetivo_actualizado.emit(
			objective_id,
			"Para completar esta misión debes definir al menos una variable (ej. 'pasos = 2') antes de usarla."
		)
		return

	if variables_usadas.is_empty():
		objetivo_actualizado.emit(
			objective_id,
			"Definiste una variable, pero debes utilizarla como parámetro en los comandos dspid (ej. 'spid.norte(pasos)') o en 'range()'."
		)
		return

	if recolectados < 1 or transferidos < 1:
		objetivo_actualizado.emit(
			objective_id,
			"Buen uso de variables, pero debes extraer al menos 1 mineral y transferirlo a la nave en la base."
		)
		return

	objective_completed = true
	estado_actual = EstadoMision.COMPLETADA
	if objective_id not in completed_missions:
		completed_missions.append(objective_id)

	desbloquear_conocimiento("variable")
	mision_completada.emit(objective_id)
	print("Misión variables completada!")


func iniciar_mision_comprar_if() -> void:
	objective_id = "comprar_if"
	objective_completed = "comprar_if" in completed_missions or GestorSintaxis.esta_desbloqueada("if")

	if objective_completed:
		iniciar_senales_inciertas()
		return

	estado_actual = EstadoMision.COMPRAR_IF
	mision_iniciada.emit(objective_id)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	print("Misión iniciada: comprar_if")


func registrar_compra_if() -> void:
	if "comprar_if" not in completed_missions:
		completed_missions.append("comprar_if")

	desbloquear_conocimiento("condicional_if")

	if objective_id == "comprar_if":
		objective_completed = true
		estado_actual = EstadoMision.COMPLETADA
		mision_completada.emit("comprar_if")
		iniciar_senales_inciertas()
	else:
		mision_completada.emit("compra_temprana_if")


func _evaluar_comprar_if(resultado: Dictionary) -> void:
	var transferidos: int = int(resultado.get("minerals_transferred", 0))
	if transferidos > 0:
		print("Minerales transferidos en fase de acumulación: ", transferidos)


func iniciar_senales_inciertas() -> void:
	objective_id = "senales_inciertas"
	objective_completed = "senales_inciertas" in completed_missions
	estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.SENALES_INCIERTAS
	mision_iniciada.emit(objective_id)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	print("Misión iniciada: senales_inciertas")


func _evaluar_senales_inciertas(resultado: Dictionary) -> void:
	var codigo: String = str(resultado.get("code", "")).to_lower().replace(" ", "")
	var if_evaluations: int = int(resultado.get("if_evaluations", 0))
	var recolectados: int = int(resultado.get("minerals_collected", 0))
	var transferidos: int = int(resultado.get("minerals_transferred", 0))

	if if_evaluations < 1:
		objetivo_actualizado.emit(
			objective_id,
			"Debes usar la estructura condicional 'if spid.hay_mineral():' para censar " +
			"la casilla antes de intentar minar."
		)
		return

	var usa_else: bool = codigo.contains("else:")
	var usa_bucle_patrulla: bool = codigo.contains("while") and if_evaluations >= 2

	if not usa_else and not usa_bucle_patrulla:
		objetivo_actualizado.emit(
			objective_id,
			"El sensor funcionó, pero debes aplicar una estrategia completa:\n" +
			"1) Un plan de contingencia con 'else:' (si no hay mineral, buscar en otra casilla).\n" +
			"2) O una patrulla continua con 'while' censando cada casilla con 'if'."
		)
		return

	if recolectados < 1 or transferidos < 1:
		objetivo_actualizado.emit(
			objective_id,
			"Buen planteamiento condicional, pero Spid debe localizar al menos 1 mineral, " +
			"extraerlo con la rutina y transferirlo a la nave en la base."
		)
		return

	objective_completed = true
	estado_actual = EstadoMision.COMPLETADA
	if objective_id not in completed_missions:
		completed_missions.append(objective_id)
	desbloquear_conocimiento("condicional_if")
	mision_completada.emit(objective_id)
	print("Misión senales_inciertas completada!")
	iniciar_mision_comprar_mapa_3x3()


func iniciar_mision_comprar_while() -> void:
	objective_id = "comprar_while"
	objective_completed = "comprar_while" in completed_missions or GestorSintaxis.esta_desbloqueada("while")
	if objective_completed:
		iniciar_ciclo_autonomo()
		return
	estado_actual = EstadoMision.COMPRAR_WHILE
	mision_iniciada.emit(objective_id)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	print("Misión iniciada: comprar_while")


func registrar_compra_while() -> void:
	if "comprar_while" not in completed_missions:
		completed_missions.append("comprar_while")

	desbloquear_conocimiento("bucle_while")

	if objective_id == "comprar_while":
		objective_completed = true
		estado_actual = EstadoMision.COMPLETADA
		mision_completada.emit("comprar_while")
		iniciar_ciclo_autonomo()
	else:
		mision_completada.emit("compra_temprana_while")


func iniciar_ciclo_autonomo() -> void:
	objective_id = "ciclo_autonomo"
	objective_completed = "ciclo_autonomo" in completed_missions
	estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.CICLO_AUTONOMO
	mision_iniciada.emit(objective_id)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	print("Misión iniciada: ciclo_autonomo")


func _evaluar_ciclo_autonomo(resultado: Dictionary) -> void:
	var _comandos_usados: Array = resultado.get("commands_used", [])
	var recolectados: int = int(resultado.get("minerals_collected", 0))
	var transferidos: int = int(resultado.get("minerals_transferred", 0))
	var iteraciones: int = int(resultado.get("loop_iterations", 0))
	var if_evaluations: int = int(resultado.get("if_evaluations", 0))
	if iteraciones < 1:
		objetivo_actualizado.emit(
			objective_id,
			"Debes usar la estructura 'while <condicion>:' (como spid.tiene_espacio()) " +
			"para que spid decida de forma autónoma cuándo detenerse."
		)
		return
	if if_evaluations < 1:
		objetivo_actualizado.emit(
			objective_id,
			"El ciclo se repite, pero todavía debes usar 'if spid.hay_mineral():' " +
			"para que spid decida cuándo extraer."
		)
		return
	if recolectados < 3 or transferidos < 3:
		objetivo_actualizado.emit(
			objective_id,
			"El ciclo while funcionó, pero debes recolectar y transferir al menos 3 minerales " +
			"para demostrar la autonomía dspid."
		)
		return
	objective_completed = true
	estado_actual = EstadoMision.COMPLETADA
	if objective_id not in completed_missions:
		completed_missions.append(objective_id)
	desbloquear_conocimiento("bucle_while")
	mision_completada.emit(objective_id)
	print("Misión ciclo_autonomo completada!")


func iniciar_mision_comprar_mapa_3x3() -> void:
	var map_tier: int = int(ProgressService.get_current_progress().get("map_tier", 0))
	objective_id = "comprar_mapa_3x3"
	objective_completed = "comprar_mapa_3x3" in completed_missions or map_tier >= 3
	if objective_completed:
		iniciar_ciclo_recoleccion()
		return
	estado_actual = EstadoMision.COMPRAR_MAPA_3X3
	mision_iniciada.emit(objective_id)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	print("Misión iniciada: comprar_mapa_3x3")


func registrar_compra_mapa_3x3() -> void:
	if "comprar_mapa_3x3" not in completed_missions:
		completed_missions.append("comprar_mapa_3x3")

	# DESBLOQUEO DE FASE 4: FOR e IN RANGE al expandir a 3x3
	GestorSintaxis.desbloquear_sintaxis("for")
	GestorSintaxis.desbloquear_sintaxis("in range")
	desbloquear_conocimiento("bucle_for")

	if objective_id == "comprar_mapa_3x3":
		objective_completed = true
		estado_actual = EstadoMision.COMPLETADA
		mision_completada.emit("comprar_mapa_3x3")
		iniciar_ciclo_recoleccion()
	else:
		mision_completada.emit("compra_temprana_3x3")


func iniciar_exploracion_3x3() -> void:
	objective_id = "exploracion_3x3"
	objective_completed = "exploracion_3x3" in completed_missions
	estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.EXPLORACION_3X3
	mision_iniciada.emit(objective_id)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	print("Misión iniciada: exploracion_3x3")


func _evaluar_exploracion_3x3(resultado: Dictionary) -> void:
	var if_evaluations: int = int(resultado.get("if_evaluations", 0))
	var loop_count: int = int(resultado.get("loop_count", 0))
	var recolectados: int = int(resultado.get("minerals_collected", 0))
	var transferidos: int = int(resultado.get("minerals_transferred", 0))

	if loop_count < 1:
		objetivo_actualizado.emit(
			objective_id,
			"Para explorar el cuadrante necesitas usar un bucle 'while' o 'for' " +
			"que recorra varias casillas."
		)
		return
	if if_evaluations < 1:
		objetivo_actualizado.emit(
			objective_id,
			"Antes de minar, usa 'if spid.hay_mineral():' para leer las señales " +
			"del cuadrante. Los depósitos cambian de posición."
		)
		return
	if recolectados < 3 or transferidos < 3:
		objetivo_actualizado.emit(
			objective_id,
			"Debes recolectar y transferir al menos 3 minerales del sector 3x3 a la base central para completar la expedicion."
		)
		return

	objective_completed = true
	estado_actual = EstadoMision.COMPLETADA
	if objective_id not in completed_missions:
		completed_missions.append(objective_id)
	mision_completada.emit(objective_id)
	print("Misión exploracion_3x3 completada!")
	iniciar_camino_largo()
