extends Control

const ESCENA_MENU := "res://escenas/menu_inicio.tscn"
# Preview de registro validado manualmente; no adjuntar credenciales ni tokens.
const WEB_SIGNUP_URL := "https://educode-web-git-feat-spidocode-web-auth-educode3.vercel.app/registro"
var _abrir_navegador: Callable = OS.shell_open
@onready var email_input: LineEdit = $Panel/Contenedor/Email
@onready var password_input: LineEdit = $Panel/Contenedor/Password
@onready var recovery_button: Button = $Panel/Contenedor/RecuperarPassword
@onready var login_button: Button = $Panel/Contenedor/IniciarSesion
@onready var signup_button: Button = $Panel/Contenedor/Registrarse
@onready var status_label: Label = $Panel/Contenedor/Mensaje
@onready var fondo: TextureRect = $Fondo

func _ready() -> void:
	_animar_estrellas()
	Supabase.login_succeeded.connect(_on_login_succeeded)
	Supabase.login_failed.connect(_on_login_failed)
	Supabase.signup_succeeded.connect(_on_signup_succeeded)
	Supabase.signup_failed.connect(_on_signup_failed)
	Supabase.password_recovery_sent.connect(_on_password_recovery_sent)
	Supabase.password_recovery_failed.connect(_on_password_recovery_failed)
	var panel := $Panel
	panel.modulate.a = 0.0
	panel.position.y += 12.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.25)
	tween.tween_property(panel, "position:y", panel.position.y - 12.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

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

func _on_iniciar_sesion_pressed() -> void:
	if not _validar_campos():
		return
	_set_request_state(true, "Iniciando sesión...")
	if not Supabase.sign_in(email_input.text.strip_edges(), password_input.text):
		_set_request_state(false, "Ya hay una operación en curso.")

func _on_registrarse_pressed() -> void:
	if WEB_SIGNUP_URL.is_empty() or not WEB_SIGNUP_URL.begins_with("https://"):
		status_label.text = "El registro web aún no está disponible. Si ya tienes cuenta, inicia sesión aquí."
		return
	var error: Error = _abrir_navegador.call(WEB_SIGNUP_URL)
	if error != OK:
		status_label.text = "No se pudo abrir el navegador. Inténtalo nuevamente."
		return
	status_label.text = "Completa el registro en el navegador y confirma tu correo si se solicita. Después vuelve al juego e inicia sesión."

func _on_recuperar_password_pressed() -> void:
	var email := email_input.text.strip_edges()
	if email.is_empty():
		status_label.text = "Escribe tu correo electrónico."
		return
	_set_request_state(true, "Enviando correo de recuperación...")
	if not Supabase.send_password_recovery(email):
		_set_request_state(false, "Ya hay una operación en curso.")

func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file(ESCENA_MENU)

func _validar_campos() -> bool:
	if email_input.text.strip_edges().is_empty():
		status_label.text = "Escribe tu correo electrónico."
		return false
	if password_input.text.is_empty():
		status_label.text = "Escribe tu contraseña."
		return false
	return true

func _set_request_state(in_progress: bool, message: String) -> void:
	login_button.disabled = in_progress
	signup_button.disabled = in_progress
	recovery_button.disabled = in_progress
	status_label.text = message

func _on_login_succeeded(_user: Dictionary) -> void:
	_set_request_state(false, "Sesión iniciada.")
	get_tree().change_scene_to_file(ESCENA_MENU)

func _on_login_failed(message: String) -> void:
	_set_request_state(false, "No se pudo iniciar sesión: " + message)

func _on_signup_succeeded(_user: Dictionary, has_session: bool) -> void:
	_set_request_state(false, "Cuenta creada. Revisa tu correo para confirmar tu cuenta." if not has_session else "Cuenta creada.")
	if has_session:
		get_tree().change_scene_to_file(ESCENA_MENU)

func _on_signup_failed(message: String) -> void:
	_set_request_state(false, "No se pudo registrar la cuenta: " + message)

func _on_password_recovery_sent() -> void:
	_set_request_state(false, "Si el correo está registrado, recibirás un enlace para restablecer tu contraseña.")

func _on_password_recovery_failed(message: String) -> void:
	_set_request_state(false, "No se pudo enviar el correo de recuperación: " + message)
