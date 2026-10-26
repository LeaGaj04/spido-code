extends Control
## Panel de Depuración y Atajos para Pruebas (Solo Desarrollo)
## Para eliminar después: borrar este archivo y remover la referencia en interfaz.gd.

var interfaz: Control
var mundo: Node3D
var panel_flotante: PanelContainer
var label_estado: Label
var boton_turbo_ref: Button
var boton_toggle_top: Button

func _ready() -> void:
	interfaz = get_parent() as Control
	if interfaz == null:
		return
	mundo = interfaz.get_parent() as Node3D

	# 1. Crear botón de acceso en la barra superior junto a MEJORAS y CÓDICE
	var contenedor_top = interfaz.get_node_or_null("ContenedorTienda") as HBoxContainer
	if contenedor_top != null:
		boton_toggle_top = Button.new()
		boton_toggle_top.name = "BotonDevTest"
		boton_toggle_top.text = "🛠️ TEST (F1)"
		boton_toggle_top.add_theme_color_override("font_color", Color("f6ad55"))
		boton_toggle_top.add_theme_font_size_override("font_size", 18)
		var sb_norm := StyleBoxFlat.new()
		sb_norm.bg_color = Color("2d2417", 0.85)
		sb_norm.border_color = Color("ed8936")
		sb_norm.set_border_width_all(2)
		sb_norm.set_corner_radius_all(6)
		boton_toggle_top.add_theme_stylebox_override("normal", sb_norm)
		boton_toggle_top.pressed.connect(toggle_panel)
		contenedor_top.add_child(boton_toggle_top)

	# 2. Crear panel flotante
	_crear_panel_flotante()

func _crear_panel_flotante() -> void:
	panel_flotante = PanelContainer.new()
	panel_flotante.name = "VentanaDevTest"
	panel_flotante.visible = false
	panel_flotante.z_index = 100
	panel_flotante.custom_minimum_size = Vector2(440, 560)
	panel_flotante.position = Vector2(60, 70)

	var sb_panel := StyleBoxFlat.new()
	sb_panel.bg_color = Color(0.08, 0.11, 0.14, 0.96)
	sb_panel.border_color = Color("ed8936")
	sb_panel.set_border_width_all(2)
	sb_panel.set_corner_radius_all(8)
	panel_flotante.add_theme_stylebox_override("panel", sb_panel)
	add_child(panel_flotante)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 16)
	margen.add_theme_constant_override("margin_right", 16)
	margen.add_theme_constant_override("margin_top", 14)
	margen.add_theme_constant_override("margin_bottom", 14)
	panel_flotante.add_child(margen)

	var v_box := VBoxContainer.new()
	v_box.add_theme_constant_override("separation", 10)
	margen.add_child(v_box)

	# Cabecera
	var h_top := HBoxContainer.new()
	v_box.add_child(h_top)
	var lbl_titulo := Label.new()
	lbl_titulo.text = "🛠️ MODO TEST / ATAJOS"
	lbl_titulo.add_theme_font_size_override("font_size", 18)
	lbl_titulo.add_theme_color_override("font_color", Color("f6ad55"))
	lbl_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_top.add_child(lbl_titulo)

	var btn_cerrar := Button.new()
	btn_cerrar.text = "✕"
	btn_cerrar.custom_minimum_size = Vector2(32, 28)
	btn_cerrar.pressed.connect(func(): panel_flotante.visible = false)
	h_top.add_child(btn_cerrar)

	# Leyenda de atajos de teclado
	var lbl_shortcuts := Label.new()
	lbl_shortcuts.text = "Atajos de teclado:\n[F1] Abrir/Cerrar | [F2] +50 Min | [F3] Pasar Misión\n[F4] Turbo Spid (5x) | [F5] Desbloquear Todo"
	lbl_shortcuts.add_theme_font_size_override("font_size", 12)
	lbl_shortcuts.add_theme_color_override("font_color", Color("a0aec0"))
	v_box.add_child(lbl_shortcuts)

	# Estado actual
	label_estado = Label.new()
	label_estado.add_theme_font_size_override("font_size", 13)
	label_estado.add_theme_color_override("font_color", Color("68d391"))
	v_box.add_child(label_estado)

	# Separador
	v_box.add_child(HSeparator.new())

	# Botones de Acciones Rápidas
	var lbl_acc := Label.new()
	lbl_acc.text = "ACCIONES RÁPIDAS:"
	lbl_acc.add_theme_font_size_override("font_size", 13)
	lbl_acc.add_theme_color_override("font_color", Color("ecc94b"))
	v_box.add_child(lbl_acc)

	var grid_acc := GridContainer.new()
	grid_acc.columns = 2
	grid_acc.add_theme_constant_override("h_separation", 8)
	grid_acc.add_theme_constant_override("v_separation", 6)
	v_box.add_child(grid_acc)

	var btn_min := Button.new()
	btn_min.text = "+50 Minerales (F2)"
	btn_min.pressed.connect(func(): dar_minerales(50))
	grid_acc.add_child(btn_min)

	var btn_next := Button.new()
	btn_next.text = "Completar Misión (F3)"
	btn_next.pressed.connect(completar_mision_actual)
	grid_acc.add_child(btn_next)

	boton_turbo_ref = Button.new()
	boton_turbo_ref.text = "Turbo Spid: OFF (F4)"
	boton_turbo_ref.pressed.connect(alternar_turbo)
	grid_acc.add_child(boton_turbo_ref)

	var btn_all := Button.new()
	btn_all.text = "Desbloquear Todo (F5)"
	btn_all.pressed.connect(desbloquear_todo)
	grid_acc.add_child(btn_all)

	# Separador
	v_box.add_child(HSeparator.new())

	# Salto a Fases
	var lbl_fases := Label.new()
	lbl_fases.text = "SALTAR DIRECTAMENTE A FASE:"
	lbl_fases.add_theme_font_size_override("font_size", 13)
	lbl_fases.add_theme_color_override("font_color", Color("63b3ed"))
	v_box.add_child(lbl_fases)

	var scroll_fases := ScrollContainer.new()
	scroll_fases.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_fases.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v_box.add_child(scroll_fases)

	var v_fases := VBoxContainer.new()
	v_fases.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v_fases.add_theme_constant_override("separation", 5)
	scroll_fases.add_child(v_fases)

	_boton_fase(v_fases, "F1: Primer Mineral (Base 1x1)", "recolectar_primer_mineral", 0, {})
	_boton_fase(v_fases, "F1: Ruta Calibración (Corredor 1x3)", "ruta_calibracion", 1, {})
	_boton_fase(v_fases, "F2: While Continuo (Corredor 1x3)", "trabajo_continuo", 1, {"while": true})
	_boton_fase(v_fases, "F2: Cuota Suministro (While < 10)", "cuota_suministro", 1, {"while": true})
	_boton_fase(v_fases, "F3: Señales Inciertas (Sector 2x3 + IF/ELSE)", "senales_inciertas", 2, {"while": true, "if": true, "else": true})
	_boton_fase(v_fases, "F4: Ciclo For (Sector 2x3 + Range)", "ciclo_recoleccion", 2, {"while": true, "if": true, "else": true, "for": true, "in range": true})
	_boton_fase(v_fases, "F4.5: Rover Autónomo (While + For + If)", "patrulla_autonoma", 2, {"while": true, "if": true, "else": true, "for": true, "in range": true})
	_boton_fase(v_fases, "F5: Variables (Sector 3x3)", "calibracion_variables", 3, {"while": true, "if": true, "else": true, "for": true, "in range": true})
	_boton_fase(v_fases, "F5.5: Telemetría Dinámica (tamano_mundo)", "telemetria_dinamica", 3, {"while": true, "if": true, "else": true, "for": true, "in range": true, "tamano_mundo": true})
	_boton_fase(v_fases, "F6: Listas y Mover (Sector 4x3)", "patrulla_lista", 4, {"while": true, "if": true, "else": true, "for": true, "in range": true, "tamano_mundo": true, "listas": true})
	_boton_fase(v_fases, "F7: Funciones def (Sector 4x4)", "rutina_funciones", 5, {"while": true, "if": true, "else": true, "for": true, "in range": true, "tamano_mundo": true, "listas": true, "def": true})

func _boton_fase(contenedor: Control, label: String, mision_id: String, tier: int, sintaxis: Dictionary) -> void:
	var btn := Button.new()
	btn.text = label
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(func(): saltar_a_fase(mision_id, tier, sintaxis))
	contenedor.add_child(btn)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			toggle_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F2:
			dar_minerales(50)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F3:
			completar_mision_actual()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F4:
			alternar_turbo()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F5:
			desbloquear_todo()
			get_viewport().set_input_as_handled()

func toggle_panel() -> void:
	if panel_flotante == null:
		return
	panel_flotante.visible = not panel_flotante.visible
	if panel_flotante.visible:
		actualizar_estado_visual()

func actualizar_estado_visual() -> void:
	if label_estado == null or interfaz == null:
		return
	var mis: String = MissionService.objective_id
	var min_n: int = int(interfaz.minerales_nave)
	var spid = interfaz.get("mi_spid")
	var turbo_txt: String = "ON" if spid != null and spid.get("duracion_paso") != null and spid.duracion_paso < 0.2 else "OFF"
	label_estado.text = "Misión: %s\nMinerales nave: %d | Turbo Spid: %s" % [mis, min_n, turbo_txt]
	if boton_turbo_ref != null:
		boton_turbo_ref.text = "Turbo Spid: " + turbo_txt + " (F4)"

func dar_minerales(cantidad: int) -> void:
	if interfaz == null:
		return
	interfaz.minerales_nave += cantidad
	interfaz.actualizar_contadores()
	interfaz.actualizar_mejoras_visual()
	actualizar_estado_visual()
	if interfaz.get("transmision_ada") != null:
		interfaz.transmision_ada.mostrar_mensaje("🛠️ TEST: +%d minerales entregados a la nave (Total: %d)." % [cantidad, interfaz.minerales_nave], "progreso", 3.0)

func completar_mision_actual() -> void:
	if interfaz == null:
		return
	var mision_actual := MissionService.objective_id
	MissionService.objective_completed = true
	if mision_actual not in MissionService.completed_missions:
		MissionService.completed_missions.append(mision_actual)
	MissionService.mision_completada.emit(mision_actual)
	MissionService.preparar_mision_expansion()
	interfaz.actualizar_panel_mision({})
	interfaz.actualizar_mejoras_visual()
	actualizar_estado_visual()
	if interfaz.get("transmision_ada") != null:
		interfaz.transmision_ada.mostrar_mensaje("🛠️ TEST: Misión '%s' forzada como completada." % mision_actual, "completado", 3.0)

func alternar_turbo() -> void:
	if interfaz == null:
		return
	var spid = interfaz.get("mi_spid")
	if spid != null and spid.has_method("alternar_modo_rapido"):
		var activado: bool = spid.alternar_modo_rapido()
		actualizar_estado_visual()
		if interfaz.get("transmision_ada") != null:
			interfaz.transmision_ada.mostrar_mensaje("🛠️ TEST: Turbo Spid %s (0.06s por paso)." % ("ACTIVADO" if activado else "DESACTIVADO"), "progreso", 2.5)

func desbloquear_todo() -> void:
	if interfaz == null or mundo == null:
		return
	GestorSintaxis.aplicar_sintaxis_desbloqueada({
		"for": true,
		"while": true,
		"if": true,
		"else": true,
		"in range": true,
		"tamano_mundo": true,
		"listas": true,
		"def": true
	})
	interfaz.minerales_nave += 100
	mundo.aplicar_progreso_mapa(5)
	mundo.resetear_posicion_spid()
	mundo.generar_minerales_iniciales()
	interfaz.actualizar_contadores()
	interfaz.actualizar_mejoras_visual()
	actualizar_estado_visual()
	if interfaz.get("transmision_ada") != null:
		interfaz.transmision_ada.mostrar_mensaje("🛠️ TEST: Todo desbloqueado (Sintaxis completa, 4x4 y 100 minerales).", "completado", 4.0)

func saltar_a_fase(mision_id: String, tier: int, sintaxis: Dictionary) -> void:
	if interfaz == null or mundo == null:
		return

	# Detener cualquier ejecución previa
	CodeExecutor.detener_ejecucion()

	# Configurar mapa y sintaxis
	mundo.aplicar_progreso_mapa(tier)
	GestorSintaxis.aplicar_sintaxis_desbloqueada(sintaxis)

	# Iniciar misión correspondiente
	match mision_id:
		"recolectar_primer_mineral":
			MissionService.iniciar_mision()
		"ruta_calibracion":
			MissionService.iniciar_ruta_calibracion()
		"trabajo_continuo":
			MissionService.iniciar_trabajo_continuo()
		"cuota_suministro":
			MissionService.iniciar_cuota_suministro()
		"senales_inciertas":
			MissionService.iniciar_senales_inciertas()
		"ciclo_recoleccion":
			MissionService.iniciar_ciclo_recoleccion()
		"patrulla_autonoma":
			MissionService.iniciar_patrulla_autonoma()
		"calibracion_variables":
			MissionService.iniciar_calibracion_variables()
		"telemetria_dinamica":
			MissionService.iniciar_telemetria_dinamica()
		"patrulla_lista":
			MissionService.iniciar_patrulla_lista()
		"rutina_funciones":
			MissionService.iniciar_rutina_funciones()
		_:
			MissionService.iniciar_mision()

	mundo.resetear_posicion_spid()
	mundo.generar_minerales_iniciales()
	interfaz.actualizar_panel_mision({})
	interfaz.actualizar_mejoras_visual()
	actualizar_estado_visual()

	if interfaz.get("transmision_ada") != null:
		interfaz.transmision_ada.mostrar_mensaje("🛠️ TEST: Saltaste a '%s' (Tier %d)." % [mision_id, tier], "progreso", 4.0)
