extends Control

@onready var panel: PanelContainer = $PanelTransmision
@onready var mensaje: RichTextLabel = $PanelTransmision/Margen/Contenido/Cuerpo/Mensaje
@onready var estado: Label = $PanelTransmision/Margen/Contenido/Cabecera/Estado
@onready var boton_sistema: Button = get_node_or_null("../BotonSistemaADA")

var posicion_visible: Vector2
var posicion_oculta: Vector2
var version_mensaje: int = 0
var tween_actual: Tween
var cerrado_por_jugador: bool = false
var mensajes_bloqueados: bool = false
var mensaje_pendiente: Dictionary = {}


func _ready() -> void:
	z_index = 100
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	posicion_visible = panel.position
	posicion_oculta = posicion_visible + Vector2(0.0, -18.0)
	panel.position = posicion_oculta
	panel.modulate.a = 0.0
	panel.hide()
	_actualizar_boton(false)


func mostrar_mensaje(texto: String, tipo: String = "objetivo", duracion: float = 7.0) -> void:
	if mensajes_bloqueados:
		mensaje_pendiente = {
			"texto": texto,
			"tipo": tipo,
			"duracion": duracion
		}
		return

	version_mensaje += 1
	var mi_version := version_mensaje

	if tween_actual != null and tween_actual.is_valid():
		tween_actual.kill()

	estado.text = "● TRANSMISION"
	if tipo == "error":
		estado.text = "● ALERTA"
	elif tipo == "progreso":
		estado.text = "● EN CURSO"
	elif tipo == "completado":
		estado.text = "● MISION CUMPLIDA"

	mensaje.text = texto
	mensaje.visible_characters = 0
	if cerrado_por_jugador:
		mensaje.visible_characters = -1
		return

	panel.show()
	_actualizar_boton(true)

	tween_actual = create_tween()
	tween_actual.set_parallel(true)
	tween_actual.tween_property(panel, "position", posicion_visible, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_actual.tween_property(panel, "modulate:a", 1.0, 0.2)
	await tween_actual.finished

	for cantidad in range(1, texto.length() + 1):
		if mi_version != version_mensaje:
			return
		mensaje.visible_characters = cantidad
		await get_tree().create_timer(0.018).timeout

	await get_tree().create_timer(duracion).timeout
	if mi_version == version_mensaje:
		ocultar()


func bloquear_mensajes() -> void:
	mensajes_bloqueados = true
	version_mensaje += 1
	if tween_actual != null and tween_actual.is_valid():
		tween_actual.kill()
	panel.hide()
	panel.position = posicion_oculta
	panel.modulate.a = 0.0
	_actualizar_boton(false)


func desbloquear_mensajes() -> void:
	mensajes_bloqueados = false
	if mensaje_pendiente.is_empty():
		return
	var pendiente := mensaje_pendiente.duplicate()
	mensaje_pendiente.clear()
	call_deferred(
		"mostrar_mensaje",
		str(pendiente.get("texto", "")),
		str(pendiente.get("tipo", "objetivo")),
		float(pendiente.get("duracion", 7.0))
	)


func establecer_panel_abierto(abierto: bool) -> void:
	cerrado_por_jugador = not abierto
	version_mensaje += 1
	if tween_actual != null and tween_actual.is_valid():
		tween_actual.kill()

	if abierto:
		panel.show()
		mensaje.visible_characters = -1
		tween_actual = create_tween()
		tween_actual.set_parallel(true)
		tween_actual.tween_property(panel, "position", posicion_visible, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_actual.tween_property(panel, "modulate:a", 1.0, 0.18)
	else:
		ocultar()


func ocultar() -> void:
	version_mensaje += 1
	if tween_actual != null and tween_actual.is_valid():
		tween_actual.kill()
	tween_actual = create_tween()
	tween_actual.set_parallel(true)
	tween_actual.tween_property(panel, "position", posicion_oculta, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween_actual.tween_property(panel, "modulate:a", 0.0, 0.22)
	await tween_actual.finished
	panel.hide()
	_actualizar_boton(false)


func _actualizar_boton(abierto: bool) -> void:
	if boton_sistema == null:
		return
	boton_sistema.set_pressed_no_signal(abierto)
	boton_sistema.text = "SISTEMA ADA  ▲" if abierto else "SISTEMA ADA  ▼"
