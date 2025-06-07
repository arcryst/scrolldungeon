extends Node
class_name LayerGenerator

# Layer templates with content variety
const LAYER_TEMPLATES = {
	BaseLayer.LayerType.COMBAT: [
		{
			"title": "Goblin Ambush",
			"description": "A sneaky goblin blocks your path with a rusty dagger!",
			"damage": 15,
			"reward": 20
		},
		{
			"title": "Skeleton Warrior", 
			"description": "Ancient bones rattle menacingly in the darkness.",
			"damage": 25,
			"reward": 35
		},
		{
			"title": "Giant Spider",
			"description": "Webs everywhere... something large moves in the shadows.",
			"damage": 20,
			"reward": 30
		},
		{
			"title": "Orc Berserker",
			"description": "A massive orc swings a brutal axe!",
			"damage": 35,
			"reward": 50
		},
		{
			"title": "Cave Troll",
			"description": "A hulking troll blocks the entire passage.",
			"damage": 45,
			"reward": 75
		}
	],
	BaseLayer.LayerType.LOOT: [
		{
			"title": "Treasure Chest",
			"description": "A dusty chest gleams in the torchlight.",
			"damage": 0,
			"reward": 50
		},
		{
			"title": "Gold Pile",
			"description": "Coins scattered across the stone floor.",
			"damage": 0,
			"reward": 25
		},
		{
			"title": "Magic Artifact",
			"description": "Something powerful glows with mystical energy.",
			"damage": 0,
			"reward": 100
		},
		{
			"title": "Hidden Cache",
			"description": "A secret stash behind loose stones.",
			"damage": 0,
			"reward": 40
		},
		{
			"title": "Ancient Relic",
			"description": "A priceless artifact from a lost civilization.",
			"damage": 0,
			"reward": 80
		}
	],
	BaseLayer.LayerType.SHOP: [
		{
			"title": "Underground Merchant",
			"description": "A hooded figure offers strange wares for gold.",
			"damage": 0,
			"reward": 0
		},
		{
			"title": "Dungeon Vending Machine",
			"description": "A bizarre machine hums quietly, offering supplies.",
			"damage": 0,
			"reward": 0
		},
		{
			"title": "Goblin Trader",
			"description": "A friendly goblin wants to make a deal.",
			"damage": 0,
			"reward": 0
		}
	],
	BaseLayer.LayerType.EVENT: [
		{
			"title": "Cat Tax Collector",
			"description": "A distinguished cat demands payment for safe passage.",
			"damage": 10,
			"reward": 15
		},
		{
			"title": "Motivational Speaker",
			"description": "An enthusiastic adventurer offers life advice.",
			"damage": 0,
			"reward": 10
		},
		{
			"title": "Mysterious Well",
			"description": "A deep well echoes with strange sounds.",
			"damage": 5,
			"reward": 25
		},
		{
			"title": "Underground Café",
			"description": "A cozy coffee shop run by friendly dwarves.",
			"damage": 0,
			"reward": 5
		},
		{
			"title": "Riddle Master",
			"description": "An ancient sage challenges you to a battle of wits.",
			"damage": 0,
			"reward": 40
		}
	]
}

# Difficulty scaling per depth
static func get_difficulty_multiplier(depth: int) -> float:
	# Gradually increase difficulty
	return 1.0 + (depth * 0.1)

# Generate a random layer for the given depth
static func generate_layer(depth: int) -> BaseLayer:
	# Create layer entirely in code (no .tscn file needed!)
	var layer = BaseLayer.new()
	
	# Choose layer type based on weighted probabilities
	var layer_type = choose_layer_type(depth)
	var template = choose_template(layer_type)
	var difficulty = get_difficulty_multiplier(depth)
	
	# Set layer properties
	layer.layer_type = layer_type
	layer.depth = depth
	layer.layer_title = template.title
	layer.layer_description = template.description
	
	# Scale rewards and damage based on depth
	layer.reward_gold = int(template.reward * difficulty)
	layer.damage_amount = int(template.damage * difficulty)
	
	# Adjust interaction time based on layer type
	match layer_type:
		BaseLayer.LayerType.COMBAT:
			layer.interaction_time = randf_range(1.5, 3.0)
		BaseLayer.LayerType.LOOT:
			layer.interaction_time = randf_range(0.5, 1.5)
		BaseLayer.LayerType.SHOP:
			layer.interaction_time = randf_range(1.0, 2.0)
		BaseLayer.LayerType.EVENT:
			layer.interaction_time = randf_range(1.0, 4.0)
	
	return layer

# Choose layer type with weighted probabilities
static func choose_layer_type(depth: int) -> BaseLayer.LayerType:
	var weights: Array[float]
	
	if depth < 5:
		# Early game: more loot, less danger
		weights = [0.4, 0.3, 0.15, 0.15]  # Combat, Loot, Shop, Event
	elif depth < 15:
		# Mid game: balanced
		weights = [0.5, 0.25, 0.15, 0.1]
	else:
		# Deep dungeon: mostly combat
		weights = [0.65, 0.2, 0.1, 0.05]
	
	return weighted_random_selection(weights)

# Choose a random template from the given layer type
static func choose_template(layer_type: BaseLayer.LayerType) -> Dictionary:
	var templates = LAYER_TEMPLATES[layer_type]
	return templates[randi() % templates.size()]

# Weighted random selection helper
static func weighted_random_selection(weights: Array[float]) -> BaseLayer.LayerType:
	var total_weight = 0.0
	for weight in weights:
		total_weight += weight
	
	var random_value = randf() * total_weight
	var current_weight = 0.0
	
	for i in range(weights.size()):
		current_weight += weights[i]
		if random_value <= current_weight:
			return i as BaseLayer.LayerType
	
	# Fallback to combat
	return BaseLayer.LayerType.COMBAT

# Generate multiple layers at once
static func generate_layers(start_depth: int, count: int) -> Array[BaseLayer]:
	var layers: Array[BaseLayer] = []
	
	for i in range(count):
		var layer = generate_layer(start_depth + i)
		layers.append(layer)
	
	return layers

# Preview what a layer would be without creating it
static func preview_layer(depth: int) -> Dictionary:
	var layer_type = choose_layer_type(depth)
	var template = choose_template(layer_type)
	var difficulty = get_difficulty_multiplier(depth)
	
	return {
		"type": BaseLayer.LayerType.keys()[layer_type],
		"title": template.title,
		"description": template.description,
		"reward": int(template.reward * difficulty),
		"damage": int(template.damage * difficulty),
		"depth": depth
	}