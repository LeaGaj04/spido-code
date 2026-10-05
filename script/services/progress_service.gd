extends Node

signal progress_loaded(progress: Dictionary)
signal progress_load_failed(message: String)
signal progress_saved(progress: Dictionary)
signal progress_save_failed(message: String)

const RESOURCE := "player_progress"
const SELECT_FIELDS := (
	"user_id," +
	"minerals_ship," +
	"minerals_spid," +
	"map_tier," +
	"unlocked_syntax," +
	"current_mission_id," +
	"completed_missions," +
	"unlocked_knowledge," +
	"hardware_upgrades," +
	"created_at," +
	"updated_at"
)
const SAVE_DEBOUNCE_SECONDS := 0.75
const SINTAXIS_CONOCIDAS := ["for", "while", "if", "else", "in range"]
const CONOCIMIENTOS_CONOCIDOS := [
	"objeto",
	"metodo",
	"secuencia",
	"parametro",
	"condicion_not",
	"bucle_for",
	"condicional_if",
	"bucle_while",
	"variable",
	"funcion"
]

const MEJORAS_HARDWARE_CONOCIDAS := [
	"drill_speed",
	"cargo_capacity",
	"movement_speed",
	"scanner"
]

var current_progress: Dictionary = {}
var http_request: HTTPRequest
var save_timer: Timer
var loading := false
var pending_operation := ""
var pending_user_id := ""
var pending_save_progress: Dictionary = {}
var save_in_flight_progress: Dictionary = {}
var save_debounce_elapsed := false

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	save_timer = Timer.new()
	save_timer.one_shot = true
	save_timer.wait_time = SAVE_DEBOUNCE_SECONDS
	add_child(save_timer)
	save_timer.timeout.connect(_on_save_debounce_timeout)
	Supabase.signed_out.connect(clear_progress)

func load_progress() -> bool:
	if pending_operation != "":
		return false
	if not Supabase.is_authenticated():
		_fail_load("Debes iniciar sesión para cargar progreso remoto.")
		return false
	pending_user_id = Supabase.get_current_user_id()
	if pending_user_id.is_empty():
		_fail_load("No se pudo identificar al usuario autenticado.")
		return false
	loading = true
	pending_operation = "select"
	var query := "?user_id=eq." + pending_user_id.uri_encode() + "&select=" + SELECT_FIELDS + "&limit=1"
	var error := http_request.request(Supabase.get_rest_url(RESOURCE) + query, Supabase.get_authenticated_headers(), HTTPClient.METHOD_GET)
	if error != OK:
		_fail_load("No se pudo iniciar la carga del progreso.")
		return false
	return true


# Solicita un PATCH coalescido. Para invitados es un no-op seguro y no genera
# ninguna petición a Supabase.
func save_progress(progress: Dictionary) -> bool:
	var normalizado := _normalizar_progreso(progress)
	if not normalizado.is_empty():
		current_progress.merge(normalizado, true)

	if not Supabase.is_authenticated():
		return false
	if normalizado.is_empty():
		_fail_save("El estado de progreso local no es válido para guardar.")
		return false
	if not has_loaded_progress() and not loading:
		_fail_save("No se puede guardar sin un progreso remoto cargado.")
		return false
	pending_save_progress = normalizado
	save_debounce_elapsed = false
	save_timer.start()
	return true


func has_loaded_progress() -> bool:
	return not current_progress.is_empty()

func get_current_progress() -> Dictionary:
	return current_progress.duplicate(true)

func clear_progress() -> void:
	current_progress = {}
	pending_save_progress = {}
	save_in_flight_progress = {}
	save_debounce_elapsed = false
	loading = false
	pending_operation = ""
	pending_user_id = ""
	if save_timer != null:
		save_timer.stop()


func _on_save_debounce_timeout() -> void:
	save_debounce_elapsed = true
	_try_start_save()


func _try_start_save() -> void:
	if not save_debounce_elapsed or pending_save_progress.is_empty() or pending_operation != "":
		return
	if not Supabase.is_authenticated():
		return
	var user_id := Supabase.get_current_user_id()
	if user_id.is_empty():
		_fail_save("No se pudo identificar al usuario autenticado para guardar.")
		return
	save_in_flight_progress = pending_save_progress.duplicate(true)
	pending_save_progress = {}
	pending_operation = "update"
	pending_user_id = user_id
	save_debounce_elapsed = false
	var headers := Supabase.get_authenticated_headers(PackedStringArray(["Prefer: return=representation"]))
	var endpoint := Supabase.get_rest_url(RESOURCE) + "?user_id=eq." + user_id.uri_encode() + "&select=" + SELECT_FIELDS
	var error := http_request.request(endpoint, headers, HTTPClient.METHOD_PATCH, JSON.stringify(save_in_flight_progress))
	if error != OK:
		_handle_request_failure("update", "No se pudo iniciar el guardado del progreso.")


func _create_initial_progress() -> void:
	pending_operation = "insert"
	var headers := Supabase.get_authenticated_headers(PackedStringArray(["Prefer: return=representation"]))
	var error := http_request.request(Supabase.get_rest_url(RESOURCE) + "?select=" + SELECT_FIELDS, headers, HTTPClient.METHOD_POST, JSON.stringify({"user_id": pending_user_id}))
	if error != OK:
		_fail_load("No se pudo crear el progreso inicial.")


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var operation := pending_operation
	if not Supabase.is_authenticated() or Supabase.get_current_user_id() != pending_user_id:
		clear_progress()
		if operation == "update":
			_fail_save("La sesión cambió mientras se procesaba el progreso.")
		else:
			_fail_load("La sesión cambió mientras se procesaba el progreso.")
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		_handle_request_failure(operation, "Error de red al comunicarse con Supabase.")
		return
	if response_code == 401:
		_handle_request_failure(operation, "La sesión ya no es válida. Vuelve a iniciar sesión.")
		return
	if response_code == 403:
		_handle_request_failure(operation, "No tienes permiso para acceder a este progreso.")
		return
	if response_code < 200 or response_code >= 300:
		_handle_request_failure(operation, "Supabase no pudo completar la operación de progreso.")
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_ARRAY:
		_handle_request_failure(operation, "Supabase devolvió una respuesta de progreso inválida.")
		return
	if operation == "select" and data.is_empty():
		_create_initial_progress()
		return
	if data.is_empty() or typeof(data[0]) != TYPE_DICTIONARY:
		_handle_request_failure(operation, "No se recibió una fila de progreso válida.")
		return
	_handle_request_success(operation, data[0])


func _handle_request_success(operation: String, progress: Dictionary) -> void:
	loading = false
	pending_operation = ""
	pending_user_id = ""
	if operation == "update":
		save_in_flight_progress = {}
		if pending_save_progress.is_empty():
			current_progress = progress.duplicate(true)
		else:
			# Conserva los cambios locales posteriores al PATCH confirmado.
			current_progress["user_id"] = progress.get("user_id", current_progress.get("user_id", ""))
			current_progress["created_at"] = progress.get("created_at", current_progress.get("created_at", ""))
			current_progress["updated_at"] = progress.get("updated_at", current_progress.get("updated_at", ""))
		progress_saved.emit(get_current_progress())
		_try_start_save()
		return
	current_progress = progress.duplicate(true)
	progress_loaded.emit(get_current_progress())
	_try_start_save()


func _handle_request_failure(operation: String, message: String) -> void:
	loading = false
	pending_operation = ""
	pending_user_id = ""
	if operation == "update":
		if pending_save_progress.is_empty():
			pending_save_progress = save_in_flight_progress.duplicate(true)
		save_in_flight_progress = {}
		_fail_save(message)
		return
	_fail_load(message)


func _fail_load(message: String) -> void:
	loading = false
	pending_operation = ""
	pending_user_id = ""
	progress_load_failed.emit(message)


func _fail_save(message: String) -> void:
	progress_save_failed.emit(message)


func _normalizar_progreso(progress: Dictionary) -> Dictionary:
	var progreso_base: Dictionary = current_progress

	# Normalizar sintaxis desbloqueada.
	var sintaxis = progress.get(
		"unlocked_syntax",
		progreso_base.get("unlocked_syntax", {})
	)

	if typeof(sintaxis) != TYPE_DICTIONARY:
		return {}

	var sintaxis_normalizada: Dictionary = {}

	for clave in SINTAXIS_CONOCIDAS:
		sintaxis_normalizada[clave] = sintaxis.get(clave, false) == true

	# Normalizar misiones completadas.
	var misiones = progress.get(
			"completed_missions",
		progreso_base.get("completed_missions", [])
	)

	if typeof(misiones) != TYPE_ARRAY:
		return {}

	var misiones_normalizadas: Array = []

	for mision in misiones:
		if (
			typeof(mision) == TYPE_STRING
			and not mision.is_empty()
			and mision not in misiones_normalizadas
		):
			misiones_normalizadas.append(mision)

	# Normalizar conocimientos desbloqueados.
	var conocimientos = progress.get(
		"unlocked_knowledge",
		progreso_base.get(
			"unlocked_knowledge",
			["objeto", "metodo"]
		)
	)

	if typeof(conocimientos) != TYPE_ARRAY:
		return {}

	var conocimientos_normalizados: Array = []

	for conocimiento in conocimientos:
		if (
			typeof(conocimiento) == TYPE_STRING
			and conocimiento in CONOCIMIENTOS_CONOCIDOS
			and conocimiento not in conocimientos_normalizados
		):
			conocimientos_normalizados.append(conocimiento)

	# Normalizar mejoras de hardware.
	var mejoras = progress.get(
		"hardware_upgrades",
		progreso_base.get("hardware_upgrades", {})
	)

	if typeof(mejoras) != TYPE_DICTIONARY:
		return {}

	var mejoras_normalizadas: Dictionary = {}

	for mejora in MEJORAS_HARDWARE_CONOCIDAS:
				mejoras_normalizadas[mejora] = maxi(
			0,
			int(mejoras.get(mejora, 0))
		)

	# Normalizar misión actual.
	var mision_actual: String = str(
		progress.get(
			"current_mission_id",
			progreso_base.get(
				"current_mission_id",
				"recolectar_primer_mineral"
			)
		)
	).strip_edges()

	if mision_actual.is_empty():
		mision_actual = "recolectar_primer_mineral"

	return {
		"minerals_ship": maxi(
			0,
			int(progress.get(
				"minerals_ship",
				progreso_base.get("minerals_ship", 0)
			))
		),
		"minerals_spid": maxi(
			0,
			int(progress.get(
				"minerals_spid",
				progreso_base.get("minerals_spid", 0)
			))
		),
		"map_tier": maxi(
			0,
			int(progress.get(
				"map_tier",
				progreso_base.get("map_tier", 0)
			))
		),
		"unlocked_syntax": sintaxis_normalizada,
		"current_mission_id": mision_actual,
		"completed_missions": misiones_normalizadas,
		"unlocked_knowledge": conocimientos_normalizados,
		"hardware_upgrades": mejoras_normalizadas,
	}
