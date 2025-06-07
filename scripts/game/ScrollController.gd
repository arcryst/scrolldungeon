extends Node2D
class_name ScrollController

# Core scrolling settings
@export var scroll_speed: float = 800.0
@export var layers_visible: int = 5      # Keep more layers loaded
@export var auto_scroll_enabled: bool = true

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

# Track viewport size
var viewport_height: float = 0.0

# Touch/scroll input tracking
var touch_start_y: float = 0.0
var is_touching: bool = false
var scroll_velocity: float = 0.0

signal layer_revealed(layer)
signal scroll_completed

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

func _input(event):
	handle_scroll_input(event)

func handle_scroll_input(event):
	# Touch/Mouse input for scrolling
	if event is InputEventScreenTouch:
		if event.pressed:
			start_touch_input(event.position.y)
		else:
			end_touch_input(event.position.y)
	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_touch_input(event.position.y)
			else:
				end_touch_input(event.position.y)
	
	elif event is InputEventScreenDrag:
		handle_drag_input(event.relative.y)
	
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		handle_drag_input(event.relative.y)
	
	# Keyboard shortcuts for testing
	elif event.is_action_pressed("ui_down"):
		scroll_to_next_layer()
	elif event.is_action_pressed("ui_up"):
		scroll_to_previous_layer()

func start_touch_input(y_position: float):
	touch_start_y = y_position
	is_touching = true
	scroll_velocity = 0.0

func end_touch_input(y_position: float):
	if not is_touching:
		return
		
	is_touching = false
	var swipe_distance = y_position - touch_start_y
	
	# Determine if this was a significant swipe
	if abs(swipe_distance) > scroll_input_threshold:
		if swipe_distance < 0:  # Swipe up = dig deeper
			scroll_to_next_layer()
		else:  # Swipe down = go back up
			scroll_to_previous_layer()

func handle_drag_input(relative_y: float):
	if not is_touching:
		return
	scroll_velocity = relative_y * 0.1

func scroll_to_next_layer():
	if is_scrolling:
		return
	
	current_layer_index += 1
	target_scroll_position = current_layer_index * viewport_height
	start_scroll_animation()
	
	print("Scrolling to layer %d" % current_layer_index)
	
	# Update game depth when scrolling to new layer
	game_manager.current_depth = current_layer_index
	
	# Ensure layers exist ahead
	ensure_layers_ahead()

func scroll_to_previous_layer():
	if is_scrolling or current_layer_index <= 0:
		return
		
	current_layer_index -= 1
	target_scroll_position = current_layer_index * viewport_height
	start_scroll_animation()
	
	print("Scrolling back to layer %d" % current_layer_index)
	
	# Update game depth when scrolling back
	game_manager.current_depth = current_layer_index
	
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
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(camera, "position:y", target_scroll_position, 0.6)
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
	
	# Handle scroll velocity
	if abs(scroll_velocity) > 0.1:
		camera.position.y += scroll_velocity * delta * 60
		scroll_velocity *= 0.9

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
