extends Control

signal cerrado

# CÃ³dice
const CONOCIMIENTOS := {
	"objeto": {
		"nombre": "Objeto",
		"categoria": "Fundamentos",
		"descripcion": "En programaciÃ³n orientada a objetos (POO), un objeto es una entidad que combina propiedades y acciones. En SpidoCode, tu Spid es el objeto principal que controlas mediante cÃ³digo.",
		"sintaxis": "spid.<metodo>()",
		"ejemplo": "spid.minar()\n# 'spid' es el objeto que ejecuta la instrucciÃ³n.",
		"errores": "Escribir mal el nombre del objeto o usar mayÃºsculas (ej: Spid.minar() o rver.minar())."
	},
	"metodo": {
		"nombre": "MÃ©todo",
		"categoria": "Fundamentos",
		"descripcion": "Un mÃ©todo es una acciÃ³n o comando que un objeto sabe realizar. Siempre va acompaÃ±ado de parÃ©ntesis '()', que pueden o no llevar datos en su interior.",
		"sintaxis": "objeto.nombre_metodo()",
		"ejemplo": "spid.minar()\nspid.transferir()\nspid.norte()",
		"errores": "Olvidar los parÃ©ntesis obligatorios (ej: escribir 'spid.minar' sin '()') o usar comas en vez de puntos."
	},
	"secuencia": {
		"nombre": "Secuencia de CÃ³digo",
		"categoria": "Fundamentos",
		"descripcion": "El ordenador ejecuta las instrucciones en orden secuencial: de arriba hacia abajo y una por una. El orden lÃ³gico de tus lÃ­neas determina si el spid cumple o falla la misiÃ³n.",
		"sintaxis": "instruccion_1\ninstruccion_2\ninstruccion_3",
		"ejemplo": "spid.norte()\nspid.minar()\nspid.sur()\nspid.transferir()",
		"errores": "Intentar transferir antes de minar o antes de regresar a la casilla de la nave."
	},
	"parametro": {
		"nombre": "ParÃ¡metros (Argumentos)",
		"categoria": "Fundamentos",
		"descripcion": "Los parÃ¡metros son valores numÃ©ricos que enviamos dentro de los parÃ©ntesis de un mÃ©todo para modificar su comportamiento, como indicar la cantidad exacta de pasos a avanzar.",
		"sintaxis": "spid.direccion(cantidad)",
		"ejemplo": "spid.norte(2)  # Avanza dos casillas al norte\nspid.sur(3)    # Avanza tres casillas al sur",
		"errores": "Enviar nÃºmeros negativos, texto o enviar parÃ¡metros a comandos que no los reciben (como spid.minar(5))."
	},
	"bucle_while": {
		"nombre": "Bucle While (AutomatizaciÃ³n)",
		"categoria": "Control",
		"descripcion": "Estructura de control que repite un bloque de instrucciones continuamente mientras una condiciÃ³n sea verdadera. Permite automatizar rutinas continuas de suministro y patrullaje.",
		"sintaxis": "while <condicion>:\n    <instrucciones_con_sangria>",
		"ejemplo": "# Ciclo continuo de suministro:\nwhile True:\n    spid.norte()\n    spid.minar()\n    spid.sur()\n    spid.transferir()\n\n# O segÃºn el espacio en bodega:\nwhile spid.tiene_espacio():\n    spid.minar()",
		"errores": "Olvidar los dos puntos ':' al final, olvidar aplicar sangrÃ­a a las acciones interiores, o no incluir una condiciÃ³n de parada o retorno a base."
	},
	"bucle_for": {
		"nombre": "Bucle For (RepeticiÃ³n Exacta)",
		"categoria": "Control",
		"descripcion": "Estructura de control que permite repetir un bloque de instrucciones un nÃºmero exacto de veces usando range(N). Todo lo que se repite debe llevar sangrÃ­a (tabulaciÃ³n o 4 espacios).",
		"sintaxis": "for <variable> in range(<repeticiones>):\n    <instrucciones_con_sangria>",
		"ejemplo": "for ciclo in range(10):\n    spid.norte()\n    spid.minar()\n    spid.sur()\nspid.transferir()  # Fuera del bucle",
		"errores": "Olvidar los dos puntos ':' al final de range(), o no aplicar sangrÃ­a a las instrucciones interiores."
	},
	"condicional_if": {
		"nombre": "Condicional If (Decisiones)",
		"categoria": "Control",
		"descripcion": "Permite al spid tomar decisiones lÃ³gicas en base al estado de sus sensores o del terreno. Si la condiciÃ³n es verdadera, ejecuta el bloque.",
		"sintaxis": "if <condicion>:\n    <instrucciones_con_sangria>",
		"ejemplo": "if spid.hay_mineral():\n    spid.minar()",
		"errores": "Olvidar los dos puntos ':', olvidar los parÃ©ntesis en los sensores (ej: 'spid.hay_mineral' sin '()') o no aplicar sangrÃ­a a la acciÃ³n interior."
	},
	"variable": {
		"nombre": "Variables",
		"categoria": "OrganizaciÃ³n",
		"descripcion": "Una variable es un espacio asignado en memoria para almacenar un dato (como un entero) bajo un nombre Ãºnico, permitiendo reutilizar ese dato en mÃºltiples operaciones.",
		"sintaxis": "nombre_variable = valor",
		"ejemplo": "pasos = 2\nspid.norte(pasos)\nspid.minar()\nspid.sur(pasos)\nspid.transferir()",
		"errores": "Intentar usar una variable antes de definirla (ej: spid.norte(pasos) sin definir 'pasos = 2') o utilizar nombres de palabras clave del sistema."
	},
	"funcion": {
		"nombre": "Funciones Propias",
		"categoria": "OrganizaciÃ³n",
		"descripcion": "Bloques de cÃ³digo personalizados definidos por el jugador para reutilizar rutinas complejas sin duplicar cÃ³digo.",
		"sintaxis": "def mi_rutina():\n    <instrucciones>",
		"ejemplo": "# PrÃ³ximamente",
		"errores": "Archivo cifrado."
	},
	"movimiento": {
		"nombre": "Movimiento",
		"categoria": "Comandos",
		"descripcion": "Ordena al Spid desplazarse por la cuadrícula del mapa. Recibe de forma opcional el número de casillas a avanzar como parámetro.",
		"sintaxis": "spid.norte(pasos)
spid.sur(pasos)
spid.este(pasos)
spid.oeste(pasos)",
		"ejemplo": "spid.norte()   # Avanza 1 casilla\nspid.sur(2)    # Avanza 2 casillas",
		"errores": "Chocar con los límites del mapa o ingresar parámetros no numéricos."
	},
	"acciones": {
		"nombre": "Minería y Transferencia",
		"categoria": "Comandos",
		"descripcion": "Acciones principales para interactuar con los recursos del entorno y completar las cuotas de recolección.",
		"sintaxis": "spid.minar()
spid.transferir()",
		"ejemplo": "spid.minar()
spid.sur()
spid.transferir()",
		"errores": "Intentar minar cuando no hay minerales o el inventario está lleno. Intentar transferir fuera de la base."
	},
	"sensores": {
		"nombre": "Sensores del Spid",
		"categoria": "Comandos",
		"descripcion": "El Spid cuenta con sensores integrados para evaluar su entorno y estado. Devuelven un valor verdadero (True/False) o un número.",
		"sintaxis": "spid.hay_mineral()
spid.tiene_espacio()
spid.en_base()
spid.minerales_en_rover()
spid.minerales_en_nave()",
		"ejemplo": "if spid.hay_mineral():
	spid.minar()",
		"errores": "Olvidar los paréntesis al llamar al sensor, o usar un sensor fuera de una condición o evaluación."
	}
}

var categoria_actual: String = "Comandos"
var concepto_actual_id: String = "movimiento"

@onready var contenedor_lista: VBoxContainer = $Centro/PanelPrincipal/VBox/Cuerpo/ColumnaIzquierda/Scroll/ListaConceptos
@onready var label_titulo: Label = $Centro/PanelPrincipal/VBox/Cuerpo/ColumnaDerecha/Scroll/Detalle/TituloConcepto
@onready var label_estado: Label = $Centro/PanelPrincipal/VBox/Cuerpo/ColumnaDerecha/Scroll/Detalle/EstadoConcepto
@onready var txt_descripcion: RichTextLabel = $Centro/PanelPrincipal/VBox/Cuerpo/ColumnaDerecha/Scroll/Detalle/Descripcion
@onready var txt_sintaxis: RichTextLabel = $Centro/PanelPrincipal/VBox/Cuerpo/ColumnaDerecha/Scroll/Detalle/Sintaxis
@onready var txt_ejemplo: RichTextLabel = $Centro/PanelPrincipal/VBox/Cuerpo/ColumnaDerecha/Scroll/Detalle/Ejemplo
@onready var txt_errores: RichTextLabel = $Centro/PanelPrincipal/VBox/Cuerpo/ColumnaDerecha/Scroll/Detalle/Errores

@onready var btn_fundamentos: Button = $Centro/PanelPrincipal/VBox/Pestanas/BotonFundamentos
@onready var btn_control: Button = $Centro/PanelPrincipal/VBox/Pestanas/BotonControl
@onready var btn_organizacion: Button = $Centro/PanelPrincipal/VBox/Pestanas/BotonOrganizacion
@onready var btn_comandos: Button = $Centro/PanelPrincipal/VBox/Pestanas/BotonComandos


var estilo_concepto_normal: StyleBoxFlat
var estilo_concepto_hover: StyleBoxFlat
var estilo_concepto_selected: StyleBoxFlat
var estilo_concepto_cifrado: StyleBoxFlat
var botones_por_id: Dictionary = {}


func _ready() -> void:
	hide()
	_inicializar_estilos_conceptos()
	btn_fundamentos.pressed.connect(_cambiar_categoria.bind("Fundamentos"))
	btn_control.pressed.connect(_cambiar_categoria.bind("Control"))
	btn_organizacion.pressed.connect(_cambiar_categoria.bind("OrganizaciÃ³n"))
	btn_comandos.pressed.connect(_cambiar_categoria.bind("Comandos"))
	$Centro/PanelPrincipal/VBox/Cabecera/BotonCerrar.pressed.connect(cerrar)


func _inicializar_estilos_conceptos() -> void:
	estilo_concepto_normal = StyleBoxFlat.new()
	estilo_concepto_normal.bg_color = Color(0.0, 0.06666667, 0.0, 0.76)
	estilo_concepto_normal.border_color = Color(0.37254903, 0.5921569, 0.41960785, 0.85)
	estilo_concepto_normal.set_border_width_all(2)
	estilo_concepto_normal.set_corner_radius_all(10)
	estilo_concepto_normal.content_margin_left = 14.0
	estilo_concepto_normal.content_margin_top = 8.0
	estilo_concepto_normal.content_margin_right = 14.0
	estilo_concepto_normal.content_margin_bottom = 8.0
	estilo_concepto_normal.shadow_color = Color(0.0039, 0.09, 0.011, 0.65)
	estilo_concepto_normal.shadow_offset = Vector2(3, 3)

	estilo_concepto_hover = StyleBoxFlat.new()
	estilo_concepto_hover.bg_color = Color(0.015, 0.12, 0.025, 0.92)
	estilo_concepto_hover.border_color = Color(0.48, 0.76, 0.54, 1.0)
	estilo_concepto_hover.set_border_width_all(2)
	estilo_concepto_hover.set_corner_radius_all(10)
	estilo_concepto_hover.content_margin_left = 14.0
	estilo_concepto_hover.content_margin_top = 8.0
	estilo_concepto_hover.content_margin_right = 14.0
	estilo_concepto_hover.content_margin_bottom = 8.0
	estilo_concepto_hover.expand_margin_left = 1.0
	estilo_concepto_hover.expand_margin_top = 1.0
	estilo_concepto_hover.expand_margin_right = 1.0
	estilo_concepto_hover.expand_margin_bottom = 1.0
	estilo_concepto_hover.shadow_color = Color(0.0039, 0.09, 0.011, 0.65)
	estilo_concepto_hover.shadow_offset = Vector2(3, 3)

	estilo_concepto_selected = StyleBoxFlat.new()
	estilo_concepto_selected.bg_color = Color(0.025, 0.14, 0.04, 0.95)
	estilo_concepto_selected.border_color = Color(0.7607843, 0.9372549, 0.7764706, 1.0)
	estilo_concepto_selected.set_border_width_all(2)
	estilo_concepto_selected.set_corner_radius_all(10)
	estilo_concepto_selected.content_margin_left = 14.0
	estilo_concepto_selected.content_margin_top = 8.0
	estilo_concepto_selected.content_margin_right = 14.0
	estilo_concepto_selected.content_margin_bottom = 8.0
	estilo_concepto_selected.shadow_color = Color(0.0039, 0.09, 0.011, 0.75)
	estilo_concepto_selected.shadow_offset = Vector2(4, 4)

	estilo_concepto_cifrado = StyleBoxFlat.new()
	estilo_concepto_cifrado.bg_color = Color(0.01, 0.03, 0.015, 0.6)
	estilo_concepto_cifrado.border_color = Color(0.25, 0.4, 0.3, 0.45)
	estilo_concepto_cifrado.set_border_width_all(1)
	estilo_concepto_cifrado.set_corner_radius_all(10)
	estilo_concepto_cifrado.content_margin_left = 14.0
	estilo_concepto_cifrado.content_margin_top = 8.0
	estilo_concepto_cifrado.content_margin_right = 14.0
	estilo_concepto_cifrado.content_margin_bottom = 8.0


func abrir() -> void:
	show()
	_cambiar_categoria("Fundamentos")


func cerrar() -> void:
	hide()
	cerrado.emit()


func _cambiar_categoria(categoria: String) -> void:
	categoria_actual = categoria

	# Resaltar pestaÃ±a activa
	btn_fundamentos.modulate = Color(1.2, 1.2, 1.2) if categoria == "Fundamentos" else Color(0.7, 0.7, 0.7)
	btn_control.modulate = Color(1.2, 1.2, 1.2) if categoria == "Control" else Color(0.7, 0.7, 0.7)
	btn_organizacion.modulate = Color(1.2, 1.2, 1.2) if categoria == "OrganizaciÃ³n" else Color(0.7, 0.7, 0.7)
	btn_comandos.modulate = Color(1.2, 1.2, 1.2) if categoria == "Comandos" else Color(0.7, 0.7, 0.7)

	_poblar_lista_conceptos()


func _poblar_lista_conceptos() -> void:
	botones_por_id.clear()
	for hijo in contenedor_lista.get_children():
		hijo.queue_free()

	var conocimientos_desbloqueados: Array = MissionService.get_unlocked_knowledge()
	var primer_concepto := ""

	for id_clave in CONOCIMIENTOS:
		var datos = CONOCIMIENTOS[id_clave]
		if datos["categoria"] != categoria_actual:
			continue

		var esta_desbloqueado = id_clave in conocimientos_desbloqueados or datos["categoria"] == "Comandos"
		var boton := Button.new()
		boton.text = datos["nombre"] if esta_desbloqueado else "[ CIFRADO ] " + datos["nombre"]
		boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		boton.custom_minimum_size = Vector2(0, 42)
		boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		boton.add_theme_font_size_override("font_size", 14)
		boton.add_theme_color_override("font_outline_color", Color(0.025, 0.02, 0.055, 1))
		boton.add_theme_constant_override("outline_size", 2)

		if esta_desbloqueado:
			boton.add_theme_color_override("font_color", Color(0.7607843, 0.9372549, 0.7764706, 1))
			boton.add_theme_color_override("font_hover_color", Color(0.92, 1.0, 0.92, 1))
			boton.add_theme_stylebox_override("normal", estilo_concepto_normal)
			boton.add_theme_stylebox_override("hover", estilo_concepto_hover)
			boton.add_theme_stylebox_override("focus", estilo_concepto_selected)
		else:
			boton.add_theme_color_override("font_color", Color(0.45, 0.6, 0.5, 0.75))
			boton.add_theme_color_override("font_hover_color", Color(0.6, 0.75, 0.65, 0.9))
			boton.add_theme_stylebox_override("normal", estilo_concepto_cifrado)
			boton.add_theme_stylebox_override("hover", estilo_concepto_hover)
			boton.add_theme_stylebox_override("focus", estilo_concepto_cifrado)

		botones_por_id[id_clave] = boton
		boton.pressed.connect(_seleccionar_concepto.bind(id_clave))
		contenedor_lista.add_child(boton)

		if primer_concepto.is_empty():
			primer_concepto = id_clave

	if not primer_concepto.is_empty():
		_seleccionar_concepto(primer_concepto)


func _seleccionar_concepto(id_clave: String) -> void:
	concepto_actual_id = id_clave
	var datos = CONOCIMIENTOS.get(id_clave, {})
	var esta_desbloqueado = id_clave in MissionService.get_unlocked_knowledge() or datos.get("categoria", "") == "Comandos"

	# Resaltar el botÃ³n activo en la lista
	for clave in botones_por_id:
		var btn: Button = botones_por_id[clave]
		if is_instance_valid(btn):
			var desbloq = clave in MissionService.get_unlocked_knowledge() or CONOCIMIENTOS.get(clave, {}).get("categoria", "") == "Comandos"
			if clave == id_clave:
				btn.add_theme_stylebox_override("normal", estilo_concepto_selected)
			else:
				btn.add_theme_stylebox_override("normal", estilo_concepto_normal if desbloq else estilo_concepto_cifrado)

	if esta_desbloqueado:
		label_titulo.text = "â—† " + datos.get("nombre", "").to_upper()
		label_estado.text = "â— ESTADO: DESBLOQUEADO"
		label_estado.modulate = Color(0.7608024, 0.9369633, 0.7753063)
		txt_descripcion.text = datos.get("descripcion", "")
		txt_sintaxis.text = "[code]" + datos.get("sintaxis", "") + "[/code]"
		txt_ejemplo.text = "[code]" + datos.get("ejemplo", "") + "[/code]"
		txt_errores.text = datos.get("errores", "")
	else:
		label_titulo.text = "â—† " + datos.get("nombre", "").to_upper() + " [ENCRIPTADO]"
		label_estado.text = "â— ESTADO: ARCHIVO CIFRADO"
		label_estado.modulate = Color(0.9, 0.4, 0.4)
		txt_descripcion.text = "Este banco de datos se encuentra cifrado. Para descifrarlo debes desbloquear y superar misiones de exploraciÃ³n avanzadas en el asteroide."
		txt_sintaxis.text = "[code]??? [/code]"
		txt_ejemplo.text = "[code]# ACCESO DENEGADO POR SEGURIDAD DE A.D.A.[/code]"
		txt_errores.text = "InformaciÃ³n clasificada hasta nueva asignaciÃ³n de misiÃ³n."
