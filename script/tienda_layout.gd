extends RefCounted
## Distribución adaptable: los controles existentes conservan sus señales y estado.

const BG := Color("202833")
const PANEL := Color("454D5A")
const SURFACE := Color("596372")
const GREEN := Color("8BCB91")
const GREEN_DARK := Color("6FAF78")
const TEXT := Color("F4F6F2")
const SHADOW := Color("111720")

class TiendaInputRouter extends Node:
	var scroll: ScrollContainer
	var mapa: Control
	var arrastrando := false
	var ultimo_mouse := Vector2.ZERO
	var zoom_forzado := 0.58

	func _ready() -> void:
		# Aplicar la escala después del primer reajuste de los Containers.
		call_deferred("_aplicar_estado_inicial")
		set_process(true)

	func _process(_delta: float) -> void:
		# ScrollContainer puede reajustar el Control hijo al cambiar el layout;
		# mantener la transformación aquí evita que el mapa vuelva a escala 1.
		if mapa != null and not is_equal_approx(mapa.scale.x, zoom_forzado):
			mapa.scale = Vector2.ONE * zoom_forzado

	func _ajustar_scroll_al_pivote(mouse_local: Vector2, punto_mapa: Vector2, zoom_nuevo: float) -> void:
		await get_tree().process_frame
		var nuevo_scroll := punto_mapa * zoom_nuevo - mouse_local
		var max_horizontal := int(maxf(0.0, scroll.get_h_scroll_bar().max_value - scroll.get_h_scroll_bar().page))
		var max_vertical := int(maxf(0.0, scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page))
		scroll.scroll_horizontal = clampi(int(nuevo_scroll.x), 0, max_horizontal)
		scroll.scroll_vertical = clampi(int(nuevo_scroll.y), 0, max_vertical)

	func _aplicar_estado_inicial() -> void:
		if mapa == null:
			return
		mapa.pivot_offset = Vector2.ZERO
		zoom_forzado = 0.58
		mapa.scale = Vector2.ONE * zoom_forzado
		mapa.custom_minimum_size = Vector2(1400, 1080)
		mapa.size = Vector2(1400, 1080)
		scroll.scroll_horizontal = 0
		scroll.scroll_vertical = 0

	func _input(event: InputEvent) -> void:
		if scroll == null or mapa == null or not scroll.is_visible_in_tree():
			return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and scroll.get_global_rect().has_point(event.position):
				arrastrando = true
				ultimo_mouse = event.position
			elif not event.pressed:
				arrastrando = false
			return
		if event is InputEventMouseMotion and arrastrando:
			scroll.scroll_horizontal = maxi(0, scroll.scroll_horizontal - int(event.relative.x))
			scroll.scroll_vertical = maxi(0, scroll.scroll_vertical - int(event.relative.y))
			ultimo_mouse = event.position
			get_viewport().set_input_as_handled()
			return
		if event is InputEventMouseButton and event.pressed and event.ctrl_pressed and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var zoom_actual: float = float(mapa.get_meta("zoom", 1.0))
			var factor := 1.1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.9
			var zoom_nuevo := clampf(zoom_actual * factor, 0.45, 1.45)
			if not is_equal_approx(zoom_actual, zoom_nuevo):
				var mouse_local: Vector2 = event.position - scroll.global_position
				var punto_mapa: Vector2 = (mouse_local + Vector2(scroll.scroll_horizontal, scroll.scroll_vertical)) / zoom_actual
				mapa.set_meta("zoom", zoom_nuevo)
				zoom_forzado = zoom_nuevo
				mapa.scale = Vector2.ONE * zoom_nuevo
				mapa.custom_minimum_size = Vector2(1400, 1080)
				mapa.size = Vector2(1400, 1080)
				_ajustar_scroll_al_pivote(mouse_local, punto_mapa, zoom_nuevo)
			get_viewport().set_input_as_handled()

static func construir(panel: Control) -> void:
	panel.z_index = 200
	# La tienda es una capa modal: bloquea los clics hacia la interfaz del mundo.
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var lienzo: Control = panel.get_node("LienzoArbol")
	var originales := {}
	for hijo in lienzo.get_children():
		originales[hijo.name] = hijo
		if hijo is CanvasItem:
			hijo.hide()
	# El PanelTienda sigue cubriendo la pantalla para bloquear entradas, pero el
	# contenedor visual queda centrado y con tamaño controlado.
	panel.add_theme_stylebox_override("panel", _estilo(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 0))
	var oscurecedor := ColorRect.new()
	oscurecedor.name = "OscurecedorTienda"
	oscurecedor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	oscurecedor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	oscurecedor.color = Color(0.02, 0.04, 0.06, 0.68)
	oscurecedor.z_index = -20
	panel.add_child(oscurecedor)
	lienzo.set_anchors_preset(Control.PRESET_CENTER)
	lienzo.anchor_left = 0.5
	lienzo.anchor_top = 0.5
	lienzo.anchor_right = 0.5
	lienzo.anchor_bottom = 0.5
	lienzo.offset_left = -620
	lienzo.offset_top = -350
	lienzo.offset_right = 620
	lienzo.offset_bottom = 350
	lienzo.add_theme_stylebox_override("panel", _estilo(PANEL, SURFACE, 3, 14, 8))
	var margen := MarginContainer.new()
	lienzo.add_child(margen)
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 24)
	var columna := VBoxContainer.new()
	margen.add_child(columna)
	columna.add_theme_constant_override("separation", 18)
	var cabecera := HBoxContainer.new()
	columna.add_child(cabecera)
	var titulos := VBoxContainer.new()
	titulos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecera.add_child(titulos)
	_texto(titulos, "CENTRO DE MEJORAS", 26, GREEN)
	_texto(titulos, "Amplía tu terreno. Cada etapa incorpora nuevas herramientas de Python.", 16, TEXT)
	var cerrar: Button = originales["BotonCerrar"]
	cerrar.reparent(cabecera)
	cerrar.custom_minimum_size = Vector2(110, 44)
	cerrar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cerrar.show()
	_texto(columna, "PROGRESIÓN  /  Desliza para explorar las etapas", 15, GREEN)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.follow_focus = false
	scroll.focus_mode = Control.FOCUS_NONE
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.get_h_scroll_bar().hide()
	scroll.get_v_scroll_bar().hide()
	scroll.get_h_scroll_bar().mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.get_v_scroll_bar().mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(scroll)
	var mapa := Control.new()
	# El árbol completo entra inicialmente en la ventana; el jugador puede
	# ampliarlo después con Ctrl + rueda.
	var zoom_inicial := 0.58
	var tamano_mapa := Vector2(1400, 1080)
	# El tamaño lógico permanece completo para que el ScrollContainer tenga un
	# rango real de navegación; la escala solo modifica la representación visual.
	mapa.custom_minimum_size = tamano_mapa
	mapa.size = tamano_mapa
	mapa.scale = Vector2.ONE * zoom_inicial
	mapa.set_meta("zoom", zoom_inicial)
	mapa.mouse_filter = Control.MOUSE_FILTER_STOP
	mapa.set_meta("arrastrando", false)
	mapa.gui_input.connect(_on_mapa_gui_input.bind(scroll, mapa))
	scroll.add_child(mapa)
	var input_router := TiendaInputRouter.new()
	input_router.scroll = scroll
	input_router.mapa = mapa
	panel.add_child(input_router)
	# Grilla de fases: tres columnas por fila, con conexiones en zigzag.
	var x1 := 120.0
	var x2 := 560.0
	var x3 := 1000.0
	var y1 := 20.0
	var y2 := 260.0
	var y3 := 500.0
	var y4 := 740.0
	_conexion(mapa, Vector2(400, 105), Vector2(560, 105))
	_conexion(mapa, Vector2(840, 105), Vector2(1000, 105))
	_conexion(mapa, Vector2(1140, 190), Vector2(1140, 245))
	_conexion(mapa, Vector2(1140, 245), Vector2(260, 245))
	_conexion(mapa, Vector2(260, 245), Vector2(260, 260))
	_conexion(mapa, Vector2(400, 345), Vector2(560, 345))
	_conexion(mapa, Vector2(840, 345), Vector2(1000, 345))
	_conexion(mapa, Vector2(1140, 430), Vector2(1140, 485))
	_conexion(mapa, Vector2(1140, 485), Vector2(260, 485))
	_conexion(mapa, Vector2(260, 485), Vector2(260, 500))
	_conexion(mapa, Vector2(400, 585), Vector2(560, 585))
	_conexion(mapa, Vector2(840, 585), Vector2(1000, 585))
	_conexion(mapa, Vector2(1140, 670), Vector2(1140, 725))
	_conexion(mapa, Vector2(1140, 725), Vector2(260, 725))
	_conexion(mapa, Vector2(260, 725), Vector2(260, 740))
	_conexion(mapa, Vector2(400, 825), Vector2(560, 825))
	_conexion(mapa, Vector2(840, 825), Vector2(1000, 825))
	_nodo(mapa, Vector2(x1, y1), "FASE 0  /  BASE 1×1", "Punto de partida. Extrae y transfiere minerales.", null, null)
	_nodo(mapa, Vector2(x2, y1), "FASE 1  /  SECTOR 1×3", "Calibra una ruta y activa WHILE.", originales["ButtonExpansion1"], originales["ButtonWhile"])
	_nodo(mapa, Vector2(x3, y1), "FASE 2  /  SECTOR 2×3", "Detecta minerales con IF / ELSE.", originales["ButtonExpansion2"], originales["ButtonIf"])
	_nodo(mapa, Vector2(x1, y2), "FASE 3  /  CICLO FOR", "Automatiza ciclos de recolección.", originales["ButtonExpansion3"], originales["ButtonFor"])
	_nodo(mapa, Vector2(x2, y2), "FASE 4  /  SECTOR 3×3", "Expande el terreno y habilita variables.", originales["ButtonVariables"], null)
	_nodo(mapa, Vector2(x3, y2), "FASE 5  /  TELEMETRÍA", "Consulta el tamaño del sector en tiempo real.", originales.get("ButtonTelemetria"), null)
	_nodo(mapa, Vector2(x1, y3), "FASE 6  /  SECTOR 4×3", "Desbloquea listas y navegación dinámica.", originales.get("ButtonSector4x3"), null)
	_nodo(mapa, Vector2(x2, y3), "FASE 7  /  SECTOR 4×4", "Desbloquea funciones propias con def.", originales.get("ButtonSector4x4"), null)
	_nodo(mapa, Vector2(x3, y3), "FASE 7.5  /  SECTOR 5×4", "Funciones con parámetros personalizados.", originales.get("ButtonSector5x4"), null)
	_nodo(mapa, Vector2(x2, y4), "FASE 8  /  SECTOR 5×5", "Barrido bidimensional por columnas.", originales.get("ButtonSector5x5"), null)
	_nodo(mapa, Vector2(x3, y4), "FASE 8.5  /  PROTOCOLO MAESTRO", "Barrido continuo y descarga autónoma.", originales.get("ButtonProtocoloMaestro"), null)
	_nodo(mapa, Vector2(x1, y4), "OPCIONAL  /  MINERÍA RÁPIDA", "Reduce el tiempo de extracción a 1 segundo.", originales["ButtonMineria"], null)
	# Aplicar la escala después de construir todos los hijos: los Containers de
	# Godot pueden reajustar el tamaño de un Control durante la construcción.
	mapa.pivot_offset = Vector2.ZERO
	mapa.scale = Vector2.ONE * zoom_inicial
	mapa.custom_minimum_size = tamano_mapa
	mapa.size = tamano_mapa


static func _etapa(destino: Control, titulo: String, detalle: String, compra: Button, conocimiento: Button, color: Color) -> void:
	var tarjeta := PanelContainer.new()
	tarjeta.add_theme_stylebox_override("panel", _estilo(SURFACE, GREEN_DARK, 3, 14, 7))
	destino.add_child(tarjeta)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 24)
	tarjeta.add_child(fila)
	var contenido := VBoxContainer.new()
	contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenido.add_theme_constant_override("separation", 10)
	fila.add_child(contenido)
	_texto(contenido, titulo, 20, GREEN)
	_texto(contenido, detalle, 16, TEXT)
	if conocimiento != null:
		conocimiento.reparent(contenido)
		conocimiento.flat = true
		conocimiento.mouse_filter = Control.MOUSE_FILTER_IGNORE
		conocimiento.focus_mode = Control.FOCUS_NONE
		conocimiento.alignment = HORIZONTAL_ALIGNMENT_LEFT
		conocimiento.add_theme_color_override("font_color", TEXT)
		conocimiento.add_theme_color_override("font_outline_color", SHADOW)
		conocimiento.add_theme_constant_override("outline_size", 3)
		conocimiento.add_theme_font_size_override("font_size", 14)
		conocimiento.add_theme_stylebox_override("normal", _estilo(BG, GREEN_DARK, 2, 10, 4))
		conocimiento.show()
	if compra != null:
		compra.reparent(fila)
		compra.custom_minimum_size = Vector2(280, 76)
		compra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		compra.add_theme_font_size_override("font_size", 17)
		compra.add_theme_color_override("font_color", TEXT)
		compra.add_theme_color_override("font_hover_color", TEXT)
		compra.add_theme_color_override("font_pressed_color", TEXT)
		compra.add_theme_color_override("font_disabled_color", Color("CBD0D2"))
		compra.add_theme_color_override("font_outline_color", SHADOW)
		compra.add_theme_constant_override("outline_size", 3)
		compra.add_theme_stylebox_override("normal", _estilo(GREEN, GREEN_DARK, 3, 14, 6))
		compra.add_theme_stylebox_override("hover", _estilo(Color("A1D6A6"), GREEN_DARK, 3, 14, 6))
		compra.add_theme_stylebox_override("pressed", _estilo(GREEN_DARK, GREEN_DARK, 3, 14, 2))
		compra.add_theme_stylebox_override("disabled", _estilo(SURFACE, PANEL, 3, 14, 4))
		compra.show()


static func _nodo(mapa: Control, posicion: Vector2, titulo: String, detalle: String, compra: Button, conocimiento: Button) -> void:
	var tarjeta := PanelContainer.new()
	tarjeta.position = posicion
	tarjeta.custom_minimum_size = Vector2(280, 170)
	tarjeta.size = Vector2(280, 170)
	tarjeta.add_theme_stylebox_override("panel", _estilo(SURFACE, GREEN_DARK, 3, 14, 7))
	mapa.add_child(tarjeta)
	tarjeta.z_index = 1
	var contenido := VBoxContainer.new()
	contenido.add_theme_constant_override("separation", 6)
	tarjeta.add_child(contenido)
	_texto(contenido, titulo, 15, GREEN)
	var descripcion := Label.new()
	descripcion.text = detalle
	descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	descripcion.custom_minimum_size = Vector2(0, 42)
	descripcion.add_theme_font_size_override("font_size", 14)
	descripcion.add_theme_color_override("font_color", TEXT)
	descripcion.add_theme_color_override("font_outline_color", SHADOW)
	descripcion.add_theme_constant_override("outline_size", 2)
	contenido.add_child(descripcion)
	if conocimiento != null:
		conocimiento.reparent(contenido)
		conocimiento.flat = true
		conocimiento.mouse_filter = Control.MOUSE_FILTER_IGNORE
		conocimiento.focus_mode = Control.FOCUS_NONE
		conocimiento.add_theme_font_size_override("font_size", 13)
		conocimiento.add_theme_color_override("font_color", TEXT)
		conocimiento.show()
	if compra != null:
		compra.reparent(contenido)
		compra.focus_mode = Control.FOCUS_NONE
		compra.custom_minimum_size = Vector2(0, 48)
		compra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		compra.add_theme_font_size_override("font_size", 14)
		compra.show()


static func _conexion(mapa: Control, inicio: Vector2, fin: Vector2) -> void:
	var linea := Line2D.new()
	linea.points = PackedVector2Array([inicio, fin])
	linea.width = 5.0
	linea.default_color = GREEN_DARK
	linea.z_index = 0
	mapa.add_child(linea)


static func _on_mapa_gui_input(event: InputEvent, scroll: ScrollContainer, mapa: Control) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mapa.set_meta("arrastrando", event.pressed)
		scroll.accept_event()
	elif event is InputEventMouseMotion and bool(mapa.get_meta("arrastrando", false)):
		scroll.scroll_horizontal = maxi(0, scroll.scroll_horizontal - int(event.relative.x))
		scroll.scroll_vertical = maxi(0, scroll.scroll_vertical - int(event.relative.y))
		scroll.accept_event()


static func _texto(destino: Control, contenido: String, tamano: int, color: Color) -> void:
	var label := Label.new()
	label.text = contenido
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", tamano)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", SHADOW)
	label.add_theme_constant_override("outline_size", 3)
	destino.add_child(label)


static func _estilo(fondo: Color, borde: Color, borde_ancho: int = 2, radio: int = 12, sombra: int = 0) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.border_color = borde
	estilo.set_border_width_all(borde_ancho)
	estilo.set_corner_radius_all(radio)
	estilo.shadow_color = SHADOW
	estilo.shadow_size = sombra
	estilo.shadow_offset = Vector2(0, 5)
	estilo.content_margin_left = 22
	estilo.content_margin_right = 22
	estilo.content_margin_top = 18
	estilo.content_margin_bottom = 18
	return estilo
