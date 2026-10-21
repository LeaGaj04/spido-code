extends SceneTree
## Ejecutar con Godot --headless --path . --script tests/test_parametros_variables.gd

var executor: Node
var misiones: Node
var casos := 0
var fallos := 0
var comandos_ejecutados: Array = []
var errores_emitidos: Array = []
var pasos_esperados: Array = []


func _initialize() -> void:
	call_deferred("ejecutar_suite")


func ejecutar_suite() -> void:
	executor = root.get_node("CodeExecutor")
	misiones = root.get_node("MissionService")
	executor.error_detectado.connect(_registrar_error)
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

	# Literales y variables comparten límites y mensajes, antes de ejecutar comandos.
	for n in [0, -1, 51]:
		var literal: Dictionary = executor.compilar_programa("for i in range(%d):\n    spid.norte()" % n)
		var variable: Dictionary = executor.compilar_programa("n = %d\nfor i in range(n):\n    spid.norte()" % n)
		_verificar(not literal.get("ok", false), "literal inválido %d se rechaza" % n)
		_verificar(not variable.get("ok", false), "variable inválida %d se rechaza" % n)
		if not variable.get("ok", false) and not literal.get("ok", false):
			_verificar(variable["error"]["message"] == literal["error"]["message"], "literal y variable %d comparten mensaje" % n)
			_verificar(variable["error"]["line"] == 2, "error de range se asocia a la línea del for")

	var inexistente: Dictionary = await _ejecutar("for i in range(no_existe):\n    spid.norte()")
	_verificar(not inexistente.get("success", false), "range rechaza variable inexistente")
	_verificar(comandos_ejecutados.is_empty(), "range inexistente no ejecuta comandos")
	_verificar(not inexistente.get("errors", []).is_empty(), "range inexistente informa error normal")
	_verificar(errores_emitidos == inexistente.get("errors", []), "error_detectado conserva el error y línea usados por la interfaz")
	if not inexistente.get("errors", []).is_empty():
		_verificar(inexistente["errors"][0]["line"] == 1, "variable inexistente informa la línea del for")
		_verificar("no_existe" in inexistente["errors"][0]["message"], "error identifica la variable inexistente")

	for n in [1, 2, 50]:
		var literal: Dictionary = await _ejecutar("for i in range(%d):\n    spid.norte()" % n)
		_verificar(literal.get("success", false) and comandos_ejecutados.size() == n, "literal %d conserva sus repeticiones" % n)
		var variable: Dictionary = await _ejecutar("n = %d\nfor i in range(n):\n    spid.norte()" % n)
		_verificar(variable.get("success", false) and comandos_ejecutados.size() == n, "variable %d ejecuta las repeticiones esperadas" % n)
		_verificar(variable.get("loop_count", 0) == literal.get("loop_count", 0), "literal y variable conservan loop_count")
		_verificar(variable.get("loop_iterations", 0) == n, "variable conserva loop_iterations")

	var copia_range: Dictionary = await _ejecutar("a = 3\nb = a\nfor i in range(b):\n    spid.norte()")
	_verificar(copia_range.get("success", false) and comandos_ejecutados.size() == 3, "range resuelve copia de variable")
	_verificar(copia_range.get("variables_defined", []) == ["a", "b"], "range conserva las definiciones")
	_verificar(copia_range.get("variables_used", []) == ["a"], "range conserva la métrica de uso actual, sin contar b")

	# La expansión conserva líneas originales y el modo Paso a Paso.
	comandos_ejecutados.clear()
	executor.paso_esperando.connect(_avanzar_paso)
	var por_pasos: Dictionary = await executor.ejecutar_codigo("n = 2\nfor i in range(n):\n    spid.norte()", _ejecutar_comando, Callable(), true)
	executor.paso_esperando.disconnect(_avanzar_paso)
	_verificar(por_pasos.get("success", false) and comandos_ejecutados.size() == 2, "range(variable) funciona Paso a Paso")
	_verificar(pasos_esperados == [1, 3, 3], "Paso a Paso conserva líneas originales para resaltado")

	comandos_ejecutados.clear()
	var limite_while: Dictionary = await executor.ejecutar_codigo("while True:\n    spid.norte()", _ejecutar_comando, _siempre_verdadero)
	_verificar(not limite_while.get("success", false), "while infinito sigue rechazándose por seguridad")
	_verificar(comandos_ejecutados.size() == 50, "while conserva el límite de 50 iteraciones")
	_verificar(limite_while.get("loop_iterations", 0) == 50, "while conserva su métrica de iteraciones")
	_verificar(limite_while.get("loop_count", 0) == 1, "while conserva su métrica de bucles")

	root.get_node("ProgressService").clear_progress()
	misiones.completed_missions.clear()
	misiones.unlocked_knowledge = ["objeto", "metodo"]
	if fallos > 0:
		push_error("Suite parámetros y variables: %d de %d comprobaciones fallaron." % [fallos, casos])
		quit(1)
		return
	print("OK: %d comprobaciones de parámetros, variables, Camino Largo, range y regresiones de ejecución." % casos)
	quit(0)


func _ejecutar(codigo: String) -> Dictionary:
	comandos_ejecutados.clear()
	errores_emitidos.clear()
	return await executor.ejecutar_codigo(codigo, _ejecutar_comando)


func _registrar_error(error: Dictionary) -> void:
	errores_emitidos.append(error.duplicate(true))


func _avanzar_paso(numero: int, _contenido: String) -> void:
	pasos_esperados.append(numero)
	executor.call_deferred("avanzar_un_paso")


func _siempre_verdadero(_condicion: String) -> bool:
	return true


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
