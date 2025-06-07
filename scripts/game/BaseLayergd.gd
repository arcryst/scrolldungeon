extends Area2D
class_name BaseLayer

# Preload modular components
const LayerLayout = preload("res://scripts/game/LayerLayout.gd")
const BaseLayerContent = preload("res://scripts/game/BaseLayerContent.gd")

# Signals for communication with the game
signal layer_interacted(layer)
signal layer_completed(layer)

# Layer properties
@export var layer_type: LayerType
@export var depth: int = 0
@export var layer_title: String = "Unknown Layer"
@export var layer_description: String = "Something mysterious happens here."
@export var reward_gold: int = 0
@export var damage_amount: int = 0
@export var interaction_time: float = 2.0

# Modular systems
var layout_manager: LayerLayout
var content_system: BaseLayerContent

# Core visual components
var collision_shape: CollisionShape2D
var background: TextureRect
var overlay: ColorRect
var main_container: CenterContainer
var content_container: VBoxContainer

# Layer types
enum LayerType { 
	COMBAT,   # Fight enemies
	LOOT,     # Collect treasure
	SHOP,     # Buy items
	EVENT     # Random events
}

func _ready():
	setup_modular_systems()
	create_layer_structure()
	setup_layer_content()

func setup_modular_systems():
	# Create layout manager
	layout_manager = LayerLayout.new()
	add_child(layout_manager)
	
	# Create content system
	content_system = BaseLayerContent.new()
	add_child(content_system)
	
	# Connect content signals
	content_system.interaction_started.connect(_on_content_interaction_started)
	content_system.interaction_completed.connect(_on_content_interaction_completed)
	
	print("🎛️ BaseLayer modular systems setup for: %s" % layer_title)

func create_layer_structure():
	# Use layout manager to create core structure
	collision_shape = layout_manager.create_layer_collision_shape()
	add_child(collision_shape)
	
	# Setup background using layout manager
	background = layout_manager.setup_layer_background(self)
	add_child(background)
	
	# Setup overlay using layout manager
	overlay = layout_manager.setup_layer_overlay(self)
	add_child(overlay)
	
	# Setup main container using layout manager
	main_container = layout_manager.setup_main_container(self)
	add_child(main_container)
	
	# Setup content layout using layout manager
	content_container = layout_manager.setup_content_layout(main_container)
	
	# Connect layout manager signals
	layout_manager.layout_updated.connect(_on_layout_updated)

func setup_layer_content():
	# Prepare layer data for content system
	var layer_data = {
		"layer_type": layer_type,
		"depth": depth,
		"layer_title": layer_title,
		"layer_description": layer_description,
		"reward_gold": reward_gold,
		"damage_amount": damage_amount,
		"interaction_time": interaction_time
	}
	
	# Setup content system
	content_system.setup_content(layer_data, layout_manager)
	content_system.setup_in_layout(content_container)
	
	# Apply visual styling
	set_layer_appearance()

func set_layer_appearance():
	if not background:
		return
		
	var base_color: Color
	match layer_type:
		LayerType.COMBAT:
			base_color = Color(0.8, 0.2, 0.2)  # Red
		LayerType.LOOT:
			base_color = Color(0.2, 0.7, 0.2)  # Green
		LayerType.SHOP:
			base_color = Color(0.2, 0.4, 0.8)  # Blue
		LayerType.EVENT:
			base_color = Color(0.7, 0.4, 0.8)  # Purple
	
	# Create gradient background
	var gradient = Gradient.new()
	gradient.add_point(0.0, base_color.darkened(0.7))
	gradient.add_point(1.0, base_color.darkened(0.9))
	
	# Create and configure gradient texture
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = int(layout_manager.get_viewport_size().x)
	gradient_texture.height = int(layout_manager.get_viewport_size().y)
	gradient_texture.fill = GradientTexture2D.FILL_LINEAR
	gradient_texture.fill_from = Vector2(0, 0)
	gradient_texture.fill_to = Vector2(0, layout_manager.get_viewport_size().y)
	
	# Apply gradient to background
	background.texture = gradient_texture

# Signal handlers for content system
func _on_content_interaction_started():
	layer_interacted.emit(self)

func _on_content_interaction_completed(results: Dictionary):
	layer_completed.emit(self)

# Signal handlers for layout system
func _on_layout_updated():
	# Update background appearance when layout changes
	set_layer_appearance()
	
	# Let layout manager handle the structural updates
	layout_manager.update_layer_layout(self)

# Helper function to get layer type as string
func get_layer_type_string() -> String:
	return LayerType.keys()[layer_type]

# Public interface
func get_content_system() -> BaseLayerContent:
	return content_system

func get_layout_manager() -> LayerLayout:
	return layout_manager

# Quick interaction for testing
func quick_interact():
	if content_system and not content_system.is_currently_interacting():
		content_system.start_interaction()
		content_system.complete_interaction()
