extends Node2D
class_name ParticleManager

# Particle effects for different interactions
var gold_particles: GPUParticles2D
var combat_particles: GPUParticles2D
var success_particles: GPUParticles2D
var failure_particles: GPUParticles2D
var loot_particles: GPUParticles2D

func _ready():
	setup_particle_systems()

func setup_particle_systems():
	# Gold/coin collection particles
	gold_particles = create_gold_particles()
	add_child(gold_particles)
	
	# Combat hit effects
	combat_particles = create_combat_particles()
	add_child(combat_particles)
	
	# Success burst particles
	success_particles = create_success_particles()
	add_child(success_particles)
	
	# Failure particles
	failure_particles = create_failure_particles()
	add_child(failure_particles)
	
	# Loot collection particles
	loot_particles = create_loot_particles()
	add_child(loot_particles)

func create_gold_particles() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	var material = ParticleProcessMaterial.new()
	
	# Gold coin burst effect - BIGGER AND MORE DRAMATIC
	particles.emitting = false
	particles.amount = 150  # More particles
	particles.lifetime = 3.0  # Last longer
	particles.one_shot = true
	particles.explosiveness = 1.0
	
	# Material properties
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 200.0  # Faster
	material.initial_velocity_max = 400.0  # Much faster
	material.angular_velocity_min = -360.0
	material.angular_velocity_max = 360.0
	material.gravity = Vector3(0, 300, 0)  # Stronger gravity
	material.scale_min = 1.0  # Much larger
	material.scale_max = 2.5  # Even larger
	
	# Color animation (gold to yellow)
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color.GOLD)
	gradient.add_point(0.3, Color.YELLOW)
	gradient.add_point(0.7, Color.ORANGE)
	gradient.add_point(1.0, Color.TRANSPARENT)
	material.color_ramp = gradient
	
	# Emission shape - larger burst area
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 50.0  # Bigger emission area
	
	particles.process_material = material
	return particles

func create_combat_particles() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	var material = ParticleProcessMaterial.new()
	
	# Combat impact effect
	particles.emitting = false
	particles.amount = 30
	particles.lifetime = 1.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	
	# Material properties
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 80.0
	material.initial_velocity_max = 150.0
	material.angular_velocity_min = -90.0
	material.angular_velocity_max = 90.0
	material.gravity = Vector3(0, 100, 0)
	material.scale_min = 0.3
	material.scale_max = 0.8
	
	# Color animation (red impact)
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color.RED)
	gradient.add_point(0.3, Color.ORANGE_RED)
	gradient.add_point(1.0, Color.TRANSPARENT)
	material.color_ramp = gradient
	
	# Emission shape
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 15.0
	
	particles.process_material = material
	return particles

func create_success_particles() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	var material = ParticleProcessMaterial.new()
	
	# Success celebration burst - MASSIVE CELEBRATION
	particles.emitting = false
	particles.amount = 300  # Huge celebration
	particles.lifetime = 4.0  # Long lasting
	particles.one_shot = true
	particles.explosiveness = 1.0
	
	# Material properties
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 300.0  # Very fast
	material.initial_velocity_max = 600.0  # Explosive
	material.angular_velocity_min = -720.0  # Fast spinning
	material.angular_velocity_max = 720.0
	material.gravity = Vector3(0, 100, 0)  # Light gravity
	material.scale_min = 1.5  # Large particles
	material.scale_max = 3.0  # Very large
	
	# Color animation (bright celebration colors)
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color.CYAN)
	gradient.add_point(0.2, Color.LIME_GREEN)
	gradient.add_point(0.4, Color.YELLOW)
	gradient.add_point(0.6, Color.MAGENTA)
	gradient.add_point(0.8, Color.WHITE)
	gradient.add_point(1.0, Color.TRANSPARENT)
	material.color_ramp = gradient
	
	# Emission shape - wide celebration
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 100.0  # Wide celebration
	
	particles.process_material = material
	return particles

func create_failure_particles() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	var material = ParticleProcessMaterial.new()
	
	# Failure/damage effect
	particles.emitting = false
	particles.amount = 20
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.explosiveness = 1.0
	
	# Material properties
	material.direction = Vector3(0, 1, 0)  # Downward
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 100.0
	material.gravity = Vector3(0, 150, 0)
	material.scale_min = 0.4
	material.scale_max = 0.7
	
	# Color animation (dark/smoke effect)
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color.DARK_RED)
	gradient.add_point(0.5, Color.DIM_GRAY)
	gradient.add_point(1.0, Color.TRANSPARENT)
	material.color_ramp = gradient
	
	# Emission shape
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 25.0
	
	particles.process_material = material
	return particles

func create_loot_particles() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	var material = ParticleProcessMaterial.new()
	
	# Loot discovery sparkles
	particles.emitting = false
	particles.amount = 40
	particles.lifetime = 2.5
	particles.one_shot = true
	particles.explosiveness = 0.8
	
	# Material properties
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 60.0
	material.initial_velocity_max = 120.0
	material.angular_velocity_min = -180.0
	material.angular_velocity_max = 180.0
	material.gravity = Vector3(0, 80, 0)
	material.scale_min = 0.6
	material.scale_max = 1.0
	
	# Color animation (magical sparkles)
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color.WHITE)
	gradient.add_point(0.4, Color.LIGHT_BLUE)
	gradient.add_point(0.8, Color.MAGENTA)
	gradient.add_point(1.0, Color.TRANSPARENT)
	material.color_ramp = gradient
	
	# Emission shape
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 35.0
	
	particles.process_material = material
	return particles

# Public methods to trigger particle effects
func play_gold_effect(position: Vector2):
	# Position particles relative to the camera
	gold_particles.global_position = position
	gold_particles.restart()
	print("💰 Playing DRAMATIC gold particle effect at GLOBAL position: %s" % position)
	print("   Gold particles child count: %d, emitting: %s" % [gold_particles.amount, gold_particles.emitting])

func play_combat_effect(position: Vector2):
	combat_particles.global_position = position
	combat_particles.restart()
	print("⚔️ Playing combat particle effect at GLOBAL position: %s" % position)

func play_success_effect(position: Vector2):
	success_particles.global_position = position
	success_particles.restart()
	print("✨ Playing MASSIVE success particle effect at GLOBAL position: %s" % position)
	print("   Success particles: amount=%d, lifetime=%s" % [success_particles.amount, success_particles.lifetime])

func play_failure_effect(position: Vector2):
	failure_particles.global_position = position
	failure_particles.restart()
	print("💥 Playing failure particle effect at GLOBAL position: %s" % position)

func play_loot_effect(position: Vector2):
	loot_particles.global_position = position
	loot_particles.restart()
	print("🎁 Playing loot particle effect at GLOBAL position: %s" % position)

# Combined effects for layer completion
func play_layer_completion_effect(layer: BaseLayer, position: Vector2):
	match layer.layer_type:
		BaseLayer.LayerType.COMBAT:
			play_combat_effect(position)
			if layer.reward_gold > 0:
				# Delay gold effect slightly for combat
				await get_tree().create_timer(0.3).timeout
				play_gold_effect(position)
		BaseLayer.LayerType.LOOT:
			play_loot_effect(position)
			if layer.reward_gold > 0:
				await get_tree().create_timer(0.2).timeout
				play_gold_effect(position)
		BaseLayer.LayerType.SHOP:
			play_success_effect(position)
		BaseLayer.LayerType.EVENT:
			if layer.damage_amount > 0:
				play_failure_effect(position)
			else:
				play_success_effect(position)
			
			if layer.reward_gold > 0:
				await get_tree().create_timer(0.4).timeout
				play_gold_effect(position) 