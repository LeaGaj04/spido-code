extends Node

const ERROR_SINTAXIS_BLOQUEADA := "Sintaxis no adquirida. Visita la Nave para comprar esta mejora."

# false: la mejora todavia no fue adquirida.
# true: la mejora fue comprada y puede superar este validador.
var sintaxis_desbloqueada: Dictionary = {
	"for": false,
	"while": false,
	"if": false,
	"else": false,
	"in range": false,
	"tamano_mundo": false,
	"listas": false,
	"def": false,
	"parametros_def": false,
	"tiene_espacio": false,
}

const CLAVES_CONOCIDAS := ["for", "while", "if", "else", "in range", "tamano_mundo", "listas", "def", "parametros_def", "tiene_espacio"]


# Restaura únicamente las mejoras de sintaxis que conoce el juego. Las claves
# ausentes conservan un valor seguro: bloqueadas.
func aplicar_sintaxis_desbloqueada(data: Dictionary) -> void:
	for palabra_clave in CLAVES_CONOCIDAS:
		sintaxis_desbloqueada[palabra_clave] = data.get(palabra_clave, false) == true


# Se ejecuta antes del parser actual. Si encuentra una mejora bloqueada,
# detiene el procesamiento completo del codigo ingresado.
func validar_codigo(codigo: String) -> bool:
	var codigo_normalizado := codigo.to_lower()

	for palabra_clave in sintaxis_desbloqueada:
		if sintaxis_desbloqueada[palabra_clave]:
			continue

		if palabra_clave == "listas":
			if "[" in codigo and "]" in codigo:
				print(ERROR_SINTAXIS_BLOQUEADA)
				return false
			continue

		if palabra_clave == "parametros_def":
			var regex_param := RegEx.new()
			if regex_param.compile("(?i)def\\s+[A-Za-z_][A-Za-z0-9_]*\\s*\\([^)]+\\)\\s*:") == OK:
				if regex_param.search(codigo) != null:
					print(ERROR_SINTAXIS_BLOQUEADA)
					return false
			continue

		if _contiene_palabra_clave(codigo_normalizado, palabra_clave):
			print(ERROR_SINTAXIS_BLOQUEADA)
			return false

	return true


# API publica para la Nave/Tienda.
# Ejemplo: GestorSintaxis.desbloquear_sintaxis("for")
func desbloquear_sintaxis(palabra_clave: String) -> bool:
	var palabra_normalizada := _normalizar_palabra_clave(palabra_clave)

	if not sintaxis_desbloqueada.has(palabra_normalizada):
		return false

	sintaxis_desbloqueada[palabra_normalizada] = true
	return true


func esta_desbloqueada(palabra_clave: String) -> bool:
	var palabra_normalizada := _normalizar_palabra_clave(palabra_clave)
	return sintaxis_desbloqueada.get(palabra_normalizada, false)


func get_sintaxis_desbloqueada() -> Dictionary:
	return sintaxis_desbloqueada.duplicate(true)


func _contiene_palabra_clave(codigo: String, palabra_clave: String) -> bool:
	var expresion := RegEx.new()
	var partes := palabra_clave.split(" ", false)
	var patron := "\\b" + "\\s+".join(partes) + "\\b"

	if expresion.compile(patron) != OK:
		return false

	return expresion.search(codigo) != null


func _normalizar_palabra_clave(palabra_clave: String) -> String:
	var partes := palabra_clave.strip_edges().to_lower().split(" ", false)
	return " ".join(partes)
