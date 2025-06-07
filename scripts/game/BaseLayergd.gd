extends Area2D
class_name BaseLayer

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

# Visual nodes
var background: TextureRect
var content_panel: PanelContainer
var title_label: Label
var description_label: Label
var interact_button: Button
var collision_shape: CollisionShape2D
var content_container: VBoxContainer
var progress_bar: ProgressBar
var stats_container: HBoxContainer
var depth_label: Label
var reward_label: Label
var damage_label: Label

# State
var is_interacted: bool = false
var is_interacting: bool = false
var interaction_timer: float = 0.0

# Layer types
enum LayerType { 
	COMBAT,   # Fight enemies
	LOOT,     # Collect treasure
	SHOP,     # Buy items
	EVENT     # Random events
}

# Add viewport tracking
var last_viewport_size: Vector2

func _ready():
	last_viewport_size = get_viewport_rect().size
	monitoring = true
	monitorable = true
	create_visual_elements()
	setup_layer()
	connect_signals()

func _process(delta):
	# Check for viewport size changes
	var current_viewport = get_viewport_rect().size
	if current_viewport != last_viewport_size:
		update_layout(current_viewport)
		last_viewport_size = current_viewport
	
	# Handle interaction progress if active
	if is_interacting:
		handle_interaction_progress(delta)
		
	# Update button state
	if interact_button:
		interact_button.disabled = is_interacted or is_interacting

func create_visual_elements():
	# Get viewport size for full-screen layout
	var viewport_size = get_viewport_rect().size
	
	# Create collision shape
	collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = viewport_size
	collision_shape.shape = rect_shape
	add_child(collision_shape)
	
	# Create background with gradient
	background = TextureRect.new()
	background.size = viewport_size
	background.position = -viewport_size / 2
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(background)
	
	# Add a semi-transparent overlay for better text readability
	var overlay = ColorRect.new()
	overlay.size = viewport_size
	overlay.position = -viewport_size / 2
	overlay.color = Color(0, 0, 0, 0.3)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	
	# Main container to center everything vertically
	var center_container = CenterContainer.new()
	center_container.size = viewport_size
	center_container.position = -viewport_size / 2
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center_container)
	
	# Main content container
	content_container = VBoxContainer.new()
	content_container.custom_minimum_size = Vector2(viewport_size.x, 0)  # Full width
	content_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_container.add_theme_constant_override("separation", 20)
	center_container.add_child(content_container)
	
	# Create a MarginContainer for proper padding
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 40)
	margin_container.add_theme_constant_override("margin_right", 40)
	margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_container.add_child(margin_container)
	
	# Create a VBoxContainer for content
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 30)
	content_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_container.add_child(content_vbox)
	
	# Depth indicator
	depth_label = Label.new()
	depth_label.add_theme_font_size_override("font_size", 18)
	depth_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	depth_label.modulate = Color(1, 1, 1, 0.7)
	depth_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_child(depth_label)
	
	# Title label
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_child(title_label)
	
	# Description panel
	var desc_panel = PanelContainer.new()
	desc_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	desc_panel.custom_minimum_size = Vector2(600, 0)
	desc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_child(desc_panel)
	
	var desc_margin = MarginContainer.new()
	desc_margin.add_theme_constant_override("margin_left", 20)
	desc_margin.add_theme_constant_override("margin_right", 20)
	desc_margin.add_theme_constant_override("margin_top", 20)
	desc_margin.add_theme_constant_override("margin_bottom", 20)
	desc_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_panel.add_child(desc_margin)
	
	description_label = Label.new()
	description_label.add_theme_font_size_override("font_size", 24)
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_margin.add_child(description_label)
	
	# Stats container
	stats_container = HBoxContainer.new()
	stats_container.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_container.add_theme_constant_override("separation", 40)
	stats_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_child(stats_container)
	
	# Add stats labels
	reward_label = create_stat_label("💰")
	damage_label = create_stat_label("💔")
	stats_container.add_child(reward_label)
	stats_container.add_child(damage_label)
	
	# Button container for centering
	var button_container = CenterContainer.new()
	button_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_child(button_container)
	
	# Interact button
	interact_button = Button.new()
	interact_button.add_theme_font_size_override("font_size", 24)
	interact_button.custom_minimum_size = Vector2(300, 80)
	interact_button.mouse_filter = Control.MOUSE_FILTER_STOP
	interact_button.focus_mode = Control.FOCUS_ALL
	button_container.add_child(interact_button)
	
	# Progress bar container
	var progress_container = CenterContainer.new()
	progress_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_child(progress_container)
	
	# Progress bar
	progress_bar = ProgressBar.new()
	progress_bar.visible = false
	progress_bar.custom_minimum_size = Vector2(400, 10)
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_container.add_child(progress_bar)

func create_stat_label(icon: String) -> Label:
	var label = Label.new()
	label.add_theme_font_size_override("font_size", 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func setup_layer():
	depth_label.text = "Depth %d" % depth
	title_label.text = layer_title
	description_label.text = layer_description
	
	# Update stats
	reward_label.text = "💰 %d" % reward_gold if reward_gold > 0 else ""
	damage_label.text = "💔 %d" % damage_amount if damage_amount > 0 else ""
	reward_label.visible = reward_gold > 0
	damage_label.visible = damage_amount > 0
	
	set_layer_appearance()
	update_button_text()

func set_layer_appearance():
	var base_color: Color
	
	match layer_type:
		LayerType.COMBAT:
			base_color = Color(0.8, 0.2, 0.2)  # Red
			title_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		LayerType.LOOT:
			base_color = Color(0.2, 0.7, 0.2)  # Green
			title_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
		LayerType.SHOP:
			base_color = Color(0.2, 0.4, 0.8)  # Blue
			title_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1))
		LayerType.EVENT:
			base_color = Color(0.7, 0.4, 0.8)  # Purple
			title_label.add_theme_color_override("font_color", Color(1, 0.6, 1))
	
	# Create gradient background
	var gradient = Gradient.new()
	gradient.add_point(0.0, base_color.darkened(0.7))
	gradient.add_point(1.0, base_color.darkened(0.9))
	
	# Create and configure gradient texture
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = int(get_viewport_rect().size.x)
	gradient_texture.height = int(get_viewport_rect().size.y)
	gradient_texture.fill = GradientTexture2D.FILL_LINEAR
	gradient_texture.fill_from = Vector2(0, 0)
	gradient_texture.fill_to = Vector2(0, get_viewport_rect().size.y)
	
	# Apply gradient to background
	background.texture = gradient_texture

func update_button_text():
	match layer_type:
		LayerType.COMBAT:
			interact_button.text = "⚔️  Fight!"
		LayerType.LOOT:
			interact_button.text = "💰 Collect"
		LayerType.SHOP:
			interact_button.text = "🛒 Browse"
		LayerType.EVENT:
			interact_button.text = "❓ Investigate"

func connect_signals():
	# Only connect button press, remove Area2D input handling
	if interact_button:
		interact_button.pressed.connect(_on_interact_pressed)
		print("✅ Button connected for layer: ", layer_title)

func _on_interact_pressed():
	print("🔥 BUTTON CLICKED! ", layer_title)
	if not is_interacted and not is_interacting:
		start_interaction()

func start_interaction():
	if is_interacted:
		return
		
	is_interacting = true
	interaction_timer = 0.0
	
	# Visual feedback
	interact_button.text = "⏳ Interacting..."
	interact_button.disabled = true
	progress_bar.visible = true
	progress_bar.value = 0
	
	# Scale animation
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
	
	# Emit signal that interaction started
	layer_interacted.emit(self)
	
	print("Started interacting with %s layer" % LayerType.keys()[layer_type])

func handle_interaction_progress(delta):
	interaction_timer += delta
	
	# Update progress bar
	var progress = interaction_timer / interaction_time
	progress_bar.value = progress * 100
	
	if interaction_timer >= interaction_time:
		complete_interaction()

func complete_interaction():
	is_interacting = false
	is_interacted = true
	
	# Visual feedback
	interact_button.text = "✅ Complete"
	progress_bar.visible = false
	
	# Completion animation
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(0.95, 0.95), 0.1)
	tween.parallel().tween_property(background, "modulate", Color(1.2, 1.2, 1.2, 0.8), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	tween.parallel().tween_property(background, "modulate", Color.WHITE, 0.2)
	
	# Emit completion signal
	layer_completed.emit(self)
	
	print("Completed %s layer - Gold: %d, Damage: %d" % [
		LayerType.keys()[layer_type], 
		reward_gold, 
		damage_amount
	])

# Helper function to get layer type as string
func get_layer_type_string() -> String:
	return LayerType.keys()[layer_type]

# Function to quickly interact (for testing)
func quick_interact():
	if not is_interacted:
		start_interaction()
		complete_interaction()

func update_layout(viewport_size: Vector2):
	# Update collision shape
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = viewport_size
	collision_shape.shape = rect_shape
	
	# Update background and overlay
	background.size = viewport_size
	background.position = -viewport_size / 2
	
	# Find and update overlay and center container
	for child in get_children():
		if child is ColorRect:
			child.size = viewport_size
			child.position = -viewport_size / 2
		elif child is CenterContainer:
			child.size = viewport_size
			child.position = -viewport_size / 2
			
			# Update content container width
			if child.get_child_count() > 0:
				var content = child.get_child(0)
				content.custom_minimum_size.x = viewport_size.x
	
	# Update gradient texture
	set_layer_appearance()
