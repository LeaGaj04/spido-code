extends SceneTree
## Ejecutar con Godot --headless --path . --script tests/test_senales_en_vivo.gd

class AdaPrueba extends Node:
	var mensajes: Array = []
	func mostrar_mensaje(texto: String, tipo: String = "objetivo", _duracion: float = 7.0) -> void:
		mensajes.append({"texto": texto, "tipo": tipo})

var executor: Node
var misiones: Node
var completadas := 0
var transferencias := 0

func _initialize() -> void:
	call_deferred("comprobar")

func comprobar() -> void:
	executor = root.get_node("CodeExecutor")
	misiones = root.get_node("MissionService")
	var sintaxis := root.get_node("GestorSintaxis")
	for palabra in ["while", "if", "else"]:
		sintaxis.desbloquear_sintaxis(palabra)
	misiones.completed_missions.clear()
	misiones.iniciar_senales_inciertas()
	var ui = load("res://tests/fixtures/interfaz_sin_guardado.gd").new()
	var ada := AdaPrueba.new()
	var estado := Label.new()
	ui.transmision_ada = ada
	ui.label_estado_mision = estado
	ui._interfaz_inicializada = true
	misiones.mision_completada.connect(ui._on_mision_completada)
	misiones.objetivo_actualizado.connect(ui._on_objetivo_actualizado)
	misiones.mision_completada.connect(_completada)

	# No avisar ni completar ante evidencia parcial o fallida.
	var parcial := {
		"objective_id": "senales_inciertas", "code": "while True:",
		"if_evaluations": 2, "minerals_collected": 1,
		"minerals_transferred": 1, "errors": []
	}
	for campo in ["if_evaluations", "minerals_collected", "minerals_transferred"]:
		var incompleto := parcial.duplicate(true)
		incompleto[campo] = 0
		misiones.evaluar_progreso_programa(incompleto)
	var fallido := parcial.duplicate(true)
	fallido["errors"] = [{"message": "Transferencia fallida"}]
	misiones.evaluar_progreso_programa(fallido)
	assert(completadas == 0 and ada.mensajes.is_empty())

	# Patrulla infinita: cumplimiento tras la primera transferencia, sigue hasta la segunda.
	var codigo := "while True:\n    if spid.hay_mineral():\n        spid.minar()\n    if spid.hay_mineral():\n        spid.minar()\n    spid.transferir()"
	var resultado: Dictionary = await executor.ejecutar_codigo(codigo, _comando, _condicion)
	assert(transferencias == 2 and completadas == 1)
	assert(resultado["objective_completed"])
	assert(misiones.objective_id == "comprar_mapa_3x3")
	assert(ada.mensajes.size() == 1 and ada.mensajes[0]["tipo"] == "completado")

	# La alternativa finita IF / ELSE sigue completándose una sola vez.
	misiones.completed_missions.clear()
	misiones.iniciar_senales_inciertas()
	ada.mensajes.clear()
	transferencias = 0
	completadas = 0
	codigo = "if spid.hay_mineral():\n    spid.minar()\nelse:\n    spid.este()\n    spid.minar()\nspid.transferir()"
	resultado = await executor.ejecutar_codigo(codigo, _comando, _condicion)
	assert(completadas == 1 and resultado["objective_completed"])
	assert(ada.mensajes.size() == 1 and ada.mensajes[0]["tipo"] == "completado")
	print("OK: cumplimiento en vivo, patrulla continúa, aviso único conservado, IF/ELSE y requisitos incompletos verificados.")
	ui.free()
	ada.free()
	estado.free()
	quit()

func _completada(id: String) -> void:
	assert(id == "senales_inciertas")
	assert(executor.ejecutando and not executor.detener_solicitado)
	completadas += 1

func _comando(comando: String, _pasos: int) -> Dictionary:
	if comando == "transferir":
		transferencias += 1
		if transferencias == 2:
			assert(completadas == 1)
			executor.detener_ejecucion()
	return {"ok": true, "minerals_collected": 1 if comando == "minar" else 0, "minerals_transferred": 1 if comando == "transferir" else 0}

func _condicion(_expresion: String) -> bool:
	return true
