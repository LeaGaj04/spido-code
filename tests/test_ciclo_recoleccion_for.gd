extends SceneTree
## Godot --headless --path . --script tests/test_ciclo_recoleccion_for.gd
## Executor y evaluador reales; minería, movimiento y transferencia simulados.

class AdaPrueba extends Node:
	var mensajes: Array = []
	func mostrar_mensaje(texto: String, tipo: String, _duracion: float) -> void:
		mensajes.append({"texto": texto, "tipo": tipo})

var executor: Node
var misiones: Node
var casos := 0
var fallos := 0
var carga := 0
var minados := 0
var comandos := 0
var limite_transferencia := 100
var fallar_comando := ""
var detener_tras := 0
var condicion_if := true
var pasos: Array = []


func _initialize() -> void:
	call_deferred("ejecutar_suite")


func ejecutar_suite() -> void:
	executor = root.get_node("CodeExecutor")
	misiones = root.get_node("MissionService")
	var pruebas := [
		{"nombre": "WHILE suficiente no demuestra FOR", "codigo": "while spid.tiene_espacio():\n    spid.minar()\nspid.transferir()", "completa": false, "for_iter": 0, "for_minerales": 0, "loop_minerales": 2},
		{"nombre": "FOR sin minería", "codigo": "for i in range(2):\n    spid.norte()\nspid.transferir()", "completa": false, "for_iter": 2, "for_minerales": 0},
		{"nombre": "minería anterior al FOR no cuenta", "codigo": "spid.minar()\nspid.minar()\nfor i in range(2):\n    spid.este()\nspid.transferir()", "completa": false, "for_iter": 2, "for_minerales": 0},
		{"nombre": "WHILE y FOR sin minería no se mezclan", "codigo": "while spid.tiene_espacio():\n    spid.minar()\nfor i in range(2):\n    spid.este()\nspid.transferir()", "completa": false, "for_iter": 2, "for_minerales": 0, "loop_minerales": 2},
		{"nombre": "FOR con un solo mineral", "codigo": "for i in range(1):\n    spid.minar()\nspid.transferir()", "completa": false, "for_iter": 1, "for_minerales": 1},
		{"nombre": "FOR necesita dos iteraciones", "codigo": "for i in range(1):\n    spid.minar()\n    spid.minar()\nspid.transferir()", "completa": false, "for_iter": 1, "for_minerales": 2},
		{"nombre": "transferencia insuficiente", "codigo": "for i in range(2):\n    spid.minar()\nspid.transferir()", "transferencia": 1, "completa": false, "for_iter": 2, "for_minerales": 2},
		{"nombre": "sin transferencia", "codigo": "for i in range(2):\n    spid.minar()", "completa": false, "for_iter": 2, "for_minerales": 2},
		{"nombre": "error después de cumplir cantidades", "codigo": "for i in range(2):\n    spid.minar()\nspid.transferir()\nspid.oeste()", "error": "oeste", "success": false, "completa": false, "for_iter": 2, "for_minerales": 2},
		{"nombre": "error antes de ejecutar FOR", "codigo": "spid.oeste()\nfor i in range(2):\n    spid.minar()\nspid.transferir()", "error": "oeste", "success": false, "completa": false, "for_iter": 0, "for_minerales": 0},
		{"nombre": "detención antes de cumplir", "codigo": "for i in range(2):\n    spid.minar()\nspid.transferir()", "detener": 1, "success": false, "completa": false, "for_iter": 1, "for_minerales": 1},
		{"nombre": "FOR recoge y transfiere fuera", "codigo": "for i in range(2):\n    spid.minar()\nspid.transferir()", "completa": true, "for_iter": 2, "for_minerales": 2, "loop_minerales": 2},
		{"nombre": "ruta alternativa y transferencia dentro", "codigo": "for i in range(3):\n    spid.este(2)\n    spid.minar()\n    spid.oeste(2)\n    spid.transferir()", "completa": true, "for_iter": 3, "for_minerales": 3},
		{"nombre": "range variable", "codigo": "n = 2\nfor i in range(n):\n    spid.minar()\nspid.transferir()", "completa": true, "for_iter": 2, "for_minerales": 2},
		{"nombre": "IF dentro de FOR conserva contexto", "codigo": "for i in range(2):\n    if spid.hay_mineral():\n        spid.minar()\nspid.transferir()", "completa": true, "for_iter": 2, "for_minerales": 2, "if_evaluations": 2, "loop_minerales": 2},
		{"nombre": "rama IF no ejecutada no recoge", "codigo": "for i in range(2):\n    if spid.hay_mineral():\n        spid.minar()\nspid.transferir()", "condicion": false, "completa": false, "for_iter": 2, "for_minerales": 0, "if_evaluations": 2},
		{"nombre": "FOR repetidos acumulan iteraciones sin duplicar comandos", "codigo": "for i in range(1):\n    spid.minar()\nfor j in range(1):\n    spid.minar()\nspid.transferir()", "completa": true, "for_iter": 2, "for_minerales": 2},
		{"nombre": "Paso a Paso", "codigo": "for i in range(2):\n    spid.minar()\nspid.transferir()", "paso": true, "completa": true, "for_iter": 2, "for_minerales": 2},
		{"nombre": "ejecución siguiente reinicia métricas", "codigo": "spid.norte()", "completa": false, "for_iter": 0, "for_minerales": 0, "loop_minerales": 0},
	]
	for prueba in pruebas:
		_preparar(prueba)
		if prueba.get("paso", false):
			executor.paso_esperando.connect(_avanzar)
		var resultado: Dictionary = await executor.ejecutar_codigo(prueba["codigo"], _comando, _condicion, prueba.get("paso", false))
		if prueba.get("paso", false):
			executor.paso_esperando.disconnect(_avanzar)
			_verificar(pasos == [2, 2, 3], prueba["nombre"] + ": líneas originales")
		_verificar(resultado.get("success", false) == prueba.get("success", true), prueba["nombre"] + ": ejecución")
		var completa: bool = "ciclo_recoleccion" in misiones.completed_missions
		_verificar(completa == prueba["completa"], prueba["nombre"] + ": evaluación")
		_verificar(resultado.get("objective_completed", false) == prueba["completa"], prueba["nombre"] + ": resultado de misión")
		_verificar(resultado.get("for_iterations", -1) == prueba["for_iter"], prueba["nombre"] + ": iteraciones reales FOR")
		_verificar(resultado.get("for_minerals_collected", -1) == prueba["for_minerales"], prueba["nombre"] + ": minerales FOR")
		if prueba.has("loop_minerales"):
			_verificar(resultado.get("loop_minerals_collected", -1) == prueba["loop_minerales"], prueba["nombre"] + ": contador previo conservado")
		if prueba.has("if_evaluations"):
			_verificar(resultado.get("if_evaluations", -1) == prueba["if_evaluations"], prueba["nombre"] + ": métrica IF conservada")
		if completa:
			_verificar(misiones.objective_id == "exploracion_3x3", prueba["nombre"] + ": transición")
		if prueba.has("error"):
			_verificar(not resultado.get("errors", []).is_empty(), prueba["nombre"] + ": error informado")
		print("CASO: ", prueba["nombre"])
	# La fixture evita guardado y compras al comprobar el mensaje real de la UI.
	var ui = load("res://tests/fixtures/interfaz_sin_guardado.gd").new()
	var ada := AdaPrueba.new()
	var estado := Label.new()
	ui.transmision_ada = ada
	ui.label_estado_mision = estado
	ui._on_mision_completada("ciclo_recoleccion")
	_verificar(ada.mensajes.size() == 1, "A.D.A. emite una felicitación")
	var texto: String = ada.mensajes[0]["texto"]
	_verificar("3x3" in texto and "2x3" not in texto, "A.D.A. usa el sector actual")
	_verificar("EXPLORACIÓN 3X3" in texto and "SEÑALES INCIERTAS" not in texto, "A.D.A. anuncia la transición correcta")
	var objetivo: String = ui._get_objetivo_panel("ciclo_recoleccion")
	_verificar("FOR" in objetivo and "2 minerales" in objetivo and "transfiere" in objetivo, "Panel explica FOR, recolección y transferencia")
	misiones.iniciar_ciclo_recoleccion()
	_verificar("spid.norte()" not in misiones.get_objetivo_actual(), "objetivo de A.D.A. no revela una ruta completa")
	ui.free()
	ada.free()
	estado.free()
	misiones.aplicar_progreso({})
	root.get_node("GestorSintaxis").aplicar_sintaxis_desbloqueada({})
	root.get_node("ProgressService").clear_progress()
	print("Ciclo Recolección FOR: %d PASS / %d FAIL (%d comprobaciones)." % [casos - fallos, fallos, casos])
	quit(1 if fallos > 0 else 0)


func _preparar(prueba: Dictionary) -> void:
	carga = 0
	minados = 0
	comandos = 0
	pasos.clear()
	limite_transferencia = prueba.get("transferencia", 100)
	fallar_comando = prueba.get("error", "")
	detener_tras = prueba.get("detener", 0)
	condicion_if = prueba.get("condicion", true)
	root.get_node("ProgressService").clear_progress()
	misiones.aplicar_progreso({})
	root.get_node("GestorSintaxis").aplicar_sintaxis_desbloqueada({"for": true, "in range": true, "while": true, "if": true, "else": true})
	misiones.iniciar_ciclo_recoleccion()


func _comando(comando: String, cantidad: int) -> Dictionary:
	comandos += 1
	if comando == fallar_comando:
		return {"ok": false, "error_type": "ejecucion", "message": "Error simulado de movimiento."}
	var recogidos := 0
	var transferidos := 0
	if comando == "minar":
		carga += 1
		minados += 1
		recogidos = 1
	if comando == "transferir":
		transferidos = mini(carga, limite_transferencia)
		carga -= transferidos
	if detener_tras > 0 and comandos >= detener_tras:
		executor.detener_ejecucion()
	return {"ok": true, "steps_completed": cantidad if comando in ["norte", "sur", "este", "oeste"] else 0, "minerals_collected": recogidos, "minerals_transferred": transferidos}


func _condicion(condicion: String) -> bool:
	return minados < 2 if condicion == "spid.tiene_espacio()" else condicion_if


func _avanzar(numero: int, _contenido: String) -> void:
	pasos.append(numero)
	executor.call_deferred("avanzar_un_paso")


func _verificar(condicion: bool, descripcion: String) -> void:
	casos += 1
	if not condicion:
		fallos += 1
		push_error("FALLÓ: " + descripcion)
