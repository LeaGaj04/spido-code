extends RefCounted
## Distribución adaptable: los controles existentes conservan sus señales y estado.

static func construir(panel: Control) -> void:
	panel.z_index = 30
	var lienzo: Control = panel.get_node("LienzoArbol")
	var originales := {}
	for hijo in lienzo.get_children():
		originales[hijo.name] = hijo
		if hijo is CanvasItem:
			hijo.hide()
	lienzo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lienzo.offset_left = 40
	lienzo.offset_top = 32
	lienzo.offset_right = -40
	lienzo.offset_bottom = -32
	lienzo.add_theme_stylebox_override("panel", _estilo(Color("101c24"), Color("39545e")))
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
	_texto(titulos, "CENTRO DE MEJORAS", 26, Color("b6f2d0"))
	_texto(titulos, "Amplía tu terreno. Cada etapa incorpora nuevas herramientas de Python.", 16, Color("a5bac4"))
	var cerrar: Button = originales["BotonCerrar"]
	cerrar.reparent(cabecera)
	cerrar.custom_minimum_size = Vector2(110, 44)
	cerrar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cerrar.show()
	_texto(columna, "PROGRESIÓN  /  Desliza para explorar las etapas", 15, Color("7dada7"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columna.add_child(scroll)
	var ruta := VBoxContainer.new()
	ruta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ruta.add_theme_constant_override("separation", 16)
	scroll.add_child(ruta)
	_etapa(ruta, "00  /  BASE 1×1", "Punto de partida · Aprende a extraer y transferir minerales.", null, null, Color("52d5c1"))
	_etapa(ruta, "01  /  CORREDOR 1×3", "Calibra una ruta con movimientos en secuencia.\nCompleta la calibración para activar WHILE.", originales["ButtonExpansion1"], originales["ButtonWhile"], Color("69dba2"))
	_etapa(ruta, "02  /  SECTOR 2×3", "Tres casillas nuevas y depósitos aleatorios.\nIncluye IF / ELSE para detectar minerales y tomar decisiones.", originales["ButtonExpansion2"], originales["ButtonIf"], Color("69dba2"))
	_etapa(ruta, "03  /  SECTOR 3×3", "Completa Señales inciertas para habilitar esta expansión.\nIncluye FOR e IN RANGE para recorrer el cuadrante.", originales["ButtonExpansion3"], originales["ButtonFor"], Color("69dba2"))
	_etapa(ruta, "04  /  PARÁMETROS Y VARIABLES", "Continúa las misiones del Sector 3×3 para reutilizar valores en tus programas.", null, originales["ButtonVariables"], Color("84bfe8"))
	_texto(ruta, "MEJORA OPCIONAL  /  Independiente de la ruta", 16, Color("ecc576"))
	_etapa(ruta, "MINERÍA RÁPIDA", "Reduce el tiempo de extracción a 1 segundo.", originales["ButtonMineria"], null, Color("ecc576"))


static func _etapa(destino: Control, titulo: String, detalle: String, compra: Button, conocimiento: Button, color: Color) -> void:
	var tarjeta := PanelContainer.new()
	tarjeta.add_theme_stylebox_override("panel", _estilo(Color("172730"), color.darkened(0.5)))
	destino.add_child(tarjeta)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 24)
	tarjeta.add_child(fila)
	var contenido := VBoxContainer.new()
	contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenido.add_theme_constant_override("separation", 10)
	fila.add_child(contenido)
	_texto(contenido, titulo, 20, color)
	_texto(contenido, detalle, 16, Color("c2d0d6"))
	if conocimiento != null:
		conocimiento.reparent(contenido)
		conocimiento.flat = true
		conocimiento.mouse_filter = Control.MOUSE_FILTER_IGNORE
		conocimiento.focus_mode = Control.FOCUS_NONE
		conocimiento.alignment = HORIZONTAL_ALIGNMENT_LEFT
		conocimiento.add_theme_color_override("font_disabled_color", Color("8dbbd0"))
		conocimiento.add_theme_font_size_override("font_size", 14)
		conocimiento.show()
	if compra != null:
		compra.reparent(fila)
		compra.custom_minimum_size = Vector2(280, 76)
		compra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		compra.add_theme_font_size_override("font_size", 17)
		compra.show()


static func _texto(destino: Control, contenido: String, tamano: int, color: Color) -> void:
	var label := Label.new()
	label.text = contenido
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", tamano)
	label.add_theme_color_override("font_color", color)
	destino.add_child(label)


static func _estilo(fondo: Color, borde: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.border_color = borde
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(12)
	estilo.content_margin_left = 22
	estilo.content_margin_right = 22
	estilo.content_margin_top = 18
	estilo.content_margin_bottom = 18
	return estilo
