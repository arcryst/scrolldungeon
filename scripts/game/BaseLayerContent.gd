extends Node
class_name BaseLayerContent

# Content signals
signal interaction_started
signal interaction_completed(results: Dictionary)

# Layer data
var layer_data: Dictionary = {}
var layer_type: BaseLayer.LayerType
var layout_manager: LayerLayout

# Visual elements
var title_label: Label
var description_label: Label
var interact_button: Button
var progress_bar: ProgressBar
var stats_labels: Dictionary = {}

# Interaction state
var is_interacting: bool = false
var interaction_timer: float = 0.0
var interaction_time: float = 2.0

func _ready():
	print("🎨 BaseLayerContent ready")

func setup_content(data: Dictionary, layout: LayerLayout):
	layer_data = data
	layout_manager = layout
	layer_type = data.get("layer_type", BaseLayer.LayerType.COMBAT)
	interaction_time = data.get("interaction_time", 2.0)
	
	create_content_elements()
	style_content()

func create_content_elements():
	# This method will be called by the layout system
	# Content elements are created here but positioned by layout
	pass

func setup_in_layout(content_container: VBoxContainer):
	# Called by layout system to add content to the proper container
	if not content_container:
		return
		
	# Depth indicator
	var depth_label = Label.new()
	depth_label.text = "Depth %d" % layer_data.get("depth", 0)
	depth_label.add_theme_font_size_override("font_size", 18)
	depth_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	depth_label.modulate = Color(1, 1, 1, 0.7)
	depth_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_container.add_child(depth_label)
	
	# Title label
	title_label = Label.new()
	title_label.text = layer_data.get("layer_title", "Unknown Layer")
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_container.add_child(title_label)
	
	# Description panel
	var desc_panel = PanelContainer.new()
	desc_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	desc_panel.custom_minimum_size = Vector2(600, 0)
	desc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_container.add_child(desc_panel)
	
	var desc_margin = MarginContainer.new()
	desc_margin.add_theme_constant_override("margin_left", 20)
	desc_margin.add_theme_constant_override("margin_right", 20)
	desc_margin.add_theme_constant_override("margin_top", 20)
	desc_margin.add_theme_constant_override("margin_bottom", 20)
	desc_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_panel.add_child(desc_margin)
	
	description_label = Label.new()
	description_label.text = layer_data.get("layer_description", "Something happens here.")
	description_label.add_theme_font_size_override("font_size", 24)
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_margin.add_child(description_label)
	
	# Stats container
	create_stats_display(content_container)
	
	# Button container
	create_interaction_button(content_container)
	
	# Progress bar
	create_progress_display(content_container)

func create_stats_display(parent: VBoxContainer):
	var stats_container = HBoxContainer.new()
	stats_container.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_container.add_theme_constant_override("separation", 40)
	stats_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(stats_container)
	
	# Reward display
	var reward_gold = layer_data.get("reward_gold", 0)
	if reward_gold > 0:
		var reward_label = create_stat_label("💰 %d" % reward_gold)
		stats_container.add_child(reward_label)
		stats_labels["reward"] = reward_label
	
	# Damage display
	var damage_amount = layer_data.get("damage_amount", 0)
	if damage_amount > 0:
		var damage_label = create_stat_label("💔 %d" % damage_amount)
		stats_container.add_child(damage_label)
		stats_labels["damage"] = damage_label

func create_stat_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func create_interaction_button(parent: VBoxContainer):
	var button_container = CenterContainer.new()
	button_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(button_container)
	
	interact_button = Button.new()
	interact_button.add_theme_font_size_override("font_size", 24)
	interact_button.custom_minimum_size = Vector2(300, 80)
	interact_button.mouse_filter = Control.MOUSE_FILTER_STOP
	interact_button.focus_mode = Control.FOCUS_ALL
	button_container.add_child(interact_button)
	
	# Connect button
	interact_button.pressed.connect(_on_interact_pressed)
	
	update_button_text()

func create_progress_display(parent: VBoxContainer):
	var progress_container = CenterContainer.new()
	progress_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(progress_container)
	
	progress_bar = ProgressBar.new()
	progress_bar.visible = false
	progress_bar.custom_minimum_size = Vector2(400, 10)
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_container.add_child(progress_bar)

func style_content():
	if not title_label:
		return
		
	# Apply layer-type specific styling
	var base_color: Color
	match layer_type:
		BaseLayer.LayerType.COMBAT:
			base_color = Color(0.8, 0.2, 0.2)  # Red
			title_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		BaseLayer.LayerType.LOOT:
			base_color = Color(0.2, 0.7, 0.2)  # Green
			title_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
		BaseLayer.LayerType.SHOP:
			base_color = Color(0.2, 0.4, 0.8)  # Blue
			title_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1))
		BaseLayer.LayerType.EVENT:
			base_color = Color(0.7, 0.4, 0.8)  # Purple
			title_label.add_theme_color_override("font_color", Color(1, 0.6, 1))

func update_button_text():
	if not interact_button:
		return
		
	match layer_type:
		BaseLayer.LayerType.COMBAT:
			interact_button.text = "⚔️  Fight!"
		BaseLayer.LayerType.LOOT:
			interact_button.text = "💰 Collect"
		BaseLayer.LayerType.SHOP:
			interact_button.text = "🛒 Browse"
		BaseLayer.LayerType.EVENT:
			interact_button.text = "❓ Investigate"

func _on_interact_pressed():
	if is_interacting:
		return
		
	start_interaction()

func start_interaction():
	is_interacting = true
	interaction_timer = 0.0
	
	# Visual feedback
	if interact_button:
		interact_button.text = "⏳ Interacting..."
		interact_button.disabled = true
	
	if progress_bar:
		progress_bar.visible = true
		progress_bar.value = 0
	
	interaction_started.emit()

func _process(delta):
	if is_interacting:
		handle_interaction_progress(delta)

func handle_interaction_progress(delta):
	interaction_timer += delta
	
	# Update progress bar
	if progress_bar:
		var progress = interaction_timer / interaction_time
		progress_bar.value = progress * 100
	
	if interaction_timer >= interaction_time:
		complete_interaction()

func complete_interaction():
	is_interacting = false
	
	# Visual feedback
	if interact_button:
		interact_button.text = "✅ Complete"
		progress_bar.visible = false
	
	# Create results
	var results = {
		"reward_gold": layer_data.get("reward_gold", 0),
		"damage_amount": layer_data.get("damage_amount", 0),
		"layer_type": layer_type
	}
	
	interaction_completed.emit(results)

# Public interface for different content types
func get_interaction_time() -> float:
	return interaction_time

func is_currently_interacting() -> bool:
	return is_interacting

func reset_interaction():
	is_interacting = false
	interaction_timer = 0.0
	if interact_button:
		interact_button.disabled = false
		update_button_text()
	if progress_bar:
		progress_bar.visible = false 