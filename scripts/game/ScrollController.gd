extends Node2D
class_name ScrollController

# Core scrolling settings
@export var scroll_speed: float = 800.0
@export var layers_visible: int = 5      # Keep more layers loaded
@export var auto_scroll_enabled: bool = true
@export var scroll_debounce_time: float = 0.8  # Longer debounce to prevent multiple scrolls

# Camera and layer management
@onready var camera = $Camera2D
@onready var layer_container = $LayerContainer
@onready var game_manager = $GameManager

var layers: Array[BaseLayer] = []
var current_layer_index: int = 0
var max_depth_reached: int = 0           # Track deepest layer created
var target_scroll_position: float = 0.0
var is_scrolling: bool = false
var scroll_input_threshold: float = 50.0
var last_scroll_time: float = 0.0

# Track viewport size
var viewport_height: float = 0.0

# Touch/scroll input tracking
var touch_start_y: float = 0.0
var is_touching: bool = false
var drag_start_camera_y: float = 0.0  # Camera position when drag started

signal layer_revealed(layer)
signal scroll_completed
signal depth_changed(new_depth)  # New signal for depth changes

func _ready():
	viewport_height = get_viewport_rect().size.y
	setup_camera()
	setup_initial_layers()
	connect_signals()

func setup_camera():
	camera.position = Vector2.ZERO
	camera.enabled = true

func setup_initial_layers():
	print("Setting up initial layers...")
	
	# Create the first batch of layers
	for i in range(layers_visible + 2):
		create_layer_at_depth(i)
	
	# Position camera at first layer
	target_scroll_position = 0.0
	camera.position.y = 0.0
	max_depth_reached = layers_visible + 1

func create_layer_at_depth(depth: int):
	# Generate the layer
	var layer = LayerGenerator.generate_layer(depth)
	
	# Position layer using viewport height
	layer.position.y = depth * viewport_height
	layer.position.x = 0
	
	# Connect layer signals
	layer.layer_interacted.connect(_on_layer_interacted)
	layer.layer_completed.connect(_on_layer_completed)
	
	# Add to container
	layer_container.add_child(layer)
	
	# Store in array with proper indexing
	while layers.size() <= depth:
		layers.append(null)
	layers[depth] = layer
	
	# Update max depth
	max_depth_reached = max(max_depth_reached, depth)
	
	# Emit signal
	layer_revealed.emit(layer)
	
	print("Created layer %d: %s at Y=%d" % [depth, layer.layer_title, int(layer.position.y)])

func _unhandled_input(event):
	handle_scroll_input(event)

func handle_scroll_input(event):
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Simple time-based debouncing for discrete scroll inputs only
	var can_discrete_scroll = (current_time - last_scroll_time) >= scroll_debounce_time and not is_scrolling
	
	# Handle trackpad pan gestures
	if event is InputEventPanGesture:
		if can_discrete_scroll:
			last_scroll_time = current_time
			if event.delta.y > 0:
				scroll_to_next_layer()
			elif event.delta.y < 0:
				scroll_to_previous_layer()
		get_viewport().set_input_as_handled()
		return
	
	# Handle mouse wheel
	elif event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		if can_discrete_scroll:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					last_scroll_time = current_time
					scroll_to_previous_layer()
					get_viewport().set_input_as_handled()
				MOUSE_BUTTON_WHEEL_DOWN:
					last_scroll_time = current_time
					scroll_to_next_layer()
					get_viewport().set_input_as_handled()
	
	# Handle mouse button events for drag detection
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		print("Mouse button event: pressed=%s, position=%s" % [event.pressed, event.position])
		if event.pressed:
			start_touch_input(event.position.y)
		else:
			end_touch_input(event.position.y)
	
	# Handle touch input for mobile
	elif event is InputEventScreenTouch:
		print("Screen touch event: pressed=%s, position=%s" % [event.pressed, event.position])
		if event.pressed:
			start_touch_input(event.position.y)
		else:
			end_touch_input(event.position.y)
	
	# Handle drag input for mobile
	elif event is InputEventScreenDrag:
		print("Screen drag event: position=%s" % event.position)
		handle_drag_input(event.position.y)
	
	# Handle mouse drag
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		print("Mouse motion event: position=%s, is_touching=%s" % [event.position, is_touching])
		# Only handle drag if we've already started touching
		if is_touching:
			handle_drag_input(event.position.y)
	
	# Keyboard shortcuts for testing
	elif event.is_action_pressed("ui_down"):
		if can_discrete_scroll:
			last_scroll_time = current_time
			scroll_to_next_layer()
	elif event.is_action_pressed("ui_up"):
		if can_discrete_scroll:
			last_scroll_time = current_time
			scroll_to_previous_layer()

func start_touch_input(y_position: float):
	if is_scrolling:
		return  # Don't start drag during animations
		
	touch_start_y = y_position
	is_touching = true
	drag_start_camera_y = camera.position.y
	print("Started drag: touch_y=%f, camera_y=%f" % [y_position, camera.position.y])

func end_touch_input(y_position: float):
	if not is_touching:
		return
		
	is_touching = false
	
	# Calculate which layer we're closest to and snap to it
	var current_camera_y = camera.position.y
	var closest_layer_index = round(current_camera_y / viewport_height)
	
	print("End drag: camera_y=%f, viewport_height=%f, closest_index=%f" % [current_camera_y, viewport_height, closest_layer_index])
	
	# Clamp to valid layer range
	closest_layer_index = max(0, closest_layer_index)
	
	# Ensure we don't go beyond created layers
	if closest_layer_index > max_depth_reached:
		closest_layer_index = max_depth_reached
		# Create more layers if needed
		for depth in range(max_depth_reached + 1, closest_layer_index + layers_visible):
			create_layer_at_depth(depth)
	
	# Update our current layer index and snap to it
	current_layer_index = int(closest_layer_index)
	target_scroll_position = current_layer_index * viewport_height
	
	print("Snapping to layer %d at position %f" % [current_layer_index, target_scroll_position])
	
	# Update game depth
	game_manager.current_depth = current_layer_index
	depth_changed.emit(current_layer_index)
	
	# Smooth snap to the nearest layer
	start_scroll_animation()
	
	# Ensure layers exist around our new position
	ensure_layers_ahead()
	ensure_layers_behind()

func handle_drag_input(absolute_y: float):
	if not is_touching or is_scrolling:
		return
	
	# Calculate how far we've dragged from the starting point
	var drag_distance = absolute_y - touch_start_y
	
	# Move camera directly based on drag (inverted for natural feel)
	var new_camera_y = drag_start_camera_y - drag_distance
	
	# Clamp camera position to reasonable bounds
	var min_y = 0
	var max_y = max_depth_reached * viewport_height
	camera.position.y = clamp(new_camera_y, min_y, max_y)
	
	print("Dragging: drag_distance=%f, new_camera_y=%f, clamped_y=%f" % [drag_distance, new_camera_y, camera.position.y])

func scroll_to_next_layer():
	if is_scrolling:
		return
	
	current_layer_index += 1
	target_scroll_position = current_layer_index * viewport_height
	start_scroll_animation()
	
	# Update game depth when scrolling to new layer
	game_manager.current_depth = current_layer_index
	depth_changed.emit(current_layer_index)
	
	# Ensure layers exist ahead
	ensure_layers_ahead()

func scroll_to_previous_layer():
	if is_scrolling or current_layer_index <= 0:
		return
		
	current_layer_index -= 1
	target_scroll_position = current_layer_index * viewport_height
	start_scroll_animation()
	
	# Update game depth when scrolling back
	game_manager.current_depth = current_layer_index
	depth_changed.emit(current_layer_index)
	
	# Ensure layers exist behind
	ensure_layers_behind()

func ensure_layers_ahead():
	# Create layers ahead of current position
	var layers_needed = current_layer_index + layers_visible + 1
	
	for depth in range(max_depth_reached + 1, layers_needed + 1):
		create_layer_at_depth(depth)

func ensure_layers_behind():
	# Recreate layers behind current position if they don't exist
	var start_depth = max(0, current_layer_index - layers_visible)
	
	for depth in range(start_depth, current_layer_index):
		if depth >= layers.size() or layers[depth] == null:
			create_layer_at_depth(depth)

func start_scroll_animation():
	is_scrolling = true
	
	# Smooth snap animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	
	tween.tween_property(camera, "position:y", target_scroll_position, 0.3)  # Quick snap
	tween.tween_callback(finish_scroll_animation)

func finish_scroll_animation():
	is_scrolling = false
	scroll_completed.emit()
	
	# Clean up distant layers after scrolling
	cleanup_distant_layers()

func cleanup_distant_layers():
	# Only remove layers that are very far away
	var cleanup_distance = layers_visible * 2
	
	for i in range(layers.size()):
		if layers[i] != null:
			var distance_from_current = abs(i - current_layer_index)
			
			if distance_from_current > cleanup_distance:
				print("Cleaning up distant layer %d" % i)
				layers[i].queue_free()
				layers[i] = null

func _process(delta):
	# Update viewport height if changed
	var new_height = get_viewport_rect().size.y
	if new_height != viewport_height:
		viewport_height = new_height
		update_layer_positions()

func update_layer_positions():
	# Update all layer positions based on new viewport height
	for i in range(layers.size()):
		if layers[i] != null:
			layers[i].position.y = i * viewport_height

func _on_layer_interacted(layer):
	print("🎯 Interacting with: %s" % layer.layer_title)

func _on_layer_completed(layer):
	print("✅ Completed: %s" % layer.layer_title)
	
	# Apply effects through GameManager
	if layer.damage_amount > 0:
		game_manager.take_damage(layer.damage_amount)
		add_screen_shake(0.3, 10.0)
	
	if layer.reward_gold > 0:
		game_manager.add_gold(layer.reward_gold)
	
	game_manager.increase_depth()
	
	# Auto-scroll to next layer
	if auto_scroll_enabled and not is_scrolling:
		await get_tree().create_timer(0.5).timeout
		scroll_to_next_layer()

func add_screen_shake(duration: float, intensity: float):
	var original_pos = camera.position
	var tween = create_tween()
	
	var shake_timer = 0.0
	while shake_timer < duration:
		var shake_x = randf_range(-intensity, intensity)
		var shake_y = randf_range(-intensity, intensity)
		camera.position = original_pos + Vector2(shake_x, shake_y)
		
		await get_tree().process_frame
		shake_timer += get_process_delta_time()
	
	camera.position = original_pos

func connect_signals():
	if game_manager:
		game_manager.player_died.connect(_on_player_died)

func _on_player_died():
	print("💀 Game Over at depth %d!" % game_manager.current_depth)

# Debug functions
func get_current_layer() -> BaseLayer:
	if current_layer_index < layers.size() and layers[current_layer_index] != null:
		return layers[current_layer_index]
	return null

func debug_print_layers():
	print("=== Layer Debug Info ===")
	print("Current index: %d" % current_layer_index)
	print("Max depth: %d" % max_depth_reached)
	print("Layers array size: %d" % layers.size())
	
	for i in range(layers.size()):
		if layers[i] != null:
			print("Layer %d: %s" % [i, layers[i].layer_title])
		else:
			print("Layer %d: NULL" % i)
