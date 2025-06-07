extends Control
class_name GameHUD

var health_label: Label
var gold_label: Label
var depth_label: Label
var game_over_overlay: ColorRect
var game_over_title: Label
var game_over_stats: Label
var restart_button: Button

var game_manager: GameManager

func _ready():
    create_ui_elements()
    setup_game_over_overlay()

func create_ui_elements():
    # Make this control fill the entire screen
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE

    # Create top bar container
    var top_bar = MarginContainer.new()
    top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
    add_child(top_bar)
    
    # Top bar background
    var top_bar_bg = ColorRect.new()
    top_bar_bg.color = Color(0, 0, 0, 0.4)
    top_bar_bg.custom_minimum_size = Vector2(0, 80)
    top_bar_bg.mouse_filter = Control.MOUSE_FILTER_STOP
    top_bar.add_child(top_bar_bg)
    
    # HBoxContainer for top bar content
    var top_bar_content = HBoxContainer.new()
    top_bar_content.set_anchors_preset(Control.PRESET_FULL_RECT)
    top_bar.add_child(top_bar_content)
    
    # Add some padding
    top_bar.add_theme_constant_override("margin_left", 20)
    top_bar.add_theme_constant_override("margin_right", 20)
    top_bar.add_theme_constant_override("margin_top", 20)
    
    # Health label (left)
    health_label = Label.new()
    health_label.text = "❤️ 100/100"
    health_label.add_theme_font_size_override("font_size", 24)
    health_label.add_theme_color_override("font_color", Color.WHITE)
    health_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top_bar_content.add_child(health_label)
    
    # Gold label (center)
    gold_label = Label.new()
    gold_label.text = "💰 0"
    gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    gold_label.add_theme_font_size_override("font_size", 24)
    gold_label.add_theme_color_override("font_color", Color.YELLOW)
    gold_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top_bar_content.add_child(gold_label)
    
    # Depth label (right)
    depth_label = Label.new()
    depth_label.text = "🏔️ Depth: 0"
    depth_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    depth_label.add_theme_font_size_override("font_size", 24)
    depth_label.add_theme_color_override("font_color", Color.CYAN)
    depth_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top_bar_content.add_child(depth_label)
    
    # Bottom hint container
    var bottom_container = MarginContainer.new()
    bottom_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    add_child(bottom_container)
    
    # Bottom hint text
    var hint_label = Label.new()
    hint_label.text = "👆 Swipe or scroll to navigate • ⬇️ Arrow keys to test"
    hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint_label.add_theme_font_size_override("font_size", 16)
    hint_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
    hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bottom_container.add_child(hint_label)
    
    # Add padding to bottom container
    bottom_container.add_theme_constant_override("margin_bottom", 20)

func setup_game_over_overlay():
    # Full-screen overlay
    game_over_overlay = ColorRect.new()
    game_over_overlay.color = Color(0, 0, 0, 0.9)
    game_over_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    game_over_overlay.visible = false
    game_over_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(game_over_overlay)
    
    # Center container for game over content
    var center_container = CenterContainer.new()
    center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
    game_over_overlay.add_child(center_container)
    
    # VBox for vertical layout
    var vbox = VBoxContainer.new()
    vbox.custom_minimum_size = Vector2(400, 0)  # Set minimum width
    vbox.add_theme_constant_override("separation", 40)
    center_container.add_child(vbox)
    
    # Game over title
    game_over_title = Label.new()
    game_over_title.text = "💀 GAME OVER!"
    game_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    game_over_title.add_theme_font_size_override("font_size", 48)
    game_over_title.add_theme_color_override("font_color", Color.RED)
    vbox.add_child(game_over_title)
    
    # Stats display
    game_over_stats = Label.new()
    game_over_stats.text = "Final Stats Loading..."
    game_over_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    game_over_stats.add_theme_font_size_override("font_size", 20)
    game_over_stats.add_theme_color_override("font_color", Color.WHITE)
    vbox.add_child(game_over_stats)
    
    # Restart button
    restart_button = Button.new()
    restart_button.text = "🔄 Try Again"
    restart_button.custom_minimum_size = Vector2(200, 60)
    restart_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    restart_button.add_theme_font_size_override("font_size", 20)
    restart_button.pressed.connect(_on_restart_pressed)
    vbox.add_child(restart_button)

func connect_to_game_manager(manager: GameManager):
    game_manager = manager
    manager.health_changed.connect(_on_health_changed)
    manager.gold_changed.connect(_on_gold_changed)
    manager.player_died.connect(_on_player_died)
    
    # Initial update
    update_all_ui()

func update_all_ui():
    if game_manager:
        _on_health_changed(game_manager.player_health)
        _on_gold_changed(game_manager.gold)
        _on_depth_changed(game_manager.current_depth)

func _on_health_changed(new_health: int):
    health_label.text = "❤️ %d/%d" % [new_health, game_manager.max_health]

func _on_gold_changed(new_gold: int):
    gold_label.text = "💰 %d" % new_gold

func _on_depth_changed(new_depth: int):
    depth_label.text = "🏔️ Depth: %d" % new_depth

func _on_player_died():
    # Update final stats
    game_over_stats.text = "Final Depth: %d\nGold Collected: %d" % [
        game_manager.current_depth,
        game_manager.gold
    ]
    
    # Show overlay with animation
    game_over_overlay.visible = true
    game_over_overlay.modulate.a = 0.0
    
    var tween = create_tween()
    tween.tween_property(game_over_overlay, "modulate:a", 1.0, 0.5)

func _on_restart_pressed():
    # Hide overlay
    game_over_overlay.visible = false
    
    # Reset game
    game_manager.reset_game()