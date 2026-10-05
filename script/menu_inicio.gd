extends Control

# Ruta hacia la escena del juego donde está el asteroide y el Spid
const ESCENA_MUNDO = "res://escenas/mundo.tscn"
const ESCENA_AUTH = "res://escenas/auth.tscn"
const ESCENA_PERFIL = "res://escenas/perfil.tscn"
@onready var boton_login: Button = $PanelPerfil/HBoxContainer/ButtonLogin
@onready var panel_perfil: PanelContainer = $PanelPerfil
@onready var boton_jugar: Button = $PanelMenu/ContenedorPrincipal/BotonJugar
@onready var fondo: TextureRect = $TextureRect
@onready var dropdown: PanelContainer = $ProfileDropdown
@onready var boton_ver_perfil: Button = $ProfileDropdown/Options/VerPerfil
@onready var boton_cerrar_sesion: Button = $ProfileDropdown/Options/CerrarSesion
@onready var boton_configuracion: Button = $PanelMenu/ContenedorPrincipal/BotonConfiguracion
var dropdown_abierto := false
var cargando_progreso := false

func _ready() -> void:
	_animar_estrellas()
	boton_login.mouse_entered.connect(_animar_hover.bind(true))
	boton_login.mouse_exited.connect(_animar_hover.bind(false))
	boton_ver_perfil.mouse_entered.connect(_animar_opcion_hover.bind(boton_ver_perfil, true))
	boton_ver_perfil.mouse_exited.connect(_animar_opcion_hover.bind(boton_ver_perfil, false))
	boton_cerrar_sesion.mouse_entered.connect(_animar_opcion_hover.bind(boton_cerrar_sesion, true))
	boton_cerrar_sesion.mouse_exited.connect(_animar_opcion_hover.bind(boton_cerrar_sesion, false))
	boton_configuracion.pressed.connect(_on_boton_configuracion_pressed)
	ProgressService.progress_loaded.connect(_on_progress_loaded)
	ProgressService.progress_load_failed.connect(_on_progress_load_failed)
	actualizar_estado_autenticacion()

func _animar_estrellas() -> void:
	var frames: Array[Texture2D] = []
	for indice in range(36):
		var textura := load("res://Fondos/estrellas_frames/frame_%02d.png" % indice) as Texture2D
		if textura:
			frames.append(textura)
	if frames.is_empty():
		return
	var indice := 0
	while is_inside_tree():
		fondo.texture = frames[indice]
		indice = (indice + 1) % frames.size()
		await get_tree().create_timer(0.055).timeout

func actualizar_estado_autenticacion() -> void:
	cerrar_dropdown()
	if Supabase.is_authenticated():
		boton_login.text = "Perfil ▼"
		boton_jugar.text = "Continuar Partida"
	else:
		boton_login.text = "Iniciar Sesion"
		boton_jugar.text = "Nueva Partida"

func _on_boton_login_pressed() -> void:
	if not Supabase.is_authenticated():
		get_tree().change_scene_to_file(ESCENA_AUTH)
		return
	if dropdown_abierto:
		cerrar_dropdown()
	else:
		abrir_dropdown()

func abrir_dropdown() -> void:
	dropdown_abierto = true
	dropdown.position = Vector2(
		panel_perfil.position.x,
		panel_perfil.position.y + panel_perfil.size.y + 12.0
	)
	dropdown.size.x = panel_perfil.size.x
	dropdown.visible = true
	dropdown.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(dropdown, "modulate:a", 1.0, 0.18)

func cerrar_dropdown() -> void:
	if not dropdown_abierto and not dropdown.visible:
		return
	dropdown_abierto = false
	var tween := create_tween()
	tween.tween_property(dropdown, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(dropdown.hide)

func _animar_hover(entrando: bool) -> void:
	var tween := create_tween()
	tween.tween_property(boton_login, "scale", Vector2.ONE * (1.03 if entrando else 1.0), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _animar_opcion_hover(boton: Button, entrando: bool) -> void:
	var tween := create_tween()
	tween.tween_property(boton, "modulate", Color(1.12, 1.12, 1.12) if entrando else Color.WHITE, 0.14)

func _on_ver_perfil_pressed() -> void:
	cerrar_dropdown()
	get_tree().change_scene_to_file(ESCENA_PERFIL)

func _on_cerrar_sesion_pressed() -> void:
	cerrar_dropdown()
	Supabase.sign_out()
	actualizar_estado_autenticacion()

func _on_boton_jugar_pressed() -> void:
	if Supabase.is_authenticated():
		_continuar_partida_autenticada()
	else:
		_iniciar_partida_invitado()

func _iniciar_partida_invitado() -> void:
	_abrir_mundo()

func _continuar_partida_autenticada() -> void:
	if cargando_progreso:
		return
	cargando_progreso = true
	boton_jugar.disabled = true
	if not ProgressService.load_progress():
		cargando_progreso = false
		boton_jugar.disabled = false

func _on_progress_loaded(_progress: Dictionary) -> void:
	cargando_progreso = false
	boton_jugar.disabled = false
	_abrir_mundo()

func _on_progress_load_failed(message: String) -> void:
	cargando_progreso = false
	boton_jugar.disabled = false
	push_error("No se pudo cargar el progreso: " + message)

func _abrir_mundo() -> void:
	if ResourceLoader.exists(ESCENA_MUNDO):
		get_tree().change_scene_to_file(ESCENA_MUNDO)
	else:
		print("No se encontró la escena en la ruta: ", ESCENA_MUNDO)

# Se ejecuta al hacer clic en "Salir"
func _on_boton_salir_pressed() -> void:
	get_tree().quit()

func _on_boton_configuracion_pressed() -> void:
	var MenuConfiguracion = load("res://script/menu_configuracion.gd")
	var config_menu = MenuConfiguracion.new()
	add_child(config_menu)
	var contenedor = $PanelMenu/ContenedorPrincipal
	contenedor.hide()
	config_menu.tree_exited.connect(func(): contenedor.show())
