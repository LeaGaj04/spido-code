extends SceneTree
## Ejecutar con Godot --headless --path . --script tests/test_parametros_variables.gd

var executor: Node
var misiones: Node
var casos := 0
var fallos := 0
var comandos_ejecutados: Array = []


func _initialize() -> void:
	call_deferred("ejecutar_suite")


func ejecutar_suite() -> void:
	executor = root.get_node("CodeExecutor")
	misiones = root.get_node("MissionService")
	root.get_node("GestorSintaxis").aplicar_sintaxis_desbloqueada({
		"for": true,
		"while": true,
		"if": true,
		"else": true,
		"in range": true,
	})
	root.get_node("ProgressService").clear_progress()

	for comando in ["norte", "sur", "este", "oeste"]:
		var resultado: Dictionary = await _ejecutar("spid.%s(2)" % comando)
		_verificar(resultado.get("success", false), "spid.%s(2) se ejecuta" % comando)
		_verificar(comandos_ejecutados.back() == {"command": comando, "steps": 2}, "%s recibe dos pasos" % comando)

	for codigo in ["spid.norte(0)", "spid.norte(-1)", "spid.norte(pasos)", "spid.minar(2)", "spid.transferir(2)"]:
		var resultado: Dictionary = await _ejecutar(codigo)
		_verificar(not resultado.get("success", false), "%s se rechaza" % codigo)
		_verificar(not resultado.get("errors", []).is_empty(), "%s informa el error" % codigo)

	var asignacion_y_uso: Dictionary = await _ejecutar("pasos = 2\nspid.norte(pasos)")
	_verificar(asignacion_y_uso.get("success", false), "variable numérica usada como parámetro")
	_verificar(asignacion_y_uso.get("variables_defined", []) == ["pasos"], "asignación registra variables_defined")
	_verificar(asignacion_y_uso.get("variables_used", []) == ["pasos"], "parámetro registra variables_used")
	_verificar(comandos_ejecutados.back() == {"command": "norte", "steps": 2}, "parámetro usa el valor de la variable")

	var copia_y_uso: Dictionary = await _ejecutar("a = 2\nb = a\nspid.norte(b)")
	_verificar(copia_y_uso.get("success", false), "copia de variable usada como parámetro")
	_verificar(copia_y_uso.get("variables_defined", []) == ["a", "b"], "ambas asignaciones quedan registradas")
	_verificar(copia_y_uso.get("variables_used", []) == ["a", "b"], "copia y parámetro quedan registrados como uso")
	_verificar(comandos_ejecutados.back() == {"command": "norte", "steps": 2}, "parámetro copiado conserva el valor")

	for codigo in ["spid.norte(pasos)", "pasos = 0\nspid.norte(pasos)", "pasos = -1\nspid.norte(pasos)"]:
		var resultado: Dictionary = await _ejecutar(codigo)
		_verificar(not resultado.get("success", false), "%s se rechaza" % codigo)
		_verificar(not resultado.get("errors", []).is_empty(), "%s informa el error" % codigo)

	_preparar_mision("camino_largo")
	misiones.evaluar_programa(_resultado_mision([{"steps": 2}], 1, 1))
	_verificar("camino_largo" in misiones.completed_missions, "Camino Largo registra completado con parámetro >1 y mineral recogido y transferido")
	_verificar(misiones.objective_id == "variables", "completar Camino Largo transiciona a Variables")

	_preparar_mision("camino_largo")
	misiones.evaluar_programa(_resultado_mision([{"steps": 1}], 1, 1))
	_verificar(not misiones.objective_completed, "Camino Largo no completa con parámetro =1")

	_preparar_mision("camino_largo")
	misiones.evaluar_programa(_resultado_mision([{"steps": 2}], 0, 0))
	_verificar(not misiones.objective_completed, "Camino Largo no completa sin recoger y transferir")

	_preparar_mision("camino_largo")
	misiones.evaluar_programa(_resultado_mision([{"steps": 1}], 1, 1))
	_verificar(not misiones.objective_completed, "Camino Largo no completa con minerales pero sin parámetro >1")

	_preparar_mision("variables")
	var variables_completa := _resultado_mision([{"steps": 2}], 1, 1)
	variables_completa["variables_defined"] = ["pasos"]
	variables_completa["variables_used"] = ["pasos"]
	misiones.evaluar_programa(variables_completa)
	_verificar(misiones.objective_completed, "Variables completa con definición, uso, recolección y transferencia")

	_preparar_mision("variables")
	var sin_uso := _resultado_mision([{"steps": 2}], 1, 1)
	sin_uso["variables_defined"] = ["pasos"]
	misiones.evaluar_programa(sin_uso)
	_verificar(not misiones.objective_completed, "Variables no completa si no se usa la variable")

	_preparar_mision("variables")
	var solo_copia := _resultado_mision([], 0, 0)
	solo_copia["variables_defined"] = ["a", "b"]
	solo_copia["variables_used"] = ["a"]
	misiones.evaluar_programa(solo_copia)
	_verificar(not misiones.objective_completed, "copiar una variable sin recoger y transferir no completa Variables")
	var copia_como_uso := _resultado_mision([], 1, 1)
	copia_como_uso["variables_defined"] = ["a", "b"]
	copia_como_uso["variables_used"] = ["a"]
	misiones.evaluar_programa(copia_como_uso)
	_verificar(misiones.objective_completed, "LIMITACIÓN: una copia cuenta como uso aunque no controle un movimiento")

	_preparar_mision("variables")
	var sin_minerales := _resultado_mision([], 0, 0)
	sin_minerales["variables_defined"] = ["pasos"]
	sin_minerales["variables_used"] = ["pasos"]
	misiones.evaluar_programa(sin_minerales)
	_verificar(not misiones.objective_completed, "Variables no completa sin recoger y transferir")

	var range_literal: Dictionary = executor.compilar_programa("for i in range(2):\n    spid.norte()")
	_verificar(range_literal.get("ok", false), "range literal compila")
	_verificar(range_literal.get("instrucciones", []).size() == 2, "range literal expande el cuerpo dos veces")

	var range_variable_grande: Dictionary = executor.compilar_programa("pasos = 51\nfor i in range(pasos):\n    spid.norte()")
	_verificar(range_variable_grande.get("ok", false), "LIMITACIÓN: range(variable) mayor a 50 se acepta actualmente")
	_verificar(range_variable_grande.get("instrucciones", []).size() == 52, "LIMITACIÓN: range(51) expande 51 comandos sin revalidar el límite")

	var range_variable_inexistente: Dictionary = executor.compilar_programa("for i in range(pasos):\n    spid.norte()")
	_verificar(range_variable_inexistente.get("ok", false), "LIMITACIÓN: range(variable) inexistente se acepta actualmente")
	_verificar(range_variable_inexistente.get("instrucciones", []).size() == 1, "LIMITACIÓN: variable inexistente en range se interpreta como una repetición")

	root.get_node("ProgressService").clear_progress()
	misiones.completed_missions.clear()
	misiones.unlocked_knowledge = ["objeto", "metodo"]
	if fallos > 0:
		push_error("Suite parámetros y variables: %d de %d comprobaciones fallaron." % [fallos, casos])
		quit(1)
		return
	print("OK: %d comprobaciones de parámetros, variables, Camino Largo y caracterización de range(variable)." % casos)
	quit(0)


func _ejecutar(codigo: String) -> Dictionary:
	comandos_ejecutados.clear()
	return await executor.ejecutar_codigo(codigo, _ejecutar_comando)


func _ejecutar_comando(comando: String, pasos: int) -> Dictionary:
	comandos_ejecutados.append({"command": comando, "steps": pasos})
	return {
		"ok": true,
		"steps_completed": pasos if comando in ["norte", "sur", "este", "oeste"] else 0,
		"minerals_collected": 1 if comando == "minar" else 0,
		"minerals_transferred": 1 if comando == "transferir" else 0,
	}


func _preparar_mision(id: String) -> void:
	misiones.completed_missions.clear()
	misiones.unlocked_knowledge = ["objeto", "metodo"]
	misiones.objective_id = id
	misiones.objective_completed = false
	misiones.estado_actual = misiones.EstadoMision.CAMINO_LARGO if id == "camino_largo" else misiones.EstadoMision.VARIABLES


func _resultado_mision(comandos_data: Array, recogidos: int, transferidos: int) -> Dictionary:
	return {
		"success": true,
		"code": "",
		"commands_data": comandos_data,
		"minerals_collected": recogidos,
		"minerals_transferred": transferidos,
		"variables_defined": [],
		"variables_used": [],
	}


func _verificar(condicion: bool, descripcion: String) -> void:
	casos += 1
	if condicion:
		return
	fallos += 1
	push_error("FALLÓ: " + descripcion)
