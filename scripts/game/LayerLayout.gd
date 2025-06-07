extends Node
class_name LayerLayout

# Layout change signals
signal viewport_size_changed(new_size: Vector2)
signal layout_updated

# Layout settings
@export var padding_horizontal: int = 40
@export var padding_vertical: int = 20
@export var element_spacing: int = 30

# Current layout state
var current_viewport_size: Vector2
var layer_height: float
var is_initialized: bool = false

func _ready():
	initialize_layout()
	print("📐 LayerLayout initialized")

func initialize_layout():
	current_viewport_size = get_viewport().get_visible_rect().size
	layer_height = current_viewport_size.y
	is_initialized = true
	print("📐 Initial viewport size: %s" % current_viewport_size)

func _process(_delta):
	check_viewport_changes()

func check_viewport_changes():
	if not is_initialized:
		return
		
	var new_size = get_viewport().get_visible_rect().size
	if new_size != current_viewport_size:
		handle_viewport_change(new_size)

func handle_viewport_change(new_size: Vector2):
	print("📐 Viewport changed: %s -> %s" % [current_viewport_size, new_size])
	current_viewport_size = new_size
	layer_height = new_size.y
	viewport_size_changed.emit(new_size)
	layout_updated.emit()

# Core layout methods
func get_viewport_size() -> Vector2:
	return current_viewport_size

func get_layer_height() -> float:
	return layer_height

func get_layer_width() -> float:
	return current_viewport_size.x

func calculate_layer_position(layer_index: int) -> Vector2:
	return Vector2(0, layer_index * layer_height)

# Layer collision shape setup
func create_layer_collision_shape() -> CollisionShape2D:
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = current_viewport_size
	collision_shape.shape = rect_shape
	return collision_shape

# Background setup for layers
func setup_layer_background(layer: Node2D) -> TextureRect:
	var background = TextureRect.new()
	background.size = current_viewport_size
	background.position = -current_viewport_size / 2
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	return background

# Overlay setup for layers
func setup_layer_overlay(layer: Node2D) -> ColorRect:
	var overlay = ColorRect.new()
	overlay.size = current_viewport_size
	overlay.position = -current_viewport_size / 2
	overlay.color = Color(0, 0, 0, 0.3)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return overlay

# Main content container setup
func setup_main_container(layer: Node2D) -> CenterContainer:
	var center_container = CenterContainer.new()
	center_container.size = current_viewport_size
	center_container.position = -current_viewport_size / 2
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return center_container

# Content layout setup
func setup_content_layout(parent_container: CenterContainer) -> VBoxContainer:
	var content_container = VBoxContainer.new()
	content_container.custom_minimum_size = Vector2(current_viewport_size.x, 0)
	content_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_container.add_theme_constant_override("separation", element_spacing)
	parent_container.add_child(content_container)
	
	# Add margin container
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", padding_horizontal)
	margin_container.add_theme_constant_override("margin_right", padding_horizontal)
	margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_container.add_child(margin_container)
	
	# Add inner content container
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", element_spacing)
	content_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_container.add_child(content_vbox)
	
	return content_vbox

# Update existing layer layout
func update_layer_layout(layer: Node2D):
	if not layer:
		return
		
	# Find and update collision shape
	for child in layer.get_children():
		if child is CollisionShape2D:
			var rect_shape = RectangleShape2D.new()
			rect_shape.size = current_viewport_size
			child.shape = rect_shape
		
		# Update background and overlay
		elif child is TextureRect or child is ColorRect:
			child.size = current_viewport_size
			child.position = -current_viewport_size / 2
		
		# Update main container
		elif child is CenterContainer:
			child.size = current_viewport_size
			child.position = -current_viewport_size / 2
			
			# Update content container width
			if child.get_child_count() > 0:
				var content = child.get_child(0)
				if content.has_method("set_custom_minimum_size"):
					content.custom_minimum_size.x = current_viewport_size.x

# Utility methods for responsive design
func get_scaled_font_size(base_size: int) -> int:
	var scale_factor = min(current_viewport_size.x / 1920.0, current_viewport_size.y / 1080.0)
	return max(int(base_size * scale_factor), base_size / 2)  # Ensure minimum readability

func get_scaled_spacing() -> int:
	var scale_factor = min(current_viewport_size.x / 1920.0, current_viewport_size.y / 1080.0)
	return max(int(element_spacing * scale_factor), 10)

func get_scaled_padding() -> int:
	var scale_factor = min(current_viewport_size.x / 1920.0, current_viewport_size.y / 1080.0)
	return max(int(padding_horizontal * scale_factor), 20) 
