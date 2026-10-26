extends Node

signal ejecucion_iniciada(codigo: String)
signal linea_iniciada(numero: int, contenido: String)
signal linea_finalizada(numero: int, contenido: String)
signal error_detectado(error: Dictionary)
signal ejecucion_finalizada(resultado: Dictionary)
signal progreso_actualizado(resultado: Dictionary)
signal paso_esperando(numero: int, contenido: String)
signal _avanzar_paso_solicitado

var ejecutando: bool = false
var detener_solicitado: bool = false
var modo_paso_a_paso: bool = false
var esperando_paso: bool = false
var _tiempo_inicio_msec : float = 0.0
var _objective_id_at_start: String = ""
var _objective_completed_at_start: bool = false

const PALABRAS_RESERVADAS := [
	"spid", "for", "while", "if", "else", "in", "range",
	"not", "and", "or", "true", "false", "True", "False"
]
const MAX_FOR_ITER := 50

func _es_identificador_valido(nombre: String) -> bool:
	var regex := RegEx.new()
	if regex.compile("^[A-Za-z_][A-Za-z0-9_]*$") != OK:
		return false
	return regex.search(nombre) != null and nombre not in PALABRAS_RESERVADAS


func _es_lista_valida(expr: String) -> bool:
	var limpia := expr.strip_edges()
	return limpia.begins_with("[") and limpia.ends_with("]")


func _parsear_elementos_lista(expr: String) -> Array:
	var limpia := expr.strip_edges()
	if not (limpia.begins_with("[") and limpia.ends_with("]")):
		return []
	var contenido := limpia.substr(1, limpia.length() - 2).strip_edges()
	if contenido.is_empty():
		return []
	var items := contenido.split(",")
	var res: Array = []
	for item in items:
		var it := item.strip_edges()
		if (it.begins_with('"') and it.ends_with('"')) or (it.begins_with("'") and it.ends_with("'")):
			res.append(it.substr(1, it.length() - 2))
		elif it.is_valid_int():
			res.append(int(it))
		else:
			res.append(it)
	return res


func _es_expresion_valida(expr: String) -> bool:
	var limpia := expr.strip_edges()
	if limpia.is_empty():
		return false
	if limpia.is_valid_int():
		return true
	if _es_identificador_valido(limpia):
		return true
	var limpia_lower := limpia.to_lower().replace(" ", "")
	if limpia_lower in [
		"spid.tamano_mundo()", "tamano_mundo()",
		"spid.minerales_en_nave()", "minerales_en_nave()",
		"spid.minerales_en_rover()", "minerales_en_rover()"
	]:
		return true
	for op in ["+", "-", "*", "//"]:
		if op in limpia and not limpia.begins_with("-"):
			var partes := limpia.split(op, false, 1)
			if partes.size() == 2:
				return _es_expresion_valida(partes[0]) and _es_expresion_valida(partes[1])
	return false


func _evaluar_expresion(expr: String, variables_env: Dictionary, resultado: Dictionary) -> Dictionary:
	var limpia := expr.strip_edges()
	if limpia.is_empty():
		return {"ok": false, "message": "Expresión vacía."}

	# 1. Operador +
	if "+" in limpia:
		var partes := limpia.split("+", false, 1)
		var izq := _evaluar_expresion(partes[0], variables_env, resultado)
		if not izq.get("ok", false):
			return izq
		var der := _evaluar_expresion(partes[1], variables_env, resultado)
		if not der.get("ok", false):
			return der
		return {"ok": true, "val": int(izq["val"]) + int(der["val"])}

	# 2. Operador - (no confundir con negativos como -1 al inicio)
	if "-" in limpia and not limpia.begins_with("-"):
		var partes := limpia.split("-", false, 1)
		var izq := _evaluar_expresion(partes[0], variables_env, resultado)
		if not izq.get("ok", false):
			return izq
		var der := _evaluar_expresion(partes[1], variables_env, resultado)
		if not der.get("ok", false):
			return der
		return {"ok": true, "val": int(izq["val"]) - int(der["val"])}

	# 3. Operador *
	if "*" in limpia:
		var partes := limpia.split("*", false, 1)
		var izq := _evaluar_expresion(partes[0], variables_env, resultado)
		if not izq.get("ok", false):
			return izq
		var der := _evaluar_expresion(partes[1], variables_env, resultado)
		if not der.get("ok", false):
			return der
		return {"ok": true, "val": int(izq["val"]) * int(der["val"])}

	# 4. Operador //
	if "//" in limpia:
		var partes := limpia.split("//", false, 1)
		var izq := _evaluar_expresion(partes[0], variables_env, resultado)
		if not izq.get("ok", false):
			return izq
		var der := _evaluar_expresion(partes[1], variables_env, resultado)
		if not der.get("ok", false):
			return der
		var divisor: int = int(der["val"])
		if divisor == 0:
			return {"ok": false, "message": "División por cero no permitida."}
		return {"ok": true, "val": int(izq["val"]) / divisor}

	# 5. Literal entero
	if limpia.is_valid_int():
		return {"ok": true, "val": int(limpia)}

	# 6. Variable del entorno
	if variables_env.has(limpia):
		if resultado.has("variables_used") and limpia not in resultado["variables_used"]:
			resultado["variables_used"].append(limpia)
		return {"ok": true, "val": int(variables_env[limpia])}

	# 7. Métodos de telemetría de Spid
	var limpia_lower := limpia.to_lower().replace(" ", "")
	if limpia_lower in ["spid.tamano_mundo()", "tamano_mundo()"]:
		var val := 3
		var root := Engine.get_main_loop() as SceneTree
		if root != null and root.current_scene != null:
			var spid = root.current_scene.find_child("Spid", true, false)
			if spid != null and spid.has_method("tamano_mundo"):
				val = spid.tamano_mundo()
		if resultado.has("variables_used") and "spid.tamano_mundo()" not in resultado["variables_used"]:
			resultado["variables_used"].append("spid.tamano_mundo()")
		return {"ok": true, "val": val}

	if limpia_lower in ["spid.minerales_en_nave()", "minerales_en_nave()"]:
		var val := 0
		var root := Engine.get_main_loop() as SceneTree
		if root != null and root.current_scene != null:
			var interfaz = root.current_scene.get_node_or_null("CanvasLayer")
			if interfaz != null and "minerales_nave" in interfaz:
				val = int(interfaz.minerales_nave)
			elif MissionService != null and MissionService.has_method("_obtener_minerales_nave"):
				val = MissionService._obtener_minerales_nave()
		return {"ok": true, "val": val}

	if limpia_lower in ["spid.minerales_en_rover()", "minerales_en_rover()"]:
		var val := 0
		var root := Engine.get_main_loop() as SceneTree
		if root != null and root.current_scene != null:
			var spid = root.current_scene.find_child("Spid", true, false)
			if spid != null and spid.has_method("minerales_en_rover"):
				val = spid.minerales_en_rover()
		return {"ok": true, "val": val}

	return {"ok": false, "message": "La variable o identificador '" + limpia + "' no ha sido definida."}

func detener_ejecucion() -> void:
	if ejecutando:
		detener_solicitado = true
		if esperando_paso:
			_avanzar_paso_solicitado.emit()

func avanzar_un_paso() -> void:
	if ejecutando and esperando_paso:
		_avanzar_paso_solicitado.emit()

func continuar_todo() -> void:
	if ejecutando:
		modo_paso_a_paso = false
		if esperando_paso:
			_avanzar_paso_solicitado.emit()

func _esperar_paso_si_aplica(numero: int, contenido: String) -> void:
	if modo_paso_a_paso and not detener_solicitado:
		esperando_paso = true
		paso_esperando.emit(numero, contenido)
		await _avanzar_paso_solicitado
		esperando_paso = false

func ejecutar_codigo(
	codigo: String,
	ejecutar_comando: Callable,
	evaluar_condicion: Callable = Callable(),
	paso_a_paso: bool = false
) -> Dictionary:
	_tiempo_inicio_msec = Time.get_ticks_msec()
	var resultado := _crear_resultado(codigo)
	var variables_env: Dictionary = {}

	if ejecutando:
		resultado["error_type"] = "ejecucion"
		resultado["error_message"] = "Ya existe un programa en ejecución."
		return resultado

	_objective_id_at_start = MissionService.objective_id
	_objective_completed_at_start = (
		MissionService.objective_completed
		or _objective_id_at_start in MissionService.get_completed_missions()
	)
	resultado["objective_id"] = _objective_id_at_start
	resultado["objective_completed"] = false

	ejecutando = true
	detener_solicitado = false
	modo_paso_a_paso = paso_a_paso
	esperando_paso = false
	ejecucion_iniciada.emit(codigo)

	if not GestorSintaxis.validar_codigo(codigo):
		resultado["error_type"] = "sintaxis_bloqueada"
		resultado["error_message"] = (
			"El código utiliza una estructura que todavía no está desbloqueada."
		)
		resultado["errors"].append({
			"type": resultado["error_type"],
			"line": 0,
			"message": resultado["error_message"]
		})

		error_detectado.emit(resultado["errors"][0])
		_finalizar(resultado)
		return resultado

	var compilacion: Dictionary = compilar_programa(codigo)

	if not compilacion["ok"]:
		var error: Dictionary = compilacion["error"]

		resultado["error_type"] = error["type"]
		resultado["error_message"] = error["message"]
		resultado["errors"].append(error)

		error_detectado.emit(error)
		_finalizar(resultado)
		return resultado

	var instrucciones: Array = compilacion["instrucciones"]
	if "for " in codigo:
		resultado["loop_count"] = 1

		for instruccion in instrucciones:
			resultado["loop_iterations"] = maxi(
				resultado["loop_iterations"],
				int(instruccion.get("loop_iteration", 0))
			)

	for instruccion in instrucciones:
		var tipo: String = instruccion.get("tipo", "comando")

		if tipo == "asignacion":
			var num_linea: int = instruccion["numero"]
			var cont_linea: String = instruccion["contenido"]
			linea_iniciada.emit(num_linea, cont_linea)
			await _esperar_paso_si_aplica(num_linea, cont_linea)
			if detener_solicitado:
				linea_finalizada.emit(num_linea, cont_linea)
				break

			var var_name: String = instruccion["var_name"]
			var var_expr: String = instruccion["var_expr"]
			var res_expr := _evaluar_expresion(var_expr, variables_env, resultado)

			if not res_expr.get("ok", false):
				var err_asig := {
					"type": "ejecucion",
					"line": num_linea,
					"content": cont_linea,
					"message": res_expr.get("message", "Error al evaluar la variable '" + var_expr + "'.")
				}
				resultado["error_type"] = err_asig["type"]
				resultado["error_message"] = err_asig["message"]
				resultado["errors"].append(err_asig)
				error_detectado.emit(err_asig)
				_finalizar(resultado)
				return resultado

			var val: int = int(res_expr["val"])
			variables_env[var_name] = val
			if var_name not in resultado["variables_defined"]:
				resultado["variables_defined"].append(var_name)

			linea_finalizada.emit(num_linea, cont_linea)
			continue

		if tipo == "asignacion_lista":
			var num_linea: int = instruccion["numero"]
			var cont_linea: String = instruccion["contenido"]
			linea_iniciada.emit(num_linea, cont_linea)
			await _esperar_paso_si_aplica(num_linea, cont_linea)
			var var_name: String = instruccion["var_name"]
			var var_elems: Array = instruccion.get("var_elements", [])
			variables_env[var_name] = var_elems
			if var_name not in resultado["variables_defined"]:
				resultado["variables_defined"].append(var_name)
			linea_finalizada.emit(num_linea, cont_linea)
			continue

		if tipo == "if":
			if instruccion.has("loop_var") and instruccion.has("loop_val"):
				variables_env[instruccion["loop_var"]] = instruccion["loop_val"]
			var num_linea: int = instruccion["numero"]
			var cont_linea: String = instruccion["contenido"]
			linea_iniciada.emit(num_linea, cont_linea)
			await _esperar_paso_si_aplica(num_linea, cont_linea)
			if detener_solicitado:
				linea_finalizada.emit(num_linea, cont_linea)
				break

			var cumple_condicion: bool = false
			if evaluar_condicion.is_valid():
				cumple_condicion = await evaluar_condicion.call(instruccion["condition"])

			if instruccion.get("inverted", false):
				cumple_condicion = not cumple_condicion

			resultado["if_evaluations"] = resultado.get("if_evaluations", 0) + 1

			if cumple_condicion:
				resultado["if_branch_taken"] = true
				for sub_instruccion in instruccion.get("cuerpo", []):
					if detener_solicitado:
						break
					if int(instruccion.get("loop_iteration", 0)) > 0:
						sub_instruccion["loop_iteration"] = instruccion["loop_iteration"]
					var res_sub: Dictionary = await _ejecutar_instruccion_simple(
						sub_instruccion,
						ejecutar_comando,
						resultado,
						variables_env
					)
					if not res_sub.get("ok", false):
						_finalizar(resultado)
						return resultado
			elif instruccion.has("cuerpo_else"):
				resultado["else_branch_taken"] = true
				if instruccion.has("else_numero"):
					linea_iniciada.emit(instruccion["else_numero"], instruccion.get("else_contenido", "else:"))
					await _esperar_paso_si_aplica(instruccion["else_numero"], instruccion.get("else_contenido", "else:"))
					linea_finalizada.emit(instruccion["else_numero"], instruccion.get("else_contenido", "else:"))
				for sub_instruccion in instruccion.get("cuerpo_else", []):
					if detener_solicitado:
						break
					if int(instruccion.get("loop_iteration", 0)) > 0:
						sub_instruccion["loop_iteration"] = instruccion["loop_iteration"]
					var res_sub: Dictionary = await _ejecutar_instruccion_simple(
						sub_instruccion,
						ejecutar_comando,
						resultado,
						variables_env
					)
					if not res_sub.get("ok", false):
						_finalizar(resultado)
						return resultado

			linea_finalizada.emit(num_linea, cont_linea)
			if detener_solicitado:
				break
			continue

		if tipo == "while":
			var num_linea: int = instruccion["numero"]
			var cont_linea: String = instruccion["contenido"]
			var condicion: String = instruccion["condition"]
			var invertido: bool = instruccion.get("inverted", false)
			var cuerpo_while: Array = instruccion.get("cuerpo", [])
			const MAX_WHILE_ITER: int = 50
			var iteracion: int = 0
			resultado["loop_count"] = maxi(int(resultado.get("loop_count", 0)), 1)
			while true:
				if detener_solicitado:
					break
				iteracion += 1
				if iteracion > MAX_WHILE_ITER:
					var err_infinito := {
						"type": "ejecucion",
						"line": num_linea,
						"content": cont_linea,
						"message": "Límite de seguridad alcanzado: el bucle while superó 50 iteraciones para prevenir un bucle infinito."
					}
					resultado["error_type"] = err_infinito["type"]
					resultado["error_message"] = err_infinito["message"]
					resultado["errors"].append(err_infinito)
					error_detectado.emit(err_infinito)
					_finalizar(resultado)
					return resultado
				linea_iniciada.emit(num_linea, cont_linea)
				await _esperar_paso_si_aplica(num_linea, cont_linea)
				if detener_solicitado:
					linea_finalizada.emit(num_linea, cont_linea)
					break
				var cumple: bool = false
				if evaluar_condicion.is_valid():
					cumple = await evaluar_condicion.call(condicion)
				if invertido:
					cumple = not cumple
				linea_finalizada.emit(num_linea, cont_linea)
				if not cumple:
					break
				resultado["loop_iterations"] = maxi(int(resultado.get("loop_iterations", 0)), iteracion)
				for sub_ins in cuerpo_while:
					if detener_solicitado:
						break
					var sub_tipo: String = sub_ins.get("tipo", "comando")
					if sub_tipo == "for":
						var num_for: int = sub_ins["numero"]
						var cont_for: String = sub_ins["contenido"]
						var repeticiones_for: int = int(sub_ins.get("repeticiones", 1))
						var range_var_sub: String = str(sub_ins.get("range_var", ""))
						if not range_var_sub.is_empty():
							var res_range_sub := _evaluar_expresion(range_var_sub, variables_env, resultado)
							if res_range_sub.get("ok", false):
								repeticiones_for = int(res_range_sub["val"])
						var cuerpo_for_sub: Array = sub_ins.get("cuerpo", [])
						resultado["loop_count"] = maxi(int(resultado.get("loop_count", 0)), 1)

						var elementos_iteracion: Array = []
						var loop_v: String = sub_ins.get("loop_var", "")
						if sub_ins.get("tipo_for") == "lista":
							if sub_ins.has("list_var") and not str(sub_ins["list_var"]).is_empty():
								var l_var: String = str(sub_ins["list_var"])
								if variables_env.has(l_var) and variables_env[l_var] is Array:
									elementos_iteracion = variables_env[l_var]
								if resultado.has("variables_used") and l_var not in resultado["variables_used"]:
									resultado["variables_used"].append(l_var)
							else:
								elementos_iteracion = sub_ins.get("list_literal", [])
							repeticiones_for = elementos_iteracion.size()

						for it_for in range(repeticiones_for):
							if detener_solicitado:
								break
							if sub_ins.get("tipo_for") == "lista" and it_for < elementos_iteracion.size():
								if not loop_v.is_empty():
									variables_env[loop_v] = elementos_iteracion[it_for]
							resultado["loop_iterations"] = maxi(int(resultado.get("loop_iterations", 0)), it_for + 1)
							linea_iniciada.emit(num_for, cont_for)
							await _esperar_paso_si_aplica(num_for, cont_for)
							linea_finalizada.emit(num_for, cont_for)
							for cmd_for in cuerpo_for_sub:
								if detener_solicitado:
									break
								if cmd_for.get("tipo", "") == "if":
									var num_if: int = cmd_for["numero"]
									var cont_if: String = cmd_for["contenido"]
									linea_iniciada.emit(num_if, cont_if)
									await _esperar_paso_si_aplica(num_if, cont_if)
									if detener_solicitado:
										linea_finalizada.emit(num_if, cont_if)
										break
									var cumple_if: bool = false
									if evaluar_condicion.is_valid():
										cumple_if = await evaluar_condicion.call(cmd_for["condition"])
									if cmd_for.get("inverted", false):
										cumple_if = not cumple_if
									resultado["if_evaluations"] = resultado.get("if_evaluations", 0) + 1
									if cumple_if:
										resultado["if_branch_taken"] = true
										for sub_cmd in cmd_for.get("cuerpo", []):
											if detener_solicitado:
												break
											sub_cmd["loop_iteration"] = iteracion
											var res_sub := await _ejecutar_instruccion_simple(
												sub_cmd,
												ejecutar_comando,
												resultado,
												variables_env
											)
											if not res_sub.get("ok", false):
												_finalizar(resultado)
												return resultado
									linea_finalizada.emit(num_if, cont_if)
								else:
									cmd_for["loop_iteration"] = iteracion
									var res_cmd := await _ejecutar_instruccion_simple(
										cmd_for,
										ejecutar_comando,
										resultado,
										variables_env
									)
									if not res_cmd.get("ok", false):
										_finalizar(resultado)
										return resultado
						continue

					if sub_tipo == "if":
						var num_if: int = sub_ins["numero"]
						var cont_if: String = sub_ins["contenido"]
						linea_iniciada.emit(num_if, cont_if)
						await _esperar_paso_si_aplica(num_if, cont_if)
						if detener_solicitado:
							linea_finalizada.emit(num_if, cont_if)
							break
						var cumple_if: bool = false
						if evaluar_condicion.is_valid():
							cumple_if = await evaluar_condicion.call(sub_ins["condition"])
						if sub_ins.get("inverted", false):
							cumple_if = not cumple_if
						resultado["if_evaluations"] = resultado.get("if_evaluations", 0) + 1
						if cumple_if:
							resultado["if_branch_taken"] = true
							for cmd_if in sub_ins.get("cuerpo", []):
								if detener_solicitado:
									break
								cmd_if["loop_iteration"] = iteracion
								var res_sub: Dictionary = await _ejecutar_instruccion_simple(
									cmd_if,
									ejecutar_comando,
									resultado,
									variables_env
								)
								if not res_sub.get("ok", false):
									_finalizar(resultado)
									return resultado
						elif sub_ins.has("cuerpo_else"):
							resultado["else_branch_taken"] = true
							if sub_ins.has("else_numero"):
								linea_iniciada.emit(sub_ins["else_numero"], sub_ins.get("else_contenido", "else:"))
								await _esperar_paso_si_aplica(sub_ins["else_numero"], sub_ins.get("else_contenido", "else:"))
								linea_finalizada.emit(sub_ins["else_numero"], sub_ins.get("else_contenido", "else:"))
							for cmd_else in sub_ins.get("cuerpo_else", []):
								if detener_solicitado:
									break
								cmd_else["loop_iteration"] = iteracion
								var res_sub: Dictionary = await _ejecutar_instruccion_simple(
									cmd_else,
									ejecutar_comando,
									resultado,
									variables_env
								)
								if not res_sub.get("ok", false):
									_finalizar(resultado)
									return resultado
						linea_finalizada.emit(num_if, cont_if)
						continue
					sub_ins["loop_iteration"] = iteracion
					var res_while_cmd: Dictionary = await _ejecutar_instruccion_simple(
						sub_ins,
						ejecutar_comando,
						resultado,
						variables_env
					)
					if not res_while_cmd.get("ok", false):
						_finalizar(resultado)
						return resultado
					if detener_solicitado:
						break

			if detener_solicitado:
				break
			progreso_actualizado.emit(resultado)
			continue

		var res_cmd: Dictionary = await _ejecutar_instruccion_simple(
			instruccion,
			ejecutar_comando,
			resultado,
			variables_env
		)
		if not res_cmd.get("ok", false):
			_finalizar(resultado)
			return resultado

	resultado["success"] = true
	_finalizar(resultado)
	return resultado


func _ejecutar_instruccion_simple(
	instruccion: Dictionary,
	ejecutar_comando: Callable,
	resultado: Dictionary,
	variables_env: Dictionary = {}
) -> Dictionary:
	var numero_linea: int = int(instruccion.get("numero", 0))
	var contenido: String = str(instruccion.get("contenido", ""))
	var comando: String = str(instruccion.get("command", instruccion.get("comando", "")))
	var pasos: int = int(instruccion.get("steps", 1))
	var step_var: String = str(instruccion.get("step_var", ""))

	linea_iniciada.emit(numero_linea, contenido)
	await _esperar_paso_si_aplica(numero_linea, contenido)

	if instruccion.has("loop_var") and instruccion.has("loop_val"):
		variables_env[instruccion["loop_var"]] = instruccion["loop_val"]

	if detener_solicitado:
		linea_finalizada.emit(numero_linea, contenido)
		return {
			"ok": false,
			"error_type": "ejecucion",
			"message": "Ejecución detenida."
		}

	if not step_var.is_empty():
		var res_eval := _evaluar_expresion(step_var, variables_env, resultado)
		if res_eval.get("ok", false):
			pasos = int(res_eval["val"])
			if pasos <= 0:
				var error_var := {
					"type": "ejecucion",
					"line": numero_linea,
					"content": contenido,
					"message": "La expresión o variable '" + step_var + "' tiene un valor que debe ser mayor a cero."
				}
				resultado["error_type"] = error_var["type"]
				resultado["error_message"] = error_var["message"]
				resultado["errors"].append(error_var)
				error_detectado.emit(error_var)
				linea_finalizada.emit(numero_linea, contenido)
				return {"ok": false}
		else:
			var error_undef := {
				"type": "sintaxis",
				"line": numero_linea,
				"content": contenido,
				"message": res_eval.get("message", "La variable '" + step_var + "' no ha sido definida antes de su uso.")
			}
			resultado["error_type"] = error_undef["type"]
			resultado["error_message"] = error_undef["message"]
			resultado["errors"].append(error_undef)
			error_detectado.emit(error_undef)
			linea_finalizada.emit(numero_linea, contenido)
			return {"ok": false}

	if comando.is_empty():
		linea_finalizada.emit(numero_linea, contenido)
		return {"ok": true}

	if comando == "mover":
		var dir_objetivo: String = str(instruccion.get("dir_literal", ""))
		var dir_v: String = str(instruccion.get("dir_var", ""))
		if dir_objetivo.is_empty() and not dir_v.is_empty():
			if variables_env.has(dir_v):
				dir_objetivo = str(variables_env[dir_v]).to_lower().replace('"', '').replace("'", "")
				if resultado.has("variables_used") and dir_v not in resultado["variables_used"]:
					resultado["variables_used"].append(dir_v)
			else:
				var err_dir := {
					"type": "ejecucion",
					"line": numero_linea,
					"content": contenido,
					"message": "La variable de dirección '" + dir_v + "' no ha sido definida."
				}
				resultado["error_type"] = err_dir["type"]
				resultado["error_message"] = err_dir["message"]
				resultado["errors"].append(err_dir)
				error_detectado.emit(err_dir)
				linea_finalizada.emit(numero_linea, contenido)
				return {"ok": false}

		if dir_objetivo not in ["norte", "sur", "este", "oeste"]:
			var err_dir_val := {
				"type": "ejecucion",
				"line": numero_linea,
				"content": contenido,
				"message": "Dirección inválida en spid.mover(): '" + dir_objetivo + "'. Debe ser 'norte', 'sur', 'este' u 'oeste'."
			}
			resultado["error_type"] = err_dir_val["type"]
			resultado["error_message"] = err_dir_val["message"]
			resultado["errors"].append(err_dir_val)
			error_detectado.emit(err_dir_val)
			linea_finalizada.emit(numero_linea, contenido)
			return {"ok": false}

		var res_mov: Dictionary = await ejecutar_comando.call(dir_objetivo, pasos)
		resultado["commands_used"].append("mover")
		resultado["commands_used"].append(dir_objetivo)
		resultado["commands_data"].append({"command": "mover", "direction": dir_objetivo, "steps": pasos})
		resultado["command_count"] += 1
		resultado["movement_count"] += int(res_mov.get("steps_completed", 0))
		var recolectados_m: int = int(res_mov.get("minerals_collected", 0))
		var transferidos_m: int = int(res_mov.get("minerals_transferred", 0))
		resultado["minerals_collected"] += recolectados_m
		resultado["minerals_transferred"] += transferidos_m
		linea_finalizada.emit(numero_linea, contenido)
		return res_mov

	var resultado_comando: Dictionary = await ejecutar_comando.call(
		comando,
		pasos
	)
	resultado["commands_used"].append(comando)
	resultado["commands_data"].append({
		"command": comando,
		"steps": pasos
	})
	resultado["command_count"] += 1
	resultado["movement_count"] += int(resultado_comando.get("steps_completed", 0))
	var recolectados: int = int(resultado_comando.get("minerals_collected", 0))
	var transferidos: int = int(resultado_comando.get("minerals_transferred", 0))
	resultado["minerals_collected"] += recolectados
	resultado["minerals_transferred"] += transferidos
	if (
		_objective_id_at_start == "trabajo_continuo"
		and int(resultado.get("minerals_transferred", 0)) >= 2
	):
		detener_solicitado = true
	elif (
		_objective_id_at_start == "cuota_suministro"
		and int(resultado.get("minerals_transferred", 0)) >= 10
	):
		detener_solicitado = true
	elif (
		_objective_id_at_start in ["ciclo_autonomo", "exploracion_3x3"]
		and int(resultado.get("minerals_transferred", 0)) >= 3
	):
		detener_solicitado = true
	elif (
		_objective_id_at_start in ["variables", "camino_largo"]
		and int(resultado.get("minerals_transferred", 0)) >= 1
	):
		detener_solicitado = true
	if int(instruccion.get("loop_iteration", 0)) > 0:
		resultado["loop_minerals_collected"] += recolectados
	if not resultado_comando.get("ok", false):
		var error_comando := {
			"type": resultado_comando.get("error_type", "ejecucion"),
			"line": numero_linea,
			"content": contenido,
			"message": resultado_comando.get("message", "El comando no pudo completarse.")
		}
		resultado["error_type"] = error_comando["type"]
		resultado["error_message"] = error_comando["message"]
		resultado["errors"].append(error_comando)
		error_detectado.emit(error_comando)
	else:
		MissionService.evaluar_progreso_programa(resultado)
	linea_finalizada.emit(numero_linea, contenido)
	return resultado_comando

func _analizar_asignacion(contenido: String, numero_linea: int) -> Dictionary:
	if not ("=" in contenido):
		return {"ok": false}
	if "==" in contenido or ">=" in contenido or "<=" in contenido or "!=" in contenido:
		return {"ok": false}
	var partes := contenido.split("=", false, 1)
	if partes.size() != 2:
		return {"ok": false}
	var nombre_var := partes[0].strip_edges()
	var expr_val := partes[1].strip_edges()

	if not _es_identificador_valido(nombre_var):
		if nombre_var in PALABRAS_RESERVADAS:
			return _error_de_linea(
				numero_linea,
				contenido,
				"No puedes usar '" + nombre_var + "' como nombre de variable porque es una palabra reservada."
			)
		return _error_de_linea(
			numero_linea,
			contenido,
			"'" + nombre_var + "' no es un nombre de variable válido."
		)

	if _es_lista_valida(expr_val):
		var elementos := _parsear_elementos_lista(expr_val)
		return {
			"ok": true,
			"tipo": "asignacion_lista",
			"var_name": nombre_var,
			"var_elements": elementos,
			"var_expr": expr_val
		}

	if not _es_expresion_valida(expr_val):
		return _error_de_linea(
			numero_linea,
			contenido,
			"El valor asignado a '" + nombre_var + "' debe ser un número entero, una lista, una variable o una expresión válida."
		)

	return {
		"ok": true,
		"tipo": "asignacion",
		"var_name": nombre_var,
		"var_expr": expr_val
	}

func analizar_linea(contenido: String, numero_linea: int) -> Dictionary:
	if not contenido.begins_with("spid."):
		return _error_de_linea(
			numero_linea,
			contenido,
			"La instrucción debe comenzar con 'spid.' o ser una asignación de variable (ej: pasos = 2)."
		)

	var posicion_punto := contenido.find(".")
	var posicion_parentesis_izquierdo := contenido.find("(")
	var posicion_parentesis_derecho := contenido.rfind(")")

	if posicion_parentesis_izquierdo == -1:
		return _error_de_linea(
			numero_linea,
			contenido,
			"Falta el paréntesis de apertura."
		)

	if posicion_parentesis_derecho == -1:
		return _error_de_linea(
			numero_linea,
			contenido,
			"Falta el paréntesis de cierre."
		)

	if posicion_parentesis_derecho != contenido.length() - 1:
		return _error_de_linea(
			numero_linea,
			contenido,
			"Hay contenido después del paréntesis de cierre."
		)

	var comando := contenido.substr(
		posicion_punto + 1,
		posicion_parentesis_izquierdo - posicion_punto - 1
	).strip_edges()

	var comandos_validos := [
		"norte",
		"sur",
		"este",
		"oeste",
		"minar",
		"transferir",
		"mover"
	]

	if comando not in comandos_validos:
		return _error_de_linea(
			numero_linea,
			contenido,
			"spid no conoce el comando '" + comando + "'."
		)

	var argumento := contenido.substr(
		posicion_parentesis_izquierdo + 1,
		posicion_parentesis_derecho - posicion_parentesis_izquierdo - 1
	).strip_edges()

	if comando == "mover":
		if argumento.is_empty():
			return _error_de_linea(
				numero_linea,
				contenido,
				"spid.mover() requiere especificar la dirección (ej: spid.mover('norte') o spid.mover(direccion))."
			)
		var partes_mover := argumento.split(",", false, 1)
		var dir_arg := partes_mover[0].strip_edges()
		var pasos_mover := 1
		if partes_mover.size() > 1:
			var p_arg := partes_mover[1].strip_edges()
			if p_arg.is_valid_int():
				pasos_mover = int(p_arg)
		var dir_literal := ""
		var dir_var := ""
		if (dir_arg.begins_with('"') and dir_arg.ends_with('"')) or (dir_arg.begins_with("'") and dir_arg.ends_with("'")):
			dir_literal = dir_arg.substr(1, dir_arg.length() - 2).to_lower()
		elif _es_identificador_valido(dir_arg):
			dir_var = dir_arg
		else:
			return _error_de_linea(
				numero_linea,
				contenido,
				"El parámetro de dirección en spid.mover() debe ser un texto entre comillas o una variable válida."
			)
		return {
			"ok": true,
			"command": "mover",
			"steps": pasos_mover,
			"step_var": "",
			"dir_literal": dir_literal,
			"dir_var": dir_var
		}

	var pasos := 1
	var step_var := ""

	if not argumento.is_empty():
		if argumento.is_valid_int():
			pasos = int(argumento)
			if pasos <= 0:
				return _error_de_linea(
					numero_linea,
					contenido,
					"La cantidad de pasos debe ser mayor que cero."
				)
		elif _es_identificador_valido(argumento) or _es_expresion_valida(argumento):
			step_var = argumento
		else:
			return _error_de_linea(
				numero_linea,
				contenido,
				"El parámetro debe ser un número entero, una variable o una expresión válida (ej. 'limite - 1')."
			)

	if comando in ["minar", "transferir"] and not argumento.is_empty():
		return _error_de_linea(
			numero_linea,
			contenido,
			"El comando '" + comando + "' no recibe parámetros."
		)

	return {
		"ok": true,
		"command": comando,
		"steps": pasos,
		"step_var": step_var
	}

func _crear_instruccion_comando(numero_linea: int, contenido: String, analisis: Dictionary) -> Dictionary:
	return {
		"tipo": "comando",
		"numero": numero_linea,
		"contenido": contenido,
		"command": analisis["command"],
		"steps": analisis.get("steps", 1),
		"step_var": analisis.get("step_var", ""),
		"dir_literal": analisis.get("dir_literal", ""),
		"dir_var": analisis.get("dir_var", "")
	}

func _contar_espacios_sangria(linea: String) -> int:
	var espacios := 0
	for i in range(linea.length()):
		var c := linea[i]
		if c == "\t":
			espacios += 4
		elif c == " ":
			espacios += 1
		else:
			break
	return espacios

func compilar_programa(codigo: String) -> Dictionary:
	var instrucciones: Array = []
	var lineas := codigo.split("\n")
	var indice := 0
	var variables_compile_env: Dictionary = {}

	while indice < lineas.size():
		var linea_original: String = lineas[indice]
		var contenido := linea_original.strip_edges()
		var numero_linea := indice + 1

		if contenido.is_empty() or contenido.begins_with("#"):
			indice += 1
			continue

		var contenido_lower := contenido.to_lower()

		var res_asig := _analizar_asignacion(contenido, numero_linea)
		if res_asig.get("tipo", "") == "asignacion":
			if not res_asig["ok"]:
				return res_asig
			var vname: String = res_asig["var_name"]
			var vexpr: String = res_asig["var_expr"]
			var res_compile_expr := _evaluar_expresion(vexpr, variables_compile_env, {})
			if res_compile_expr.get("ok", false):
				variables_compile_env[vname] = res_compile_expr["val"]
			instrucciones.append({
				"tipo": "asignacion",
				"numero": numero_linea,
				"contenido": contenido,
				"var_name": vname,
				"var_expr": vexpr,
				"loop_iteration": 0
			})
			indice += 1
			continue

		if res_asig.get("tipo", "") == "asignacion_lista":
			if not res_asig["ok"]:
				return res_asig
			var vname_l: String = res_asig["var_name"]
			var velements: Array = res_asig["var_elements"]
			variables_compile_env[vname_l] = velements
			instrucciones.append({
				"tipo": "asignacion_lista",
				"numero": numero_linea,
				"contenido": contenido,
				"var_name": vname_l,
				"var_elements": velements,
				"loop_iteration": 0
			})
			indice += 1
			continue

		if contenido_lower.begins_with("if "):
			var resultado_if: Dictionary = _analizar_if(contenido, numero_linea)
			if not resultado_if["ok"]:
				return resultado_if

			var sangria_base := _contar_espacios_sangria(linea_original)
			var cuerpo_if: Array = []
			var sangria_cuerpo_if_top := -1
			indice += 1

			while indice < lineas.size():
				var linea_cuerpo: String = lineas[indice]
				if linea_cuerpo.strip_edges().is_empty() or linea_cuerpo.strip_edges().begins_with("#"):
					indice += 1
					continue

				var sangria_cuerpo := _contar_espacios_sangria(linea_cuerpo)
				if sangria_cuerpo <= sangria_base:
					break

				if sangria_cuerpo_if_top == -1:
					sangria_cuerpo_if_top = sangria_cuerpo
				elif sangria_cuerpo < sangria_cuerpo_if_top:
					break

				var contenido_cuerpo := linea_cuerpo.strip_edges()
				var analisis_if: Dictionary = analizar_linea(contenido_cuerpo, indice + 1)
				if not analisis_if["ok"]:
					return analisis_if

				cuerpo_if.append(_crear_instruccion_comando(indice + 1, contenido_cuerpo, analisis_if))
				indice += 1

			if cuerpo_if.is_empty():
				return _error_de_linea(
					numero_linea,
					contenido,
					"El condicional if necesita al menos una instrucción con sangría."
				)

			var cuerpo_else: Array = []
			var else_numero: int = 0
			var else_contenido: String = ""

			var idx_la := indice
			while idx_la < lineas.size():
				var l_la := lineas[idx_la]
				if l_la.strip_edges().is_empty() or l_la.strip_edges().begins_with("#"):
					idx_la += 1
					continue
				break

			if idx_la < lineas.size():
				var linea_p_else := lineas[idx_la]
				var sangria_p_else := _contar_espacios_sangria(linea_p_else)
				var cont_p_else := linea_p_else.strip_edges()

				if cont_p_else.to_lower().begins_with("else"):
					if sangria_p_else != sangria_base:
						return _error_de_linea(
							idx_la + 1,
							cont_p_else,
							"La sangría de 'else:' debe coincidir con el 'if' correspondiente."
						)
					if cont_p_else.to_lower() != "else:":
						return _error_de_linea(
							idx_la + 1,
							cont_p_else,
							"Sintaxis incorrecta. Usa 'else:' con dos puntos al final."
						)

					else_numero = idx_la + 1
					else_contenido = cont_p_else
					indice = idx_la + 1
					var sangria_cuerpo_else_top := -1

					while indice < lineas.size():
						var linea_c_else: String = lineas[indice]
						if linea_c_else.strip_edges().is_empty() or linea_c_else.strip_edges().begins_with("#"):
							indice += 1
							continue

						var sangria_c_else := _contar_espacios_sangria(linea_c_else)
						if sangria_c_else <= sangria_base:
							break

						if sangria_cuerpo_else_top == -1:
							sangria_cuerpo_else_top = sangria_c_else
						elif sangria_c_else < sangria_cuerpo_else_top:
							break

						var cont_c_else := linea_c_else.strip_edges()
						var analisis_else: Dictionary = analizar_linea(cont_c_else, indice + 1)
						if not analisis_else["ok"]:
							return analisis_else

						cuerpo_else.append(_crear_instruccion_comando(indice + 1, cont_c_else, analisis_else))
						indice += 1

					if cuerpo_else.is_empty():
						return _error_de_linea(
							else_numero,
							else_contenido,
							"El bloque else necesita al menos una instrucción con sangría."
						)

			var ins_if: Dictionary = {
				"tipo": "if",
				"numero": numero_linea,
				"contenido": contenido,
				"condition": resultado_if["condition"],
				"inverted": resultado_if["inverted"],
				"cuerpo": cuerpo_if,
				"loop_iteration": 0
			}
			if not cuerpo_else.is_empty():
				ins_if["cuerpo_else"] = cuerpo_else
				ins_if["else_numero"] = else_numero
				ins_if["else_contenido"] = else_contenido

			instrucciones.append(ins_if)
			continue

		if contenido_lower.begins_with("else"):
			return _error_de_linea(
				numero_linea,
				contenido,
				"La instrucción 'else:' no tiene un 'if' previo correspondiente."
			)

		if contenido_lower.begins_with("for "):
			var resultado_for: Dictionary = _analizar_for(
				contenido,
				numero_linea
			)

			if not resultado_for["ok"]:
				return resultado_for

			var range_var: String = str(resultado_for.get("range_var", ""))
			var repeticiones: int = int(resultado_for.get("repeticiones", 0))

			if resultado_for.get("tipo_for") == "lista":
				if resultado_for.has("list_var"):
					var l_var: String = resultado_for["list_var"]
					if not variables_compile_env.has(l_var):
						return _error_de_linea(
							numero_linea,
							contenido,
							"La lista '" + l_var + "' no ha sido definida antes de su uso."
						)
			elif not range_var.is_empty():
				var res_range := _evaluar_expresion(range_var, variables_compile_env, {})
				if res_range.get("ok", false):
					repeticiones = int(res_range["val"])
				else:
					return _error_de_linea(
						numero_linea,
						contenido,
						"La variable '" + range_var + "' no ha sido definida antes de su uso en range()."
					)
				var validacion := _validar_repeticiones_for(repeticiones, contenido, numero_linea)
				if not validacion["ok"]:
					return validacion

			var sangria_for := _contar_espacios_sangria(linea_original)
			var cuerpo_for: Array = []
			indice += 1

			while indice < lineas.size():
				var linea_cuerpo: String = lineas[indice]

				if linea_cuerpo.strip_edges().is_empty() or linea_cuerpo.strip_edges().begins_with("#"):
					indice += 1
					continue

				var sangria_cuerpo := _contar_espacios_sangria(linea_cuerpo)
				if sangria_cuerpo <= sangria_for:
					break

				var contenido_cuerpo := linea_cuerpo.strip_edges()
				var cont_cuerpo_lower := contenido_cuerpo.to_lower()

				if cont_cuerpo_lower.begins_with("if "):
					var num_linea_if := indice + 1
					var res_if_anidado := _analizar_if(contenido_cuerpo, num_linea_if)
					if not res_if_anidado["ok"]:
						return res_if_anidado

					var sangria_if := sangria_cuerpo
					var cuerpo_if_anidado: Array = []
					var sangria_cuerpo_if_for := -1
					indice += 1

					while indice < lineas.size():
						var linea_sub := lineas[indice]
						if linea_sub.strip_edges().is_empty() or linea_sub.strip_edges().begins_with("#"):
							indice += 1
							continue

						var sangria_sub := _contar_espacios_sangria(linea_sub)
						if sangria_sub <= sangria_if:
							break

						if sangria_cuerpo_if_for == -1:
							sangria_cuerpo_if_for = sangria_sub
						elif sangria_sub < sangria_cuerpo_if_for:
							break

						var cont_sub := linea_sub.strip_edges()
						var analisis_sub := analizar_linea(cont_sub, indice + 1)
						if not analisis_sub["ok"]:
							return analisis_sub

						cuerpo_if_anidado.append(_crear_instruccion_comando(indice + 1, cont_sub, analisis_sub))
						indice += 1

					if cuerpo_if_anidado.is_empty():
						return _error_de_linea(
							num_linea_if,
							contenido_cuerpo,
							"El condicional if necesita al menos una instrucción con sangría."
						)

					cuerpo_for.append({
						"tipo": "if",
						"numero": num_linea_if,
						"contenido": contenido_cuerpo,
						"condition": res_if_anidado["condition"],
						"inverted": res_if_anidado["inverted"],
						"cuerpo": cuerpo_if_anidado
					})
					continue

				var analisis_for: Dictionary = analizar_linea(
					contenido_cuerpo,
					indice + 1
				)

				if not analisis_for["ok"]:
					return analisis_for

				cuerpo_for.append(_crear_instruccion_comando(indice + 1, contenido_cuerpo, analisis_for))
				indice += 1

			if cuerpo_for.is_empty():
				return _error_de_linea(
					numero_linea,
					contenido,
					"El bucle necesita al menos una instrucción con sangría."
				)

			if resultado_for.get("tipo_for") == "lista":
				var loop_v: String = resultado_for.get("loop_var", "")
				var lista_elem: Array = []
				if resultado_for.has("list_var"):
					var lv: String = resultado_for["list_var"]
					if variables_compile_env.has(lv) and variables_compile_env[lv] is Array:
						lista_elem = variables_compile_env[lv]
				else:
					lista_elem = resultado_for.get("list_literal", [])

				for it_idx in range(lista_elem.size()):
					var item_val = lista_elem[it_idx]
					for instruccion in cuerpo_for:
						var copia: Dictionary = instruccion.duplicate(true)
						copia["loop_iteration"] = it_idx + 1
						copia["loop_var"] = loop_v
						copia["loop_val"] = item_val
						instrucciones.append(copia)
			else:
				for iteracion in range(repeticiones):
					for instruccion in cuerpo_for:
						var copia: Dictionary = instruccion.duplicate(true)
						copia["loop_iteration"] = iteracion + 1
						instrucciones.append(copia)

			continue

		if contenido_lower.begins_with("while "):
			var resultado_while: Dictionary = _analizar_while(contenido, numero_linea)
			if not resultado_while["ok"]:
				return resultado_while

			var sangria_while := _contar_espacios_sangria(linea_original)
			var cuerpo_while: Array = []
			indice += 1

			while indice < lineas.size():
				var linea_cuerpo: String = lineas[indice]
				if linea_cuerpo.strip_edges().is_empty() or linea_cuerpo.strip_edges().begins_with("#"):
					indice += 1
					continue

				var sangria_cuerpo := _contar_espacios_sangria(linea_cuerpo)
				if sangria_cuerpo <= sangria_while:
					break

				var contenido_cuerpo := linea_cuerpo.strip_edges()
				var cont_cuerpo_lower := contenido_cuerpo.to_lower()

				if cont_cuerpo_lower.begins_with("if "):
					var num_linea_if := indice + 1
					var res_if_anidado := _analizar_if(contenido_cuerpo, num_linea_if)
					if not res_if_anidado["ok"]:
						return res_if_anidado

					var sangria_if := sangria_cuerpo
					var cuerpo_if_anidado: Array = []
					var sangria_cuerpo_if := -1
					indice += 1

					while indice < lineas.size():
						var linea_sub := lineas[indice]
						if linea_sub.strip_edges().is_empty() or linea_sub.strip_edges().begins_with("#"):
							indice += 1
							continue

						var sangria_sub := _contar_espacios_sangria(linea_sub)
						if sangria_sub <= sangria_if:
							break

						if sangria_cuerpo_if == -1:
							sangria_cuerpo_if = sangria_sub
						elif sangria_sub < sangria_cuerpo_if:
							break

						var cont_sub := linea_sub.strip_edges()
						var analisis_sub := analizar_linea(cont_sub, indice + 1)
						if not analisis_sub["ok"]:
							return analisis_sub

						cuerpo_if_anidado.append(_crear_instruccion_comando(indice + 1, cont_sub, analisis_sub))
						indice += 1

					if cuerpo_if_anidado.is_empty():
						return _error_de_linea(
							num_linea_if,
							contenido_cuerpo,
							"El condicional if necesita al menos una instrucción con sangría."
						)

					var cuerpo_else_anidado: Array = []
					var else_num_anidado: int = 0
					var else_cont_anidado: String = ""

					var idx_la_w := indice
					while idx_la_w < lineas.size():
						var l_la_w := lineas[idx_la_w]
						if l_la_w.strip_edges().is_empty() or l_la_w.strip_edges().begins_with("#"):
							idx_la_w += 1
							continue
						break

					if idx_la_w < lineas.size():
						var linea_p_else_w := lineas[idx_la_w]
						var sangria_p_else_w := _contar_espacios_sangria(linea_p_else_w)
						var cont_p_else_w := linea_p_else_w.strip_edges()

						if cont_p_else_w.to_lower().begins_with("else"):
							if sangria_p_else_w != sangria_if:
								return _error_de_linea(
									idx_la_w + 1,
									cont_p_else_w,
									"La sangría de 'else:' debe coincidir con el 'if' correspondiente."
								)
							if cont_p_else_w.to_lower() != "else:":
								return _error_de_linea(
									idx_la_w + 1,
									cont_p_else_w,
									"Sintaxis incorrecta. Usa 'else:' con dos puntos al final."
								)

							else_num_anidado = idx_la_w + 1
							else_cont_anidado = cont_p_else_w
							indice = idx_la_w + 1
							var sangria_cuerpo_else_w := -1

							while indice < lineas.size():
								var linea_c_else_w: String = lineas[indice]
								if linea_c_else_w.strip_edges().is_empty() or linea_c_else_w.strip_edges().begins_with("#"):
									indice += 1
									continue

								var sangria_c_else_w := _contar_espacios_sangria(linea_c_else_w)
								if sangria_c_else_w <= sangria_if:
									break

								if sangria_cuerpo_else_w == -1:
									sangria_cuerpo_else_w = sangria_c_else_w
								elif sangria_c_else_w < sangria_cuerpo_else_w:
									break

								var cont_c_else_w := linea_c_else_w.strip_edges()
								var analisis_else_w: Dictionary = analizar_linea(cont_c_else_w, indice + 1)
								if not analisis_else_w["ok"]:
									return analisis_else_w

								cuerpo_else_anidado.append(_crear_instruccion_comando(indice + 1, cont_c_else_w, analisis_else_w))
								indice += 1

							if cuerpo_else_anidado.is_empty():
								return _error_de_linea(
									else_num_anidado,
									else_cont_anidado,
									"El bloque else necesita al menos una instrucción con sangría."
								)

					var ins_if_anidado: Dictionary = {
						"tipo": "if",
						"numero": num_linea_if,
						"contenido": contenido_cuerpo,
						"condition": res_if_anidado["condition"],
						"inverted": res_if_anidado["inverted"],
						"cuerpo": cuerpo_if_anidado
					}
					if not cuerpo_else_anidado.is_empty():
						ins_if_anidado["cuerpo_else"] = cuerpo_else_anidado
						ins_if_anidado["else_numero"] = else_num_anidado
						ins_if_anidado["else_contenido"] = else_cont_anidado

					cuerpo_while.append(ins_if_anidado)
					continue

				if cont_cuerpo_lower.begins_with("for "):
					var num_linea_for := indice + 1
					var res_for_anidado := _analizar_for(contenido_cuerpo, num_linea_for)
					if not res_for_anidado["ok"]:
						return res_for_anidado

					var range_var_anidado: String = str(res_for_anidado.get("range_var", ""))
					var repeticiones_anidado: int = int(res_for_anidado.get("repeticiones", 1))

					if res_for_anidado.get("tipo_for") == "lista":
						if res_for_anidado.has("list_var"):
							var lv_anidado: String = res_for_anidado["list_var"]
							if not variables_compile_env.has(lv_anidado):
								return _error_de_linea(
									num_linea_for,
									contenido_cuerpo,
									"La lista '" + lv_anidado + "' no ha sido definida antes de su uso."
								)
					elif not range_var_anidado.is_empty():
						var res_range := _evaluar_expresion(range_var_anidado, variables_compile_env, {})
						if res_range.get("ok", false):
							repeticiones_anidado = int(res_range["val"])
						else:
							return _error_de_linea(
								num_linea_for,
								contenido_cuerpo,
								"La variable '" + range_var_anidado + "' no ha sido definida antes de su uso en range()."
							)
						var validacion := _validar_repeticiones_for(repeticiones_anidado, contenido_cuerpo, num_linea_for)
						if not validacion["ok"]:
							return validacion

					var sangria_for_anidado := sangria_cuerpo
					var cuerpo_for_anidado: Array = []
					indice += 1

					while indice < lineas.size():
						var linea_sub_for := lineas[indice]
						if linea_sub_for.strip_edges().is_empty() or linea_sub_for.strip_edges().begins_with("#"):
							indice += 1
							continue
						var sangria_sub_for := _contar_espacios_sangria(linea_sub_for)
						if sangria_sub_for <= sangria_for_anidado:
							break

						var cont_sub_for := linea_sub_for.strip_edges()
						var cont_sub_for_lower := cont_sub_for.to_lower()

						if cont_sub_for_lower.begins_with("if "):
							var num_if_for := indice + 1
							var res_if_for := _analizar_if(cont_sub_for, num_if_for)
							if not res_if_for["ok"]:
								return res_if_for

							var sangria_if_for := sangria_sub_for
							var cuerpo_if_for: Array = []
							indice += 1

							while indice < lineas.size():
								var linea_if_sub := lineas[indice]
								if linea_if_sub.strip_edges().is_empty() or linea_if_sub.strip_edges().begins_with("#"):
									indice += 1
									continue
								var sangria_if_sub := _contar_espacios_sangria(linea_if_sub)
								if sangria_if_sub <= sangria_if_for:
									break

								var cont_if_sub := linea_if_sub.strip_edges()
								var analisis_if_sub := analizar_linea(cont_if_sub, indice + 1)
								if not analisis_if_sub["ok"]:
									return analisis_if_sub

								cuerpo_if_for.append(_crear_instruccion_comando(indice + 1, cont_if_sub, analisis_if_sub))
								indice += 1

							if cuerpo_if_for.is_empty():
								return _error_de_linea(
									num_if_for,
									cont_sub_for,
									"El condicional if necesita al menos una instrucción con sangría."
								)

							cuerpo_for_anidado.append({
								"tipo": "if",
								"numero": num_if_for,
								"contenido": cont_sub_for,
								"condition": res_if_for["condition"],
								"inverted": res_if_for["inverted"],
								"cuerpo": cuerpo_if_for
							})
							continue

						var analisis_cmd_for := analizar_linea(cont_sub_for, indice + 1)
						if not analisis_cmd_for["ok"]:
							return analisis_cmd_for

						cuerpo_for_anidado.append(_crear_instruccion_comando(indice + 1, cont_sub_for, analisis_cmd_for))
						indice += 1

					if cuerpo_for_anidado.is_empty():
						return _error_de_linea(
							num_linea_for,
							contenido_cuerpo,
							"El bucle for necesita al menos una instrucción con sangría."
						)

					var ins_for_anidado: Dictionary = {
						"tipo": "for",
						"tipo_for": res_for_anidado.get("tipo_for", "range"),
						"loop_var": res_for_anidado.get("loop_var", ""),
						"list_var": res_for_anidado.get("list_var", ""),
						"list_literal": res_for_anidado.get("list_literal", []),
						"numero": num_linea_for,
						"contenido": contenido_cuerpo,
						"repeticiones": repeticiones_anidado,
						"range_var": range_var_anidado,
						"cuerpo": cuerpo_for_anidado
					}
					cuerpo_while.append(ins_for_anidado)
					continue

				var analisis_cmd: Dictionary = analizar_linea(contenido_cuerpo, indice + 1)
				if not analisis_cmd["ok"]:
					return analisis_cmd

				cuerpo_while.append(_crear_instruccion_comando(indice + 1, contenido_cuerpo, analisis_cmd))
				indice += 1

			if cuerpo_while.is_empty():
				return _error_de_linea(
					numero_linea,
					contenido,
					"El bucle while necesita al menos una instrucción con sangría."
				)

			instrucciones.append({
				"tipo": "while",
				"numero": numero_linea,
				"contenido": contenido,
				"condition": resultado_while["condition"],
				"inverted": resultado_while["inverted"],
				"cuerpo": cuerpo_while,
				"loop_iteration": 0
			})
			continue

		var analisis: Dictionary = analizar_linea(
			contenido,
			numero_linea
		)

		if not analisis["ok"]:
			return analisis

		var ins_raiz := _crear_instruccion_comando(numero_linea, contenido, analisis)
		ins_raiz["loop_iteration"] = 0
		instrucciones.append(ins_raiz)

		indice += 1

	return {
		"ok": true,
		"instrucciones": instrucciones
	}

func _analizar_for(
	contenido: String,
	numero_linea: int
) -> Dictionary:
	var expresion_range := RegEx.new()
	var patron_range := "^(?i)for\\s+([A-Za-z_][A-Za-z0-9_]*)\\s+in\\s+range\\((.+)\\):$"

	if expresion_range.compile(patron_range) != OK:
		return _error_de_linea(
			numero_linea,
			contenido,
			"No se pudo preparar el analizador del bucle."
		)

	var coincidencia_range := expresion_range.search(contenido)

	if coincidencia_range != null:
		var arg_range := coincidencia_range.get_string(2).strip_edges()
		var repeticiones := 0
		var range_var := ""

		if arg_range.is_valid_int():
			repeticiones = int(arg_range)
		elif _es_identificador_valido(arg_range) or _es_expresion_valida(arg_range):
			range_var = arg_range
		else:
			return _error_de_linea(
				numero_linea,
				contenido,
				"range() debe contener un número entero o una variable válida."
			)

		if not range_var.is_empty():
			return {
				"ok": true,
				"tipo_for": "range",
				"loop_var": coincidencia_range.get_string(1),
				"repeticiones": 1,
				"range_var": range_var
			}

		var res_val := _validar_repeticiones_for(repeticiones, contenido, numero_linea)
		if res_val["ok"]:
			res_val["tipo_for"] = "range"
			res_val["loop_var"] = coincidencia_range.get_string(1)
		return res_val

	# Comprobar iteración sobre listas: for <var> in <lista_o_identificador>:
	var expresion_lista := RegEx.new()
	var patron_lista := "^(?i)for\\s+([A-Za-z_][A-Za-z0-9_]*)\\s+in\\s+(.+):$"
	if expresion_lista.compile(patron_lista) == OK:
		var coincidencia_lista := expresion_lista.search(contenido)
		if coincidencia_lista != null:
			var loop_var := coincidencia_lista.get_string(1).strip_edges()
			var iterable := coincidencia_lista.get_string(2).strip_edges()

			if not _es_identificador_valido(loop_var):
				return _error_de_linea(
					numero_linea,
					contenido,
					"'" + loop_var + "' no es un nombre de variable válido para el bucle for."
				)

			if _es_lista_valida(iterable):
				var elems := _parsear_elementos_lista(iterable)
				return {
					"ok": true,
					"tipo_for": "lista",
					"loop_var": loop_var,
					"list_literal": elems,
					"repeticiones": elems.size()
				}
			elif _es_identificador_valido(iterable):
				return {
					"ok": true,
					"tipo_for": "lista",
					"loop_var": loop_var,
					"list_var": iterable,
					"repeticiones": 1
				}
			else:
				return _error_de_linea(
					numero_linea,
					contenido,
					"El bucle for debe iterar sobre range(...) o una lista válida (ej. for x in ruta:)."
				)

	return _error_de_linea(
		numero_linea,
		contenido,
		"Usa el formato: for ciclo in range(10): o for elemento in lista:"
	)


func _validar_repeticiones_for(repeticiones: int, contenido: String, numero_linea: int) -> Dictionary:
	if repeticiones <= 0:
		return _error_de_linea(
			numero_linea,
			contenido,
			"range() debe contener un número mayor que cero."
		)

	if repeticiones > MAX_FOR_ITER:
		return _error_de_linea(
			numero_linea,
			contenido,
			"Por seguridad, el bucle no puede superar %d repeticiones." % MAX_FOR_ITER
		)

	return {
		"ok": true,
		"repeticiones": repeticiones,
		"range_var": ""
	}

func _analizar_if(contenido: String, numero_linea: int) -> Dictionary:
	if not contenido.ends_with(":"):
		return _error_de_linea(
			numero_linea,
			contenido,
			"Falta el carácter de dos puntos ':' al final del condicional if."
		)
	var condicion := contenido.substr(3, contenido.length() - 4).strip_edges()
	var invertido := false
	if condicion.begins_with("not "):
		invertido = true
		condicion = condicion.substr(4).strip_edges()
	if condicion == "spid.hay_mineral()" or condicion == "hay_mineral()":
		return {
			"ok": true,
			"condition": "spid.hay_mineral()",
			"inverted": invertido
		}
	if condicion in ["spid.hay_mineral", "hay_mineral"]:
		return _error_de_linea(
			numero_linea,
			contenido,
			"Te faltaron los paréntesis de la función: usa 'if spid.hay_mineral():'"
		)
	return _error_de_linea(
		numero_linea,
		contenido,
		"Condición no reconocida. Sensor disponible: spid.hay_mineral()"
	)

func _crear_resultado(codigo: String) -> Dictionary:
	return {
		"code": codigo,
		"success": false,
		"error_type": "",
		"error_message": "",
		"errors": [],
		"commands_used": [],
		"commands_data": [],
		"variables_defined": [],
		"variables_used": [],
		"command_count": 0,
		"movement_count": 0,
		"loop_count": 0,
		"loop_iterations": 0,
		"minerals_collected": 0,
		"minerals_transferred": 0,
		"loop_minerals_collected": 0,
		"if_evaluations": 0,
		"if_branch_taken": false,
		"else_branch_taken": false,
		"duration_seconds": 0.0,
		"objective_id": MissionService.objective_id,
		"objective_completed": false
	}


func _error_de_linea(
	numero: int,
	contenido: String,
	mensaje: String
) -> Dictionary:
	return {
		"ok": false,
		"error": {
			"type": "sintaxis",
			"line": numero,
			"content": contenido,
			"message": mensaje
		}
	}


func _finalizar(resultado: Dictionary) -> void:
	resultado["duration_seconds"] = (
		Time.get_ticks_msec() - _tiempo_inicio_msec
	) / 1000.0

	# Una misión completada en vivo ya puede haber activado la siguiente.
	if MissionService.objective_id == _objective_id_at_start:
		MissionService.evaluar_programa(resultado)
	var completed_missions := MissionService.get_completed_missions()
	var objective_is_completed := (
		(
			MissionService.objective_id == _objective_id_at_start
			and MissionService.objective_completed
		)
		or _objective_id_at_start in completed_missions
	)
	resultado["objective_id"] = _objective_id_at_start
	resultado["objective_completed"] = (
		not _objective_completed_at_start
		and objective_is_completed
	)

	ejecutando = false
	modo_paso_a_paso = false
	esperando_paso = false

	print(
		"Misión: ",
		resultado["objective_id"],
		" | Completada: ",
		resultado["objective_completed"]
	)

	ejecucion_finalizada.emit(resultado)

func _analizar_while(contenido: String, numero_linea: int) -> Dictionary:
	if not contenido.ends_with(":"):
		return _error_de_linea(
			numero_linea,
			contenido,
			"Falta el carácter de dos puntos ':' al final del bucle while."
		)

	var condicion := contenido.substr(5, contenido.length() - 6).strip_edges()
	var invertido := false

	if condicion.begins_with("not ") or condicion.begins_with("NOT "):
		invertido = true
		condicion = condicion.substr(4).strip_edges()

	var condiciones_validas := [
		"True",
		"False",
		"true",
		"false",
		"spid.hay_mineral()",
		"hay_mineral()",
		"spid.tiene_espacio()",
		"tiene_espacio()",
		"spid.en_base()",
		"en_base()"
	]
	
	if condicion in condiciones_validas:
		return {
			"ok": true,
			"condition": condicion,
			"inverted": invertido
		}

	# Validación de comparaciones de recursos (ej: spid.minerales_en_nave() < 10)
	var regex_comp := RegEx.new()
	if regex_comp.compile("^(?i)(spid\\.)?(minerales_en_nave|minerales_en_rover|minerales)\\(\\)\\s*(<|<=|>|>=|==|!=)\\s*(\\d+)$") == OK:
		var match := regex_comp.search(condicion)
		if match != null:
			return {
				"ok": true,
				"condition": condicion,
				"inverted": invertido
			}

	var regex_sin_parentesis := RegEx.new()
	if regex_sin_parentesis.compile("^(?i)(spid\\.)?(minerales_en_nave|minerales_en_rover|minerales)\\s*(<|<=|>|>=|==|!=)") == OK:
		if regex_sin_parentesis.search(condicion) != null:
			return _error_de_linea(
				numero_linea,
				contenido,
				"Te faltaron los paréntesis '()' en la función: usa 'spid.minerales_en_nave() < ...'"
			)

	if condicion in ["spid.hay_mineral", "hay_mineral", "spid.tiene_espacio", "tiene_espacio", "spid.en_base", "en_base", "spid.minerales_en_nave", "minerales_en_nave", "spid.minerales_en_rover", "minerales_en_rover"]:
		return _error_de_linea(
			numero_linea,
			contenido,
			"Te faltaron los paréntesis '()' en la condición: usa '" + condicion + "()'"
		)

	return _error_de_linea(
		numero_linea,
		contenido,
		"Condición no válida para while. Puedes usar True, False, " +
		"sensores como spid.tiene_espacio(), o comparaciones como " +
		"spid.minerales_en_nave() < 10."
	)
