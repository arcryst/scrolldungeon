extends Node2D

@onready var scroll_controller = $ScrollController
@onready var game_manager = $ScrollController/GameManager

var hud: GameHUD

func _ready():
	print("ScrollDungeon Main scene loaded")
	
	# Create UI as CanvasLayer (screen-fixed)
	var ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	# Create HUD in the CanvasLayer
	hud = GameHUD.new()
	ui_layer.add_child(hud)  # Add to CanvasLayer, not Main!
	hud.connect_to_game_manager(game_manager)
	
	# Connect scroll controller signals
	scroll_controller.layer_revealed.connect(_on_layer_revealed)
	scroll_controller.scroll_completed.connect(_on_scroll_completed)
	
	print("✅ UI created programmatically!")
	print("Ready to scroll! Use Down Arrow to dig deeper.")

func _on_layer_revealed(layer):
	print("🔍 New layer revealed: %s" % layer.layer_title)
	# Update depth in UI
	hud._on_depth_changed(game_manager.current_depth)

func _on_scroll_completed():
	print("📱 Scroll animation completed")
