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
		iniciar_mision_comprar_casillas()
		return

	if objective_id == "ciclo_autonomo":
		iniciar_mision_comprar_mapa_3x3()
		return

	if objective_id == "exploracion_3x3":
		iniciar_ciclo_recoleccion()
		return

	if objective_id == "ciclo_recoleccion":
		iniciar_camino_largo()
		return

	if objective_id == "retorno_base":
		iniciar_variables()
		return


func iniciar_mision_comprar_casillas() -> void:
	objective_id = "comprar_casillas"
	var map_tier: int = int(ProgressService.get_current_progress().get("map_tier", 0))
	objective_completed = "comprar_casillas" in completed_missions or map_tier >= 2
	if objective_completed:
		if GestorSintaxis.esta_desbloqueada("if") or "comprar_if" in completed_missions:
			iniciar_senales_inciertas()
		else:
			iniciar_mision_comprar_if()
		return
	estado_actual = EstadoMision.COMPRAR_CASILLAS
	mision_iniciada.emit(objective_id)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	print("Misión iniciada: comprar_casillas")


func registrar_compra_casillas() -> void:
	if "comprar_casillas" not in completed_missions:
		completed_missions.append("comprar_casillas")

	if objective_id == "comprar_casillas":
		objective_completed = true
		estado_actual = EstadoMision.COMPLETADA
		mision_completada.emit("comprar_casillas")
		if GestorSintaxis.esta_desbloqueada("if") or "comprar_if" in completed_missions:
			iniciar_senales_inciertas()
		else:
			iniciar_mision_comprar_if()
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

	objective_completed = objective_id in completed_missions
	preparar_mision_expansion()

	if (
		(objective_id == "trabajo_continuo" and objective_completed)
		or (objective_id == "trabajo_continuo" and "trabajo_continuo" in completed_missions)
	):
		iniciar_mision_comprar_casillas()
		return
	if objective_id == "trabajo_continuo":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.TRABAJO_CONTINUO
		return
	if (
		(objective_id == "comprar_casillas" and objective_completed)
		or (objective_id == "comprar_casillas" and "comprar_casillas" in completed_missions)
		or (objective_id == "comprar_casillas" and int(progress.get("map_tier", 0)) >= 2)
	):
		if GestorSintaxis.esta_desbloqueada("if") or "comprar_if" in completed_missions:
			iniciar_senales_inciertas()
		else:
			iniciar_mision_comprar_if()
		return
	if objective_id == "comprar_casillas":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.COMPRAR_CASILLAS
		return
	if (
		(objective_id == "ciclo_recoleccion" and objective_completed)
		or (objective_id == "ciclo_recoleccion" and "ciclo_recoleccion" in completed_missions)
	):
		iniciar_camino_largo()
		return
	if objective_id == "ciclo_recoleccion":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.CICLO_RECOLECCION
		return
	if (
		objective_id == "comprar_if"
		and (objective_completed or GestorSintaxis.esta_desbloqueada("if") or "comprar_if" in completed_missions)
	):
		iniciar_senales_inciertas()
		return
	if objective_id == "comprar_if":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.COMPRAR_IF
		return
	if (
		(objective_id == "senales_inciertas" and objective_completed)
		or (objective_id == "senales_inciertas" and "senales_inciertas" in completed_missions)
	):
		iniciar_ciclo_autonomo()
		return
	if objective_id == "senales_inciertas":
		if not GestorSintaxis.esta_desbloqueada("if") and "comprar_if" not in completed_missions:
			iniciar_mision_comprar_if()
		else:
			estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.SENALES_INCIERTAS
		return
	if (
		objective_id == "comprar_while"
		and (objective_completed or GestorSintaxis.esta_desbloqueada("while") or "comprar_while" in completed_missions)
	):
		iniciar_ciclo_autonomo()
		return
	if objective_id == "comprar_while":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.COMPRAR_WHILE
		return
	if (
		(objective_id == "ciclo_autonomo" and objective_completed)
		or (objective_id == "ciclo_autonomo" and "ciclo_autonomo" in completed_missions)
	):
		iniciar_mision_comprar_mapa_3x3()
		return
	if objective_id == "ciclo_autonomo":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.CICLO_AUTONOMO
		return
	if (
		objective_id == "comprar_mapa_3x3"
		and (objective_completed or int(progress.get("map_tier", 0)) >= 3 or "comprar_mapa_3x3" in completed_missions)
	):
		iniciar_exploracion_3x3()
		return
	if objective_id == "comprar_mapa_3x3":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.COMPRAR_MAPA_3X3
		return
	if (
		(objective_id == "exploracion_3x3" and objective_completed)
		or (objective_id == "exploracion_3x3" and "exploracion_3x3" in completed_missions)
	):
		iniciar_ciclo_recoleccion()
		return
	if objective_id == "exploracion_3x3":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.EXPLORACION_3X3
		return
	if objective_id == "comprar_casillas":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.COMPRAR_CASILLAS
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
			"CICLO DE SUMINISTRO (BUCLE WHILE)\n" +
			"Programa spid para viajar al mineral del norte, extraerlo, " +
			"regresar a la base y transferirlo. Repite el ciclo usando while."
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
			"Un bucle for repite instrucciones un número exacto de veces: for ciclo in range(N):\n" +
			"Tu desafío: en el nuevo sector 2x3, usa for para recolectar al menos 2 minerales " +
			"y transferirlos a la nave en la base."
		)

	if objective_id == "ruta_calibracion":
		return (
			"Ejecuta norte, minar, sur y transferir " +
			"una sola vez, en ese orden y en un mismo programa."
		)

	if objective_id == "senales_inciertas":
		return (
			"SEÑALES INCIERTAS (SENSORES E IF)\n" +
			"Las lecturas minerales en este sector son inestables.\n" +
			"Usa el sensor spid.hay_mineral() y la estructura condicional:\n\n" +
			"if spid.hay_mineral():\n" +
			"    spid.minar()\n\n" +
			"Tu desafío: navega a una casilla sospechosa, evalúa con if si hay mineral " +
			"antes de extraerlo, y transfiere el cargamento a la nave."
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
			"en el Centro de Mejoras para ampliar el terreno de operaciones."
		)
	if objective_id == "exploracion_3x3":
		return (
			"BARRIDO DE CUADRANTE (SECTOR 3X3)\n" +
			"El nuevo sector contiene 3 depósitos de mineral simultáneos y variables.\n\n" +
			"Tu desafío: programa una rutina combinando bucles (while o for) y el sensor condicional " +
			"'if spid.hay_mineral():' para recolectar al menos 3 minerales y transferirlos a la base."
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

func evaluar_programa(resultado: Dictionary) -> void:
	if objective_completed:
		return

	if not resultado.get("success", false):
		return

	if objective_id == "exploracion_3x3":
		_evaluar_exploracion_3x3(resultado)
		return

	if objective_id == "comprar_mapa_3x3":
		var progreso_actual: Dictionary = ProgressService.get_current_progress()
		var minerales_nave: int = int(progreso_actual.get("minerals_ship", 0))
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
	var comandos: Array = resultado.get("commands_used", [])
	var bucle_detectado: int = int(resultado.get("loop_count", 0))
	var iteraciones: int = int(resultado.get("loop_iterations", 0))

	var cumple_objetivo: bool = (
		bucle_detectado > 0
		and iteraciones >= 2
		and comandos.count("norte") >= 2
		and comandos.count("minar") >= 2
		and comandos.count("sur") >= 2
		and comandos.count("transferir") >= 2
	)

	if not cumple_objetivo:
		objetivo_actualizado.emit(
			objective_id,
			"El ciclo todavía está incompleto. " +
			"Debes repetir al menos dos veces la rutina " +
			"norte, minar, sur y transferir usando while."
		)
		return

	objective_completed = true
	estado_actual = EstadoMision.COMPLETADA

	if objective_id not in completed_missions:
		completed_missions.append(objective_id)

	mision_completada.emit(objective_id)
	print("Misión de ciclo de suministro completada.")
	iniciar_mision_comprar_casillas()

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
	var if_evaluations: int = int(resultado.get("if_evaluations", 0))
	var recolectados: int = int(resultado.get("minerals_collected", 0))
	var transferidos: int = int(resultado.get("minerals_transferred", 0))
	if if_evaluations < 1:
		objetivo_actualizado.emit(
			objective_id,
			"Debes usar la estructura 'if spid.hay_mineral():' para evaluar " +
			"la presencia de recursos antes de tomar una decisión."
		)
		return
	if recolectados < 1 or transferidos < 1:
		objetivo_actualizado.emit(
			objective_id,
			"Buen uso del sensor, pero debes localizar una casilla con mineral, " +
			"extraerlo con el condicional y transferirlo a la nave en la base."
		)
		return
	objective_completed = true
	estado_actual = EstadoMision.COMPLETADA
	if objective_id not in completed_missions:
		completed_missions.append(objective_id)
	desbloquear_conocimiento("condicional_if")
	mision_completada.emit(objective_id)
	print("Misión senales_inciertas completada!")
	iniciar_ciclo_autonomo()


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
		iniciar_exploracion_3x3()
		return
	estado_actual = EstadoMision.COMPRAR_MAPA_3X3
	mision_iniciada.emit(objective_id)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	print("Misión iniciada: comprar_mapa_3x3")


func registrar_compra_mapa_3x3() -> void:
	if "comprar_mapa_3x3" not in completed_missions:
		completed_missions.append("comprar_mapa_3x3")

	if objective_id == "comprar_mapa_3x3":
		objective_completed = true
		estado_actual = EstadoMision.COMPLETADA
		mision_completada.emit("comprar_mapa_3x3")
		iniciar_exploracion_3x3()
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
