extends Node
class_name ScrollInputHandler

# Input handling signals
signal scroll_up_requested
signal scroll_down_requested
signal drag_started(start_y: float)
signal drag_updated(current_y: float, drag_distance: float)
signal drag_ended(end_y: float)

# Input settings
@export var scroll_debounce_time: float = 0.8
@export var drag_threshold: float = 10.0

# Internal state
var last_scroll_time: float = 0.0
var is_dragging: bool = false
var drag_start_y: float = 0.0

func _ready():
	print("🎮 ScrollInputHandler initialized")

func _unhandled_input(event):
	handle_input_event(event)

func handle_input_event(event: InputEvent):
	var current_time = Time.get_ticks_msec() / 1000.0
	var can_discrete_scroll = (current_time - last_scroll_time) >= scroll_debounce_time
	
	# Handle trackpad pan gestures
	if event is InputEventPanGesture:
		if can_discrete_scroll:
			last_scroll_time = current_time
			if event.delta.y > 0:
				scroll_down_requested.emit()
			elif event.delta.y < 0:
				scroll_up_requested.emit()
		get_viewport().set_input_as_handled()
		return
	
	# Handle mouse wheel
	elif event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		if can_discrete_scroll:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					last_scroll_time = current_time
					scroll_up_requested.emit()
					get_viewport().set_input_as_handled()
				MOUSE_BUTTON_WHEEL_DOWN:
					last_scroll_time = current_time
					scroll_down_requested.emit()
					get_viewport().set_input_as_handled()
	
	# Handle mouse button events for drag detection
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_drag(event.position.y)
		else:
			end_drag(event.position.y)
	
	# Handle touch input for mobile
	elif event is InputEventScreenTouch:
		if event.pressed:
			start_drag(event.position.y)
		else:
			end_drag(event.position.y)
	
	# Handle drag input for mobile
	elif event is InputEventScreenDrag:
		handle_drag(event.position.y)
	
	# Handle mouse drag
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if is_dragging:
			handle_drag(event.position.y)
	
	# Keyboard shortcuts for testing
	elif event.is_action_pressed("ui_down"):
		if can_discrete_scroll:
			last_scroll_time = current_time
			scroll_down_requested.emit()
	elif event.is_action_pressed("ui_up"):
		if can_discrete_scroll:
			last_scroll_time = current_time
			scroll_up_requested.emit()

func start_drag(y_position: float):
	drag_start_y = y_position
	is_dragging = true
	drag_started.emit(y_position)
	print("🎯 Drag started at Y: %f" % y_position)

func handle_drag(current_y: float):
	if not is_dragging:
		return
	
	var drag_distance = current_y - drag_start_y
	drag_updated.emit(current_y, drag_distance)

func end_drag(y_position: float):
	if not is_dragging:
		return
		
	is_dragging = false
	drag_ended.emit(y_position)
	print("🎯 Drag ended at Y: %f" % y_position)

# Public methods for external state management
func is_currently_dragging() -> bool:
	return is_dragging

func reset_drag_state():
	is_dragging = false
	drag_start_y = 0.0 