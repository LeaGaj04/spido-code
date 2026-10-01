extends Node

const SAMPLE_RATE := 22050
const BUS := "Master"

var _click: AudioStream
var _hover: AudioStream
var _ambient: AudioStream
var _ambient_player: AudioStreamPlayer
var _connected_buttons: Dictionary = {}

func _ready() -> void:
	_click = _crear_sonido_click()
	_hover = _crear_sonido_hover()
	_ambient = _crear_sonido_ambiente()
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.name = "AmbienteEspacial"
	_ambient_player.stream = _ambient
	_ambient_player.volume_db = -20.0
	add_child(_ambient_player)
	get_tree().node_added.connect(_on_node_added)
	_conectar_botones(get_tree().root)
	_actualizar_ambiente()
	get_tree().scene_changed.connect(_actualizar_ambiente)

func _on_node_added(node: Node) -> void:
	if node is Button:
		_conectar_boton(node)

func _conectar_botones(node: Node) -> void:
	if node is Button:
		_conectar_boton(node)
	for child in node.get_children():
		_conectar_botones(child)

func _conectar_boton(boton: Button) -> void:
	if _connected_buttons.has(boton):
		return
	_connected_buttons[boton] = true
	boton.pressed.connect(_reproducir_click)
	boton.mouse_entered.connect(_reproducir_hover)

func _reproducir_click() -> void:
	_reproducir_efecto(_click, -8.0)

func _reproducir_hover() -> void:
	_reproducir_efecto(_hover, -17.0)

func _reproducir_efecto(sonido: AudioStream, volumen: float) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = sonido
	player.volume_db = volumen
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _actualizar_ambiente() -> void:
	if _ambient_player == null:
		return
	var en_mundo := get_tree().current_scene != null and get_tree().current_scene.name == "Mundo"
	if en_mundo and not _ambient_player.playing:
		_ambient_player.play()
	elif not en_mundo and _ambient_player.playing:
		_ambient_player.stop()

func _crear_sonido_click() -> AudioStreamWAV:
	var duracion := 0.095
	var datos := _crear_pcm(duracion, func(t: float) -> float:
		var ataque := minf(t * 180.0, 1.0)
		var envolvente := exp(-38.0 * t) * ataque
		var tono := sin(TAU * (300.0 - 55.0 * t / duracion) * t) * 0.72
		var cuerpo := sin(TAU * 600.0 * t) * 0.20
		return (tono + cuerpo) * envolvente
	)
	return _crear_wav(datos, false)

func _crear_sonido_hover() -> AudioStreamWAV:
	var duracion := 0.055
	var datos := _crear_pcm(duracion, func(t: float) -> float:
		return sin(TAU * 520.0 * t) * exp(-55.0 * t) * 0.16
	)
	return _crear_wav(datos, false)

func _crear_sonido_ambiente() -> AudioStreamWAV:
	var duracion := 16.0
	var datos := _crear_pcm(duracion, func(t: float) -> float:
		var compas := fmod(t, 8.0)
		var nota_base := 261.63 if compas < 2.0 else (196.0 if compas < 4.0 else (220.0 if compas < 6.0 else 174.61))
		var pulso := 0.5 + 0.5 * sin(TAU * t / 8.0)
		var acorde := sin(TAU * nota_base * t) * 0.10 + sin(TAU * nota_base * 1.25 * t) * 0.045 + sin(TAU * nota_base * 1.5 * t) * 0.025
		var momento := fmod(t, 0.5)
		var frase := sin(TAU * (nota_base * 2.0) * momento) * exp(-7.0 * momento) * 0.045
		return (acorde + frase) * (0.65 + pulso * 0.18)
	)
	return _crear_wav(datos, true)

func _crear_pcm(duracion: float, generador: Callable) -> PackedByteArray:
	var muestras := int(SAMPLE_RATE * duracion)
	var datos := PackedByteArray()
	datos.resize(muestras * 2)
	for i in muestras:
		var valor := clampf(float(generador.call(float(i) / SAMPLE_RATE)), -1.0, 1.0)
		datos.encode_s16(i * 2, int(valor * 32767.0))
	return datos

func _crear_wav(datos: PackedByteArray, loop: bool) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = datos
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = datos.size() / 2
	return wav
