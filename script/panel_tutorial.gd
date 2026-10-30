extends Control

signal cerrado

const TUTORIALES_POR_FASE := {
	0: {
		"titulo_fase": "A.D.A. // PROTOCOLO DE INDUCCIÓN BÁSICA",
		"tarjetas": [
			{
				"imagen": "res://assets/tutorial/fase0_1_consola.png"
			},
			{
				"imagen": "res://assets/tutorial/fase0_2_movimiento.png"
			},
			{
				"imagen": "res://assets/tutorial/fase0_3_ciclo.png"
			}
		]
	},
	1: {
		"titulo_fase": "FASE 1 // SECUENCIA LINEAL (ORDEN ESTRICTO)",
		"tarjetas": [
			{
				"imagen": "res://assets/tutorial/fase1_1_secuencia.png"
			},
			{
				"imagen": "res://assets/tutorial/fase1_2_corredor.png"
			},
			{
				"imagen": "res://assets/tutorial/fase1_3_errores.png"
			}
		]
	},
	2: {
		"titulo_fase": "FASE 2 // BUCLE WHILE (TRABAJO CONTINUO)",
		"tarjetas": [
			{
				"imagen": "res://assets/tutorial/fase2_1_bucle.png"
			},
			{
				"imagen": "res://assets/tutorial/fase2_2_sangria.png"
			},
			{
				"imagen": "res://assets/tutorial/fase2_3_errores.png"
			}
		]
	},
	3: {
		"titulo_fase": "FASE 3 // CONDICIONALES IF/ELSE (TOMA DE DECISIONES)",
		"tarjetas": [
			{
				"imagen": "res://assets/tutorial/fase3_1_sensor.png"
			},
			{
				"imagen": "res://assets/tutorial/fase3_2_ifelse.png"
			},
			{
				"imagen": "res://assets/tutorial/fase3_3_errores.png"
			}
		]
	}
}

var fase_actual: int = 0
var indice_tarjeta: int = 0

@onready var label_fase: Label = $Centro/PanelPrincipal/VBox/Cabecera/TituloFase
@onready var imagen_pantalla: TextureRect = $Centro/PanelPrincipal/VBox/ContenedorImagen/Imagen
@onready var label_contador: Label = $Centro/PanelPrincipal/VBox/Navegacion/Contador
@onready var btn_anterior: Button = $Centro/PanelPrincipal/VBox/Navegacion/BotonAnterior
@onready var btn_siguiente: Button = $Centro/PanelPrincipal/VBox/Navegacion/BotonSiguiente
@onready var btn_cerrar: Button = $Centro/PanelPrincipal/VBox/Cabecera/BotonCerrar
@onready var btn_entendido: Button = $Centro/PanelPrincipal/VBox/Navegacion/BotonEntendido


func _ready() -> void:
	visible = false
	btn_anterior.pressed.connect(_on_anterior_pressed)
	btn_siguiente.pressed.connect(_on_siguiente_pressed)
	btn_cerrar.pressed.connect(cerrar)
	btn_entendido.pressed.connect(cerrar)


func tiene_tutorial(fase: int) -> bool:
	return TUTORIALES_POR_FASE.has(fase)


func _obtener_fase_fallback(fase: int) -> int:
	var disponibles := TUTORIALES_POR_FASE.keys()
	disponibles.sort()
	var fallback := 0
	for f in disponibles:
		if f <= fase:
			fallback = f
	return fallback


func abrir(fase: int = 0) -> void:
	if not TUTORIALES_POR_FASE.has(fase):
		fase = _obtener_fase_fallback(fase)
	fase_actual = fase
	indice_tarjeta = 0
	_actualizar_contenido()
	show()


func cerrar() -> void:
	hide()
	cerrado.emit()


func _on_anterior_pressed() -> void:
	if indice_tarjeta > 0:
		indice_tarjeta -= 1
		_actualizar_contenido()


func _on_siguiente_pressed() -> void:
	var total: int = _get_total_tarjetas()
	if indice_tarjeta < total - 1:
		indice_tarjeta += 1
		_actualizar_contenido()


func _get_total_tarjetas() -> int:
	var datos_fase = TUTORIALES_POR_FASE.get(fase_actual, {})
	var tarjetas = datos_fase.get("tarjetas", [])
	return tarjetas.size()


func _actualizar_contenido() -> void:
	var datos_fase = TUTORIALES_POR_FASE.get(fase_actual, {})
	var tarjetas = datos_fase.get("tarjetas", [])
	var total: int = tarjetas.size()
	if total == 0:
		return

	indice_tarjeta = clampi(indice_tarjeta, 0, total - 1)
	var tarjeta = tarjetas[indice_tarjeta]

	label_fase.text = datos_fase.get("titulo_fase", "GUÍA DE OPERACIÓN")
	label_contador.text = "Paso " + str(indice_tarjeta + 1) + " de " + str(total)

	var ruta_img = tarjeta.get("imagen", "")
	if ResourceLoader.exists(ruta_img):
		imagen_pantalla.texture = load(ruta_img)
	else:
		imagen_pantalla.texture = null

	btn_anterior.disabled = (indice_tarjeta == 0)
	btn_siguiente.visible = (indice_tarjeta < total - 1)
	btn_entendido.visible = (indice_tarjeta == total - 1)
