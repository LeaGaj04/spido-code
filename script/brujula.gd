extends TextureRect

var is_dragging = false

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed

	elif event is InputEventMouseMotion and is_dragging:
		var new_pos = position + event.relative
		
		# Limitar a la pantalla
		var viewport_size = get_viewport_rect().size
		var actual_size = size * scale
		new_pos.x = clamp(new_pos.x, 0, viewport_size.x - actual_size.x)
		new_pos.y = clamp(new_pos.y, 0, viewport_size.y - actual_size.y)
		
		position = new_pos
