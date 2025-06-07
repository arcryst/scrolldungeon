extends Node
class_name GameManager

# Signals - these are like events that other parts of the game can listen to
signal player_died
signal gold_changed(new_amount)
signal health_changed(new_health)

# Game state variables
var current_depth: int = 0
var player_health: int = 100
var max_health: int = 100
var gold: int = 0
var is_alive: bool = true

# Game settings
var starting_health: int = 100
var starting_gold: int = 0

func _ready():
    print("GameManager initialized")
    reset_game()

# Called when player takes damage
func take_damage(amount: int):
    if not is_alive:
        return
        
    player_health -= amount
    player_health = max(0, player_health)  # Don't go below 0
    
    print("Player took %d damage, health now: %d" % [amount, player_health])
    health_changed.emit(player_health)
    
    if player_health <= 0:
        is_alive = false
        print("Player died at depth %d" % current_depth)
        player_died.emit()

# Called when player gains gold
func add_gold(amount: int):
    gold += amount
    print("Player gained %d gold, total: %d" % [amount, gold])
    gold_changed.emit(gold)

# Called when player goes deeper
func increase_depth():
    current_depth += 1
    print("Player reached depth: %d" % current_depth)

# Reset game to starting state
func reset_game():
    current_depth = 0
    player_health = starting_health
    max_health = starting_health
    gold = starting_gold
    is_alive = true
    
    print("Game reset - Health: %d, Gold: %d" % [player_health, gold])
    health_changed.emit(player_health)
    gold_changed.emit(gold)

# Heal the player (for future use)
func heal(amount: int):
    if not is_alive:
        return
        
    player_health += amount
    player_health = min(max_health, player_health)  # Don't exceed max
    health_changed.emit(player_health)

# Check if player can afford something
func can_afford(cost: int) -> bool:
    return gold >= cost

# Spend gold (returns true if successful)
func spend_gold(amount: int) -> bool:
    if can_afford(amount):
        gold -= amount
        gold_changed.emit(gold)
        return true
    return false