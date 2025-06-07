extends Node
class_name CameraController

# Camera movement signals
signal scroll_animation_started
signal scroll_animation_completed
signal camera_position_changed(new_position: Vector2)

# Camera settings
@export var scroll_animation_duration: float = 0.3
@export var scroll_ease_type: Tween.EaseType = Tween.EASE_OUT
@export var scroll_transition_type: Tween.TransitionType = Tween.TRANS_QUART

# Camera references
var camera: Camera2D
var is_animating: bool = false
var target_position: Vector2

# Layer tracking
var layer_height: float = 0.0
var current_layer_index: int = 0
var max_layer_bound: float = 0.0

func _ready():
	print("📷 CameraController initialized")

func setup_camera(camera_node: Camera2D, initial_layer_height: float):
	camera = camera_node
	layer_height = initial_layer_height
	camera.position = Vector2.ZERO
	camera.enabled = true
	target_position = camera.position
	print("📷 Camera setup complete")

func update_layer_height(new_height: float):
	layer_height = new_height
	# Update all layer positions to match new height
	update_layer_bounds()

func update_layer_bounds(max_layers: int = 0):
	max_layer_bound = max_layers * layer_height

# Discrete scrolling methods
func scroll_to_layer(layer_index: int):
	if is_animating:
		return false
		
	current_layer_index = layer_index
	target_position = Vector2(0, layer_index * layer_height)
	start_scroll_animation()
	return true

func scroll_up():
	return scroll_to_layer(max(0, current_layer_index - 1))

func scroll_down():
	return scroll_to_layer(current_layer_index + 1)

# Continuous drag methods
func start_drag_from_position(drag_start_camera_y: float):
	if is_animating:
		return false
	# Store the starting camera position for drag calculations
	return true

func update_drag_position(drag_distance: float, drag_start_camera_y: float):
	if is_animating:
		return
		
	# Move camera directly based on drag (inverted for natural feel)
	var new_camera_y = drag_start_camera_y - drag_distance
	
	# Clamp camera position to reasonable bounds
	var min_y = 0
	var max_y = max_layer_bound
	camera.position.y = clamp(new_camera_y, min_y, max_y)
	
	camera_position_changed.emit(camera.position)

func end_drag_and_snap():
	if is_animating:
		return
		
	# Calculate which layer we're closest to and snap to it
	var current_camera_y = camera.position.y
	var closest_layer_index = round(current_camera_y / layer_height)
	
	# Clamp to valid layer range
	closest_layer_index = max(0, closest_layer_index)
	
	# Ensure we don't go beyond max bounds
	if closest_layer_index * layer_height > max_layer_bound:
		closest_layer_index = int(max_layer_bound / layer_height)
	
	# Update our current layer index and snap to it
	current_layer_index = int(closest_layer_index)
	target_position = Vector2(0, current_layer_index * layer_height)
	
	print("📷 Snapping to layer %d at position %f" % [current_layer_index, target_position.y])
	start_scroll_animation()

# Animation system
func start_scroll_animation():
	if not camera:
		return
		
	is_animating = true
	scroll_animation_started.emit()
	
	# Smooth snap animation
	var tween = create_tween()
	tween.set_ease(scroll_ease_type)
	tween.set_trans(scroll_transition_type)
	
	tween.tween_property(camera, "position", target_position, scroll_animation_duration)
	tween.tween_callback(finish_scroll_animation)

func finish_scroll_animation():
	is_animating = false
	scroll_animation_completed.emit()
	camera_position_changed.emit(camera.position)

# Screen shake effect
func add_screen_shake(duration: float, intensity: float):
	if not camera:
		return
		
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

# Public getters
func get_current_layer_index() -> int:
	return current_layer_index

func get_camera_position() -> Vector2:
	if camera:
		return camera.position
	return Vector2.ZERO

func is_camera_animating() -> bool:
	return is_animating

func get_layer_height() -> float:
	return layer_height 