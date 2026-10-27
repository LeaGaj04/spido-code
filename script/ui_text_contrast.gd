extends Node

## Garantiza contraste consistente en todos los textos de la interfaz,
## incluso cuando una escena o script define overrides locales.

const COLOR_TEXTO := Color("F4F6F2")
const COLOR_CONTORNO := Color("202833")
const COLOR_SOMBRA := Color(0.05, 0.07, 0.1, 0.95)


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_aplicar_arbol_completo")


func _on_node_added(node: Node) -> void:
	if node is Control:
		call_deferred("_aplicar_contraste", node)


func _aplicar_arbol_completo() -> void:
	for node in get_tree().root.find_children("*", "Control", true, false):
		_aplicar_contraste(node)


func _aplicar_contraste(control: Control) -> void:
	if not is_instance_valid(control):
		return

	if control is RichTextLabel:
		control.add_theme_color_override("default_color", COLOR_TEXTO)
		control.add_theme_color_override("font_outline_color", COLOR_CONTORNO)
		control.add_theme_color_override("font_shadow_color", COLOR_SOMBRA)
		control.add_theme_constant_override("outline_size", 2)
		control.add_theme_constant_override("shadow_offset_x", 2)
		control.add_theme_constant_override("shadow_offset_y", 2)
		return

	if control is Button:
		control.add_theme_color_override("font_color", COLOR_TEXTO)
		control.add_theme_color_override("font_hover_color", Color.WHITE)
		control.add_theme_color_override("font_pressed_color", COLOR_TEXTO)
		control.add_theme_color_override("font_focus_color", Color.WHITE)
		control.add_theme_color_override("font_disabled_color", Color(0.76, 0.78, 0.78, 0.92))
		control.add_theme_color_override("font_outline_color", COLOR_CONTORNO)
		control.add_theme_color_override("font_shadow_color", COLOR_SOMBRA)
		control.add_theme_constant_override("outline_size", 2)
		control.add_theme_constant_override("shadow_offset_x", 2)
		control.add_theme_constant_override("shadow_offset_y", 2)
		return

	if control is Label or control is LineEdit or control is TextEdit:
		control.add_theme_color_override("font_color", COLOR_TEXTO)
		control.add_theme_color_override("font_outline_color", COLOR_CONTORNO)
		control.add_theme_color_override("font_shadow_color", COLOR_SOMBRA)
		control.add_theme_constant_override("outline_size", 2)
		control.add_theme_constant_override("shadow_offset_x", 2)
		control.add_theme_constant_override("shadow_offset_y", 2)
