extends SceneTree
## Sustituye la apertura del navegador; no hace peticiones ni lee credenciales.

class AuthSinNavegador:
	extends RefCounted
	var urls: Array[String] = []
	var resultado: Error = OK

	func _abrir_registro_web(url: String) -> Error:
		urls.append(url)
		return resultado

func _initialize() -> void:
	call_deferred("comprobar")

func comprobar() -> void:
	var navegador := AuthSinNavegador.new()
	var auth = load("res://script/auth.gd").new()
	auth._abrir_navegador = navegador._abrir_registro_web
	var status := Label.new()
	auth.status_label = status
	# Sin inputs: registrarse no debe exigir ni leer credenciales del juego.
	auth._on_registrarse_pressed()
	var passed: bool = auth.WEB_SIGNUP_URL == "https://educode-web-git-feat-spidocode-web-auth-educode3.vercel.app/registro"
	passed = passed and navegador.urls == [auth.WEB_SIGNUP_URL]
	passed = passed and status.text.contains("Completa el registro en el navegador")
	passed = passed and root.get_node("Supabase").pending_operation.is_empty()
	# La URL exacta impide añadir query strings o fragmentos con credenciales.
	navegador.resultado = ERR_CANT_OPEN
	auth._on_registrarse_pressed()
	passed = passed and navegador.urls.size() == 2
	passed = passed and navegador.urls[1] == auth.WEB_SIGNUP_URL
	passed = passed and status.text == "No se pudo abrir el navegador. Inténtalo nuevamente."
	passed = passed and root.get_node("Supabase").pending_operation.is_empty()
	auth.free()
	status.free()
	if passed:
		print("PASS: URL Preview, éxito y error del botón, sin navegador, credenciales ni petición Supabase.")
	else:
		push_error("FAIL: URL, resultado del botón o aislamiento del registro web incorrectos.")
	quit(0 if passed else 1)
