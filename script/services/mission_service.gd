extends Node

signal mision_iniciada(mision_id: String)
signal objetivo_actualizado(mision_id: String, objetivo: String)
signal mision_completada(mision_id: String)
signal conocimiento_desbloqueado(conocimiento_id: String)
signal veta_lineal_solicitada(indice: int)

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
	PATRULLA_AUTONOMA,
	COMPRAR_SECTOR_3X3,
	CALIBRACION_VARIABLES,
	COMPRAR_TELEMETRIA,
	TELEMETRIA_DINAMICA,
	COMPRAR_SECTOR_4X3,
	PATRULLA_LISTA,
}

var objective_id: String = "recolectar_primer_mineral"
var objective_completed: bool = false
var estado_actual: EstadoMision = EstadoMision.SIN_INICIAR

var completed_missions: Array = []
var unlocked_knowledge: Array = [
	"objeto",
	"metodo"
]
var vetas_lineales_completadas: int = 0


func _ready() -> void:
	iniciar_mision()


func iniciar_mision() -> void:
	objective_completed = false
	estado_actual = EstadoMision.BUSCAR_MINERAL

	mision_iniciada.emit(objective_id)

	objetivo_actualizado.emit(
		objective_id,
		"Muestra mineral detectada bajo el Spid. Mina el terreno y transfiere la carga a la nave."
	)
	
func iniciar_ruta_calibracion() -> void:
	objective_id = "ruta_calibracion"
	objective_completed = false
	estado_actual = EstadoMision.BUSCAR_MINERAL

	mision_iniciada.emit(objective_id)

	objetivo_actualizado.emit(
		objective_id,
		"RUTA DE CALIBRACIÓN\n" +
		"Yacimiento detectado al norte. Avanza hacia él, " +
		"mina el mineral, regresa a la nave y transfiere la carga."
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
		iniciar_patrulla_autonoma()
		return

	if objective_id == "patrulla_autonoma":
		iniciar_mision_comprar_sector_3x3()
		return

	if objective_id == "comprar_sector_3x3":
		iniciar_calibracion_variables()
		return

	if objective_id == "calibracion_variables":
		iniciar_mision_comprar_telemetria()
		return

	if objective_id == "comprar_telemetria":
		iniciar_telemetria_dinamica()
		return

	if objective_id == "telemetria_dinamica":
		iniciar_mision_comprar_sector_4x3()
		return

	if objective_id == "comprar_sector_4x3":
		iniciar_patrulla_lista()
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
		and (objective_completed or GestorSintaxis.esta_desbloqueada("for") or "comprar_mapa_3x3" in completed_missions)
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
		iniciar_patrulla_autonoma()
		return
	if objective_id == "ciclo_recoleccion":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.CICLO_RECOLECCION
		return

	if (
		(objective_id == "patrulla_autonoma" and objective_completed)
		or (objective_id == "patrulla_autonoma" and "patrulla_autonoma" in completed_missions)
	):
		iniciar_mision_comprar_sector_3x3()
		return
	if objective_id == "patrulla_autonoma":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.PATRULLA_AUTONOMA
		return

	if (
		(objective_id == "comprar_sector_3x3" and objective_completed)
		or (objective_id == "comprar_sector_3x3" and "comprar_sector_3x3" in completed_missions)
	):
		iniciar_calibracion_variables()
		return
	if objective_id == "comprar_sector_3x3":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.COMPRAR_SECTOR_3X3
		return

	if (
		(objective_id == "calibracion_variables" and objective_completed)
		or (objective_id == "calibracion_variables" and "calibracion_variables" in completed_missions)
	):
		iniciar_mision_comprar_telemetria()
		return
	if objective_id == "calibracion_variables":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.CALIBRACION_VARIABLES
		return

	if (
		(objective_id == "comprar_telemetria" and objective_completed)
		or (objective_id == "comprar_telemetria" and "comprar_telemetria" in completed_missions)
		or GestorSintaxis.esta_desbloqueada("tamano_mundo")
	):
		iniciar_telemetria_dinamica()
		return
	if objective_id == "comprar_telemetria":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.COMPRAR_TELEMETRIA
		return

	if (
		(objective_id == "telemetria_dinamica" and objective_completed)
		or (objective_id == "telemetria_dinamica" and "telemetria_dinamica" in completed_missions)
	):
		iniciar_mision_comprar_sector_4x3()
		return
	if objective_id == "telemetria_dinamica":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.TELEMETRIA_DINAMICA
		return

	if (
		(objective_id == "comprar_sector_4x3" and objective_completed)
		or (objective_id == "comprar_sector_4x3" and "comprar_sector_4x3" in completed_missions)
		or GestorSintaxis.esta_desbloqueada("listas")
	):
		iniciar_patrulla_lista()
		return
	if objective_id == "comprar_sector_4x3":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.COMPRAR_SECTOR_4X3
		return

	if (
		(objective_id == "patrulla_lista" and objective_completed)
		or (objective_id == "patrulla_lista" and "patrulla_lista" in completed_missions)
	):
		estado_actual = EstadoMision.COMPLETADA
		return
	if objective_id == "patrulla_lista":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.PATRULLA_LISTA
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
	if objective_id == "variables" and not objective_completed:
		estado_actual = EstadoMision.VARIABLES
		return
	if objective_id == "retorno_base" and not objective_completed:
		estado_actual = EstadoMision.RETORNO_BASE
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
			"CIRCUITO DE RECOLECCIÓN (BUCLE FOR)\n" +
			"Tres depósitos minerales activos en el Sector 2x3: Norte, Noreste y Este.\n\n" +
			"Usa 'for vuelta in range(3):' para repetir el circuito de recolección:\n" +
			"• Avanza y mina en cada depósito (norte, este, sur).\n" +
			"• Regresa al oeste a la nave nodriza al cerrar cada vuelta.\n" +
			"• Transfiere la carga a la nave al completar las 3 vueltas."
		)

	if objective_id == "patrulla_autonoma":
		return (
			"EL ROVER AUTÓNOMO (WHILE + FOR + IF)\n" +
			"Es momento de crear tu primer sistema desatendido. Enlaza tu circuito de patrulla " +
			"dentro de un bucle 'while True:' para operar continuamente.\n\n" +
			"Para evitar fallas en casillas vacías, verifica cada punto usando 'if spid.hay_mineral():' " +
			"antes de minar. Cada ronda de patrulla, Spid pasará por la base a transferir y continuará su labor."
		)

	if objective_id == "comprar_sector_3x3":
		return (
			"EXPANSIÓN SECTOR 3X3 Y VARIABLES\n" +
			"¡Rover autónomo verificado! Reúne 10 minerales en la nave y adquiere el [ SECTOR 3X3 ] " +
			"en el Centro de Mejoras para expandir el terreno a 3x3 y desbloquear las variables."
		)

	if objective_id == "calibracion_variables":
		return (
			"PARÁMETROS Y VARIABLES (SECTOR 3X3)\n" +
			"Las variables almacenan datos reutilizables y permiten parametrizar órdenes de movimiento:\n\n" +
			"vueltas = 2\n" +
			"pasos = 2\n\n" +
			"for i in range(vueltas):\n" +
			"    spid.norte(pasos)\n" +
			"    if spid.hay_mineral():\n" +
			"        spid.minar()\n" +
			"    spid.sur(pasos)\n\n" +
			"spid.transferir()\n\n" +
			"Tu desafío: parametriza la distancia y las repeticiones con variables para minar 2 minerales del depósito norte y transferirlos a la nave."
		)

	if objective_id == "comprar_telemetria":
		return (
			"EXPANSIÓN DE SENSORES (TELEMETRÍA DINÁMICA)\n" +
			"¡Calibración de variables completada! Reúne 10 minerales en la nave nodriza y adquiere " +
			"[ TELEMETRÍA DINÁMICA ] en el Centro de Mejoras para habilitar el sensor spid.tamano_mundo()."
		)

	if objective_id == "telemetria_dinamica":
		return (
			"TELEMETRÍA DINÁMICA DE SENSORES (tamano_mundo)\n" +
			"Obtén la dimensión del sector en tiempo real con 'spid.tamano_mundo()':\n\n" +
			"limite = spid.tamano_mundo()\n" +
			"vueltas = 3\n\n" +
			"while True:\n" +
			"    for i in range(vueltas):\n" +
			"        spid.norte(limite - 1)\n" +
			"        if spid.hay_mineral():\n" +
			"            spid.minar()\n" +
			"        spid.sur(limite - 1)\n" +
			"    spid.transferir()\n\n" +
			"Tu desafío: parametriza la distancia con 'limite - 1' y ejecuta la patrulla continua hasta transferir al menos 3 minerales a la nave."
		)

	if objective_id == "comprar_sector_4x3":
		return (
			"EXPANSIÓN SECTOR 4X3 Y LISTAS\n" +
			"¡Telemetría dinámica dominada! Reúne 15 minerales en la nave nodriza y adquiere " +
			"[ SECTOR 4X3 ] en el Centro de Mejoras para expandir a 4 de ancho y desbloquear listas."
		)

	if objective_id == "patrulla_lista":
		return (
			"PATRULLA CON LISTAS (SECTOR 4X3)\n" +
			"Las listas agrupan colecciones de datos que puedes recorrer con un bucle 'for':\n\n" +
			"ruta = [\"norte\", \"norte\", \"este\", \"sur\", \"este\", \"sur\", \"oeste\", \"oeste\"]\n\n" +
			"while True:\n" +
			"    for direccion in ruta:\n" +
			"        spid.mover(direccion)\n" +
			"        if spid.hay_mineral():\n" +
			"            spid.minar()\n" +
			"    spid.transferir()\n\n" +
			"Tu desafío: define tu circuito en una lista y patrulla hasta transferir al menos 3 minerales a la nave."
		)

	if objective_id == "ruta_calibracion":
		return (
			"Yacimiento detectado al norte. Avanza hacia él, " +
			"mina el mineral, regresa al sur a la nave y transfiere la muestra en una sola rutina."
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
			"ACTUALIZACIÓN DE FIRMWARE (CICLO FOR)\n" +
			"Reúne 20 minerales en la nave y adquiere el [ CICLO FOR ] " +
			"en el Centro de Mejoras para instalar el módulo BUCLE FOR en la consola."
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
				"¡Ya tienes los 20 minerales necesarios! Ve al menú MEJORAS y adquiere el [ CICLO FOR ] para continuar."
			)
		else:
			objetivo_actualizado.emit(
				objective_id,
				"Tienes %d de 20 minerales en la nave. Sigue recolectando y luego adquiere el [ CICLO FOR ] en MEJORAS." % minerales_nave
			)
		return

	if objective_id == "comprar_sector_3x3":
		var minerales_nave: int = _obtener_minerales_nave()
		if minerales_nave >= 10:
			objetivo_actualizado.emit(
				objective_id,
				"¡Ya tienes los 10 minerales necesarios! Ve al menú MEJORAS y adquiere el [ SECTOR 3X3 ] para continuar."
			)
		else:
			objetivo_actualizado.emit(
				objective_id,
				"Tienes %d de 10 minerales en la nave. Sigue recolectando y luego adquiere el [ SECTOR 3X3 ] en MEJORAS." % minerales_nave
			)
		return

	if objective_id == "comprar_telemetria":
		var minerales_nave: int = _obtener_minerales_nave()
		if minerales_nave >= 10:
			objetivo_actualizado.emit(
				objective_id,
				"¡Ya tienes los 10 minerales necesarios! Ve al menú MEJORAS y adquiere [ TELEMETRÍA DINÁMICA ] para continuar."
			)
		else:
			objetivo_actualizado.emit(
				objective_id,
				"Tienes %d de 10 minerales en la nave. Sigue recolectando y luego adquiere [ TELEMETRÍA DINÁMICA ] en MEJORAS." % minerales_nave
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

	if objective_id == "patrulla_autonoma":
		_evaluar_patrulla_autonoma(resultado)
		return

	if objective_id == "calibracion_variables":
		_evaluar_calibracion_variables(resultado)
		return

	if objective_id == "telemetria_dinamica":
		_evaluar_telemetria_dinamica(resultado)
		return

	if objective_id == "comprar_sector_4x3":
		var minerales_nave: int = _obtener_minerales_nave()
		if minerales_nave >= 15:
			objetivo_actualizado.emit(
				objective_id,
				"¡Ya tienes los 15 minerales necesarios! Ve al menú MEJORAS y adquiere [ SECTOR 4X3 ] para continuar."
			)
		else:
			objetivo_actualizado.emit(
				objective_id,
				"Tienes %d de 15 minerales en la nave. Sigue recolectando y luego adquiere [ SECTOR 4X3 ] en MEJORAS." % minerales_nave
			)
		return

	if objective_id == "patrulla_lista":
		_evaluar_patrulla_lista(resultado)
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
	var codigo: String = str(resultado.get("code", "")).to_lower().replace(" ", "")
	var comandos: Array = resultado.get("commands_used", [])
	var recolectados: int = int(resultado.get("minerals_collected", 0))
	var transferidos: int = int(resultado.get("minerals_transferred", 0))
	var iteraciones: int = int(resultado.get("loop_iterations", 0))

	# 1. Prohibir while en esta misión
	if codigo.contains("while"):
		objetivo_actualizado.emit(
			objective_id,
			"Has usado un bucle 'while'. Para recorrer el circuito un número exacto de vueltas, debes utilizar 'for <variable> in range(N):'."
		)
		return

	# 2. Exigir for e in range
	if not (codigo.contains("for") and (codigo.contains("inrange") or codigo.contains("range("))):
		objetivo_actualizado.emit(
			objective_id,
			"Debes usar la estructura 'for <variable> in range(3):' para automatizar las vueltas del circuito de recolección."
		)
		return

	# 3. Verificar que haya recolectado y transferido al menos una vuelta completa (3 minerales)
	if recolectados < 3 or transferidos < 3:
		objetivo_actualizado.emit(
			objective_id,
			"Programa terminado. Recolectaste %d minerales y transferiste %d. " % [recolectados, transferidos] +
			"El circuito contiene 3 depósitos. Completa la ronda usando 'for' y transfiere a la nave."
		)
		return

	# Al completar la recolección con for
	objective_completed = true
	estado_actual = EstadoMision.COMPLETADA

	if objective_id not in completed_missions:
		completed_missions.append(objective_id)

	mision_completada.emit(objective_id)
	print("¡Misión ciclo_recoleccion completada con éxito usando bucle for en sector 2x3!")
	iniciar_patrulla_autonoma()


func iniciar_patrulla_autonoma() -> void:
	objective_id = "patrulla_autonoma"
	objective_completed = "patrulla_autonoma" in completed_missions
	estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.PATRULLA_AUTONOMA
	mision_iniciada.emit(objective_id)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	veta_lineal_solicitada.emit(1)
	print("Misión iniciada: patrulla_autonoma")


func _evaluar_patrulla_autonoma(resultado: Dictionary, informar_pendientes: bool = true) -> void:
	var codigo: String = str(resultado.get("code", "")).to_lower().replace(" ", "")
	var recolectados: int = int(resultado.get("minerals_collected", 0))
	var transferidos: int = int(resultado.get("minerals_transferred", 0))
	var if_evaluations: int = int(resultado.get("if_evaluations", 0))

	# 1. Requiere bucle while para operación continua
	if not codigo.contains("while"):
		if not informar_pendientes:
			return
		objetivo_actualizado.emit(
			objective_id,
			"Para una operación desatendida y continua, debes envolver la rutina en un bucle 'while True:'."
		)
		return

	# 2. Requiere bucle for in range dentro de la rutina
	if not (codigo.contains("for") and (codigo.contains("inrange") or codigo.contains("range("))):
		if not informar_pendientes:
			return
		objetivo_actualizado.emit(
			objective_id,
			"Debes organizar las vueltas de la patrulla utilizando un bucle 'for i in range(2):' dentro del 'while'."
		)
		return

	# 3. Requiere sensor condicional if spid.hay_mineral():
	if not codigo.contains("if") or (not codigo.contains("hay_mineral") and if_evaluations == 0):
		if not informar_pendientes:
			return
		objetivo_actualizado.emit(
			objective_id,
			"Para evitar errores en casillas vacías, debes consultar 'if spid.hay_mineral():' antes de ejecutar 'spid.minar()'."
		)
		return

	# 4. Requiere haber recolectado y transferido minerales de forma autónoma
	if recolectados < 2 or transferidos < 2:
		if not informar_pendientes:
			return
		objetivo_actualizado.emit(
			objective_id,
			"Spid ejecutó la patrulla pero debe recolectar y transferir al menos 2 minerales a la nave para validar el ciclo autónomo."
		)
		return

	objective_completed = true
	estado_actual = EstadoMision.COMPLETADA

	if objective_id not in completed_missions:
		completed_missions.append(objective_id)

	mision_completada.emit(objective_id)
	print("¡Misión patrulla_autonoma completada con éxito!")
	CodeExecutor.call_deferred("detener_ejecucion")


func iniciar_mision_comprar_sector_3x3() -> void:
	objective_id = "comprar_sector_3x3"
	var map_tier: int = int(ProgressService.get_current_progress().get("map_tier", 0))
	objective_completed = "comprar_sector_3x3" in completed_missions or map_tier >= 3
	if objective_completed:
		iniciar_calibracion_variables()
		return
	estado_actual = EstadoMision.COMPRAR_SECTOR_3X3
	mision_iniciada.emit(objective_id)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	print("Misión iniciada: comprar_sector_3x3")


func registrar_compra_sector_3x3() -> void:
	if "comprar_sector_3x3" not in completed_missions:
		completed_missions.append("comprar_sector_3x3")
	objective_completed = true
	estado_actual = EstadoMision.COMPLETADA
	desbloquear_conocimiento("variable")
	desbloquear_conocimiento("parametro")
	mision_completada.emit("comprar_sector_3x3")
	iniciar_calibracion_variables()


func iniciar_calibracion_variables() -> void:
	objective_id = "calibracion_variables"
	objective_completed = "calibracion_variables" in completed_missions
	estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.CALIBRACION_VARIABLES
	mision_iniciada.emit(objective_id)
	veta_lineal_solicitada.emit(0)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	print("Misión iniciada: calibracion_variables")


func _evaluar_calibracion_variables(resultado: Dictionary) -> void:
	var variables_definidas: Array = resultado.get("variables_defined", [])
	var variables_usadas: Array = resultado.get("variables_used", [])
	var recolectados: int = int(resultado.get("minerals_collected", 0))
	var transferidos: int = int(resultado.get("minerals_transferred", 0))
	var codigo: String = str(resultado.get("code", "")).to_lower().replace(" ", "")

	# 1. Definición de variables (ej. vueltas = 2, pasos = 2)
	if variables_definidas.is_empty():
		objetivo_actualizado.emit(
			objective_id,
			"Para completar esta misión debes definir variables (ej. 'vueltas = 2' y 'pasos = 2') antes de usarlas."
		)
		return

	# 2. Uso de variables en parámetros de movimiento o en range()
	if variables_usadas.is_empty() and not (codigo.contains("range(") and not codigo.contains("range(1") and not codigo.contains("range(2")):
		objetivo_actualizado.emit(
			objective_id,
			"Definiste variables, pero debes utilizarlas como argumentos en los comandos (ej. 'spid.norte(pasos)') o en 'range(vueltas)'."
		)
		return

	# 3. Parametrización en movimiento
	if not (codigo.contains("norte(") or codigo.contains("sur(")):
		objetivo_actualizado.emit(
			objective_id,
			"Aprovecha los parámetros de distancia en las órdenes de movimiento: 'spid.norte(pasos)' y 'spid.sur(pasos)'."
		)
		return

	# 4. Requiere recolectar y transferir al menos 2 minerales
	if recolectados < 2 or transferidos < 2:
		objetivo_actualizado.emit(
			objective_id,
			"Buen avance con las variables, pero debes completar 2 vueltas de recolección y transferir ambos minerales a la nave."
		)
		return

	objective_completed = true
	estado_actual = EstadoMision.COMPLETADA

	if objective_id not in completed_missions:
		completed_missions.append(objective_id)

	desbloquear_conocimiento("variable")
	desbloquear_conocimiento("parametro")
	mision_completada.emit(objective_id)
	print("¡Misión calibracion_variables completada con éxito!")
	iniciar_mision_comprar_telemetria()


func iniciar_mision_comprar_telemetria() -> void:
	objective_id = "comprar_telemetria"
	objective_completed = "comprar_telemetria" in completed_missions or GestorSintaxis.esta_desbloqueada("tamano_mundo")
	if objective_completed:
		iniciar_telemetria_dinamica()
		return
	estado_actual = EstadoMision.COMPRAR_TELEMETRIA
	mision_iniciada.emit(objective_id)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	print("Misión iniciada: comprar_telemetria")


func registrar_compra_telemetria() -> void:
	if "comprar_telemetria" not in completed_missions:
		completed_missions.append("comprar_telemetria")
	GestorSintaxis.desbloquear_sintaxis("tamano_mundo")
	desbloquear_conocimiento("telemetria")
	objective_completed = true
	estado_actual = EstadoMision.COMPLETADA
	mision_completada.emit("comprar_telemetria")
	iniciar_telemetria_dinamica()


func iniciar_telemetria_dinamica() -> void:
	objective_id = "telemetria_dinamica"
	objective_completed = "telemetria_dinamica" in completed_missions
	estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.TELEMETRIA_DINAMICA
	mision_iniciada.emit(objective_id)
	veta_lineal_solicitada.emit(0)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	print("Misión iniciada: telemetria_dinamica (Fase 5.5)")


func _evaluar_telemetria_dinamica(resultado: Dictionary, informar_pendientes: bool = true) -> void:
	var codigo: String = str(resultado.get("code", "")).to_lower().replace(" ", "")
	var variables_usadas: Array = resultado.get("variables_used", [])
	var recolectados: int = int(resultado.get("minerals_collected", 0))
	var transferidos: int = int(resultado.get("minerals_transferred", 0))
	var if_evaluations: int = int(resultado.get("if_evaluations", 0))

	# 1. Requiere uso de telemetría tamano_mundo()
	if not (codigo.contains("tamano_mundo()") or "spid.tamano_mundo()" in variables_usadas):
		if not informar_pendientes:
			return
		objetivo_actualizado.emit(
			objective_id,
			"Debes consultar la dimensión del sector asignando 'limite = spid.tamano_mundo()' a una variable."
		)
		return

	# 2. Requiere bucle while y bucle for
	if not codigo.contains("while"):
		if not informar_pendientes:
			return
		objetivo_actualizado.emit(
			objective_id,
			"Para una operación de recolección continua, envuelve el circuito en 'while True:'."
		)
		return

	if not (codigo.contains("for") and (codigo.contains("inrange") or codigo.contains("range("))):
		if not informar_pendientes:
			return
		objetivo_actualizado.emit(
			objective_id,
			"Usa 'for i in range(vueltas):' para organizar las vueltas de minado."
		)
		return

	# 3. Requiere sensor condicional if spid.hay_mineral():
	if not codigo.contains("if") or (not codigo.contains("hay_mineral") and if_evaluations == 0):
		if not informar_pendientes:
			return
		objetivo_actualizado.emit(
			objective_id,
			"Verifica cada casilla con 'if spid.hay_mineral():' antes de minar."
		)
		return

	# 4. Requiere transferir al menos 3 minerales a la nave
	if recolectados < 3 or transferidos < 3:
		if not informar_pendientes:
			return
		objetivo_actualizado.emit(
			objective_id,
			"Spid ejecutó la rutina pero debe extraer y transferir al menos 3 minerales a la nave para validar la telemetría dinámica."
		)
		return

	objective_completed = true
	estado_actual = EstadoMision.COMPLETADA

	if objective_id not in completed_missions:
		completed_missions.append(objective_id)

	desbloquear_conocimiento("telemetria")
	mision_completada.emit(objective_id)
	print("¡Misión telemetria_dinamica completada con éxito!")
	CodeExecutor.call_deferred("detener_ejecucion")
	iniciar_mision_comprar_sector_4x3()


func iniciar_mision_comprar_sector_4x3() -> void:
	objective_id = "comprar_sector_4x3"
	var map_tier: int = int(ProgressService.get_current_progress().get("map_tier", 0))
	objective_completed = "comprar_sector_4x3" in completed_missions or map_tier >= 4 or GestorSintaxis.esta_desbloqueada("listas")
	if objective_completed:
		iniciar_patrulla_lista()
		return
	estado_actual = EstadoMision.COMPRAR_SECTOR_4X3
	mision_iniciada.emit(objective_id)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	print("Misión iniciada: comprar_sector_4x3")


func registrar_compra_sector_4x3() -> void:
	if "comprar_sector_4x3" not in completed_missions:
		completed_missions.append("comprar_sector_4x3")
	GestorSintaxis.desbloquear_sintaxis("listas")
	desbloquear_conocimiento("lista")
	objective_completed = true
	estado_actual = EstadoMision.COMPLETADA
	mision_completada.emit("comprar_sector_4x3")
	iniciar_patrulla_lista()


func iniciar_patrulla_lista() -> void:
	objective_id = "patrulla_lista"
	objective_completed = "patrulla_lista" in completed_missions
	estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.PATRULLA_LISTA
	mision_iniciada.emit(objective_id)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	print("Misión iniciada: patrulla_lista (Fase 6)")


func _evaluar_patrulla_lista(resultado: Dictionary, informar_pendientes: bool = true) -> void:
	var codigo: String = str(resultado.get("code", "")).to_lower().replace(" ", "")
	var comandos_usados: Array = resultado.get("commands_used", [])
	var recolectados: int = int(resultado.get("minerals_collected", 0))
	var transferidos: int = int(resultado.get("minerals_transferred", 0))
	var if_evaluations: int = int(resultado.get("if_evaluations", 0))

	# 1. Requiere sintaxis de lista [...]
	if not ("[" in codigo and "]" in codigo):
		if not informar_pendientes:
			return
		objetivo_actualizado.emit(
			objective_id,
			"Para esta misión debes definir una lista de ruta (ej. 'ruta = [\"norte\", \"este\", ...]') con corchetes []."
		)
		return

	# 2. Requiere bucle for recorriendo la lista
	if not (codigo.contains("for") and (codigo.contains("in") or codigo.contains("inrange"))):
		if not informar_pendientes:
			return
		objetivo_actualizado.emit(
			objective_id,
			"Recorre tu lista usando la estructura 'for direccion in ruta:'."
		)
		return

	# 3. Requiere uso de spid.mover()
	if not (codigo.contains("mover(") or "mover" in comandos_usados):
		if not informar_pendientes:
			return
		objetivo_actualizado.emit(
			objective_id,
			"Utiliza 'spid.mover(direccion)' dentro de tu bucle para ejecutar los pasos de la lista."
		)
		return

	# 4. Requiere sensor condicional if spid.hay_mineral():
	if not codigo.contains("if") or (not codigo.contains("hay_mineral") and if_evaluations == 0):
		if not informar_pendientes:
			return
		objetivo_actualizado.emit(
			objective_id,
			"Para minar solo en casillas ocupadas, evalúa 'if spid.hay_mineral():' antes de minar."
		)
		return

	# 5. Requiere recolectar y transferir al menos 3 minerales
	if recolectados < 3 or transferidos < 3:
		if not informar_pendientes:
			return
		objetivo_actualizado.emit(
			objective_id,
			"Spid recorrió el sector pero debe extraer y transferir al menos 3 minerales a la nave nodriza."
		)
		return

	objective_completed = true
	estado_actual = EstadoMision.COMPLETADA

	if objective_id not in completed_missions:
		completed_missions.append(objective_id)

	desbloquear_conocimiento("lista")
	mision_completada.emit(objective_id)
	print("¡Misión patrulla_lista completada con éxito!")
	CodeExecutor.call_deferred("detener_ejecucion")

	
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
	vetas_lineales_completadas = 0

	desbloquear_modulo_for()
	mision_iniciada.emit(objective_id)
	veta_lineal_solicitada.emit(0)
	objetivo_actualizado.emit(objective_id, get_objetivo_actual())
	print("Misión iniciada: ciclo_recoleccion con vetas lineales")

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


func evaluar_progreso_programa(resultado: Dictionary) -> void:
	# El resultado parcial no tiene success=true hasta finalizar el programa.
	if objective_completed:
		return
	if resultado.get("objective_id", "") != objective_id or not resultado.get("errors", []).is_empty():
		return
	if objective_id == "senales_inciertas":
		_evaluar_senales_inciertas(resultado, false)
	elif objective_id == "patrulla_autonoma":
		_evaluar_patrulla_autonoma(resultado, false)
	elif objective_id == "telemetria_dinamica":
		_evaluar_telemetria_dinamica(resultado, false)
	elif objective_id == "patrulla_lista":
		_evaluar_patrulla_lista(resultado, false)


func _evaluar_senales_inciertas(resultado: Dictionary, informar_pendientes: bool = true) -> void:
	var codigo: String = str(resultado.get("code", "")).to_lower().replace(" ", "")
	var if_evaluations: int = int(resultado.get("if_evaluations", 0))
	var recolectados: int = int(resultado.get("minerals_collected", 0))
	var transferidos: int = int(resultado.get("minerals_transferred", 0))

	if if_evaluations < 1:
		if not informar_pendientes:
			return
		objetivo_actualizado.emit(
			objective_id,
			"Debes usar la estructura condicional 'if spid.hay_mineral():' para censar " +
			"la casilla antes de intentar minar."
		)
		return

	var usa_else: bool = codigo.contains("else:")
	var usa_bucle_patrulla: bool = codigo.contains("while") and if_evaluations >= 2

	if not usa_else and not usa_bucle_patrulla:
		if not informar_pendientes:
			return
		objetivo_actualizado.emit(
			objective_id,
			"El sensor funcionó, pero debes aplicar una estrategia completa:\n" +
			"1) Un plan de contingencia con 'else:' (si no hay mineral, buscar en otra casilla).\n" +
			"2) O una patrulla continua con 'while' censando cada casilla con 'if'."
		)
		return

	if recolectados < 1 or transferidos < 1:
		if not informar_pendientes:
			return
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
	objective_id = "comprar_mapa_3x3"
	objective_completed = "comprar_mapa_3x3" in completed_missions or GestorSintaxis.esta_desbloqueada("for")
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
