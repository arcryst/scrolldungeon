extends Node2D
class_name ScrollController

# Preload modular systems
const ScrollInputHandler = preload("res://scripts/game/ScrollInputHandler.gd")
const LayerLayout = preload("res://scripts/game/LayerLayout.gd")
const CameraController = preload("res://scripts/game/CameraController.gd")

# Core systems - these are now independent modules
var input_handler: ScrollInputHandler
var layout_manager: LayerLayout
var camera_controller: CameraController

# Core scrolling settings
@export var layers_visible: int = 5      # Keep more layers loaded
@export var auto_scroll_enabled: bool = true

# Camera and layer management
@onready var camera = $Camera2D
@onready var layer_container = $LayerContainer
@onready var game_manager = $GameManager

var layers: Array[BaseLayer] = []
var max_depth_reached: int = 0           # Track deepest layer created
var drag_start_camera_y: float = 0.0  # Camera position when drag started

signal layer_revealed(layer)
signal scroll_completed
signal depth_changed(new_depth)  # New signal for depth changes

func _ready():
	setup_modular_systems()
	setup_initial_layers()
	connect_signals()

func setup_modular_systems():
	# Create and setup independent systems
	input_handler = ScrollInputHandler.new()
	layout_manager = LayerLayout.new()
	camera_controller = CameraController.new()
	
	# Add them to the scene tree
	add_child(input_handler)
	add_child(layout_manager)
	add_child(camera_controller)
	
	# Setup camera controller with actual camera
	camera_controller.setup_camera(camera, layout_manager.get_layer_height())
	
	print("🎮 Modular systems initialized")

func setup_initial_layers():
	print("Setting up initial layers...")
	
	# Create the first batch of layers
	for i in range(layers_visible + 2):
		create_layer_at_depth(i)
	
	# Update camera bounds
	camera_controller.update_layer_bounds(max_depth_reached)
	
	max_depth_reached = layers_visible + 1

func create_layer_at_depth(depth: int):
	# Generate the layer using the layout manager for proper sizing
	var layer = LayerGenerator.generate_layer(depth)
	
	# Position layer using layout manager
	layer.position = layout_manager.calculate_layer_position(depth)
	
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

func connect_signals():
	# Connect input handler signals
	input_handler.scroll_up_requested.connect(_on_scroll_up_requested)
	input_handler.scroll_down_requested.connect(_on_scroll_down_requested)
	input_handler.drag_started.connect(_on_drag_started)
	input_handler.drag_updated.connect(_on_drag_updated)
	input_handler.drag_ended.connect(_on_drag_ended)
	
	# Connect layout manager signals
	layout_manager.viewport_size_changed.connect(_on_viewport_size_changed)
	layout_manager.layout_updated.connect(_on_layout_updated)
	
	# Connect camera controller signals
	camera_controller.scroll_animation_started.connect(_on_scroll_animation_started)
	camera_controller.scroll_animation_completed.connect(_on_scroll_animation_completed)
	camera_controller.camera_position_changed.connect(_on_camera_position_changed)

# Input handler signal responses
func _on_scroll_up_requested():
	if camera_controller.scroll_up():
		update_game_depth()
		ensure_layers_behind()

func _on_scroll_down_requested():
	if camera_controller.scroll_down():
		update_game_depth()
		ensure_layers_ahead()

func _on_drag_started(start_y: float):
	drag_start_camera_y = camera_controller.get_camera_position().y
	camera_controller.start_drag_from_position(drag_start_camera_y)

func _on_drag_updated(current_y: float, drag_distance: float):
	camera_controller.update_drag_position(drag_distance, drag_start_camera_y)

func _on_drag_ended(end_y: float):
	camera_controller.end_drag_and_snap()
	update_game_depth()
	ensure_layers_ahead()
	ensure_layers_behind()

# Layout manager signal responses
func _on_viewport_size_changed(new_size: Vector2):
	camera_controller.update_layer_height(new_size.y)
	update_all_layer_positions()

func _on_layout_updated():
	# Update all existing layers with new layout
	for layer in layers:
		if layer != null:
			layout_manager.update_layer_layout(layer)

# Camera controller signal responses
func _on_scroll_animation_started():
	# Can be used for UI feedback or preventing input
	pass

func _on_scroll_animation_completed():
	scroll_completed.emit()
	cleanup_distant_layers()

func _on_camera_position_changed(new_position: Vector2):
	# Can be used for real-time updates if needed
	pass

# Layer management methods (cleaned up)
func ensure_layers_ahead():
	var current_index = camera_controller.get_current_layer_index()
	var layers_needed = current_index + layers_visible + 1
	
	for depth in range(max_depth_reached + 1, layers_needed + 1):
		create_layer_at_depth(depth)
	
	camera_controller.update_layer_bounds(max_depth_reached)

func ensure_layers_behind():
	var current_index = camera_controller.get_current_layer_index()
	var start_depth = max(0, current_index - layers_visible)
	
	for depth in range(start_depth, current_index):
		if depth >= layers.size() or layers[depth] == null:
			create_layer_at_depth(depth)

func update_all_layer_positions():
	# Update all layer positions when layout changes
	for i in range(layers.size()):
		if layers[i] != null:
			layers[i].position = layout_manager.calculate_layer_position(i)

func cleanup_distant_layers():
	var current_index = camera_controller.get_current_layer_index()
	var cleanup_distance = layers_visible * 2
	
	for i in range(layers.size()):
		if layers[i] != null:
			var distance_from_current = abs(i - current_index)
			
			if distance_from_current > cleanup_distance:
				print("Cleaning up distant layer %d" % i)
				layers[i].queue_free()
				layers[i] = null

func update_game_depth():
	var current_index = camera_controller.get_current_layer_index()
	game_manager.current_depth = current_index
	depth_changed.emit(current_index)

# Layer event handlers (unchanged)
func _on_layer_interacted(layer):
	print("🎯 Interacting with: %s" % layer.layer_title)

func _on_layer_completed(layer):
	print("✅ Completed: %s" % layer.layer_title)
	
	# Apply effects through GameManager
	if layer.damage_amount > 0:
		game_manager.take_damage(layer.damage_amount)
		camera_controller.add_screen_shake(0.3, 10.0)
	
	if layer.reward_gold > 0:
		game_manager.add_gold(layer.reward_gold)
	
	game_manager.increase_depth()
	
	# Auto-scroll to next layer
	if auto_scroll_enabled and not camera_controller.is_camera_animating():
		await get_tree().create_timer(0.5).timeout
		if camera_controller.scroll_down():
			update_game_depth()
			ensure_layers_ahead()

# Debug functions
func get_current_layer() -> BaseLayer:
	var current_index = camera_controller.get_current_layer_index()
	if current_index < layers.size() and layers[current_index] != null:
		return layers[current_index]
	return null

func debug_print_layers():
	print("=== Layer Debug Info ===")
	print("Current index: %d" % camera_controller.get_current_layer_index())
	print("Max depth: %d" % max_depth_reached)
	print("Layers array size: %d" % layers.size())
	
	for i in range(layers.size()):
		if layers[i] != null:
			print("Layer %d: %s" % [i, layers[i].layer_title])
		else:
			print("Layer %d: NULL" % i)
