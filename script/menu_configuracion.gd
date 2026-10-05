extends CanvasLayer

var panel: PanelContainer
var slider_volumen: HSlider
var check_mute: CheckButton
var boton_cerrar: Button

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS # para que funcione en pausa
	
	var color_bg = ColorRect.new()
	color_bg.color = Color(0, 0, 0, 0.7)
	color_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(color_bg)
	
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)
	
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 260)
	center_container.add_child(panel)
	
	var style_panel = StyleBoxFlat.new()
	style_panel.content_margin_left = 22.0
	style_panel.content_margin_top = 18.0
	style_panel.content_margin_right = 22.0
	style_panel.content_margin_bottom = 18.0
	style_panel.bg_color = Color(0.005, 0.055, 0.02, 0.96)
	style_panel.border_width_left = 3
	style_panel.border_width_top = 3
	style_panel.border_width_right = 3
	style_panel.border_width_bottom = 3
	style_panel.border_color = Color(0.37, 0.59, 0.42, 0.95)
	style_panel.shadow_color = Color(0.004, 0.09, 0.011, 0.85)
	style_panel.shadow_size = 12
	style_panel.shadow_offset = Vector2(8, 8)
	panel.add_theme_stylebox_override("panel", style_panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 35)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "◆ CONFIGURACIÓN ◆"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.76, 0.94, 0.78, 1))
	vbox.add_child(title)
	
	var hbox_vol = HBoxContainer.new()
	hbox_vol.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox_vol)
	var lbl_vol = Label.new()
	lbl_vol.text = "VOLUMEN"
	lbl_vol.custom_minimum_size = Vector2(130, 0)
	lbl_vol.add_theme_font_size_override("font_size", 18)
	lbl_vol.add_theme_color_override("font_color", Color(0.6, 0.86, 0.63, 1))
	hbox_vol.add_child(lbl_vol)
	slider_volumen = HSlider.new()
	slider_volumen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_volumen.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider_volumen.min_value = 0.0001
	slider_volumen.max_value = 1.0
	slider_volumen.step = 0.01
	slider_volumen.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	slider_volumen.value_changed.connect(_on_volumen_changed)
	hbox_vol.add_child(slider_volumen)
	
	var hbox_mute = HBoxContainer.new()
	hbox_mute.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox_mute)
	var lbl_mute = Label.new()
	lbl_mute.text = "MUTEAR"
	lbl_mute.custom_minimum_size = Vector2(130, 0)
	lbl_mute.add_theme_font_size_override("font_size", 18)
	lbl_mute.add_theme_color_override("font_color", Color(0.6, 0.86, 0.63, 1))
	hbox_mute.add_child(lbl_mute)
	check_mute = CheckButton.new()
	check_mute.button_pressed = AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))
	check_mute.toggled.connect(_on_mute_toggled)
	hbox_mute.add_child(check_mute)
	
	var btn_container = CenterContainer.new()
	vbox.add_child(btn_container)
	
	boton_cerrar = Button.new()
	boton_cerrar.text = "CERRAR"
	boton_cerrar.custom_minimum_size = Vector2(150, 45)
	boton_cerrar.add_theme_color_override("font_color", Color(0.76, 0.94, 0.78, 1))
	
	var style_btn = StyleBoxFlat.new()
	style_btn.bg_color = Color(0, 0.066, 0, 0.76)
	style_btn.border_width_left = 2
	style_btn.border_width_top = 2
	style_btn.border_width_right = 2
	style_btn.border_width_bottom = 2
	style_btn.border_color = Color(0.37, 0.59, 0.42, 0.85)
	style_btn.corner_radius_top_left = 12
	style_btn.corner_radius_top_right = 12
	style_btn.corner_radius_bottom_right = 12
	style_btn.corner_radius_bottom_left = 12
	boton_cerrar.add_theme_stylebox_override("normal", style_btn)
	
	var style_btn_hover = style_btn.duplicate()
	style_btn_hover.bg_color = Color(0.015, 0.12, 0.025, 0.92)
	style_btn_hover.border_color = Color(0.48, 0.76, 0.54, 1)
	boton_cerrar.add_theme_stylebox_override("hover", style_btn_hover)
	boton_cerrar.add_theme_stylebox_override("pressed", style_btn_hover)
	
	boton_cerrar.pressed.connect(_on_cerrar_pressed)
	btn_container.add_child(boton_cerrar)

func _on_volumen_changed(value: float) -> void:
	var bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))
	if value <= 0.0001:
		AudioServer.set_bus_mute(bus, true)
		check_mute.set_pressed_no_signal(true)
	else:
		if check_mute.button_pressed:
			AudioServer.set_bus_mute(bus, false)
			check_mute.set_pressed_no_signal(false)

func _on_mute_toggled(button_pressed: bool) -> void:
	var bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, button_pressed)
	if not button_pressed and slider_volumen.value <= 0.0001:
		slider_volumen.value = 0.5
		AudioServer.set_bus_volume_db(bus, linear_to_db(0.5))

func _on_cerrar_pressed() -> void:
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_cerrar_pressed()
		get_viewport().set_input_as_handled()
