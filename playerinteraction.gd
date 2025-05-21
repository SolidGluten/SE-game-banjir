extends Node2D
class_name FloodInteractionManager

@export var interaction_range := 150.0

@onready var interaction_ray := $InteractionRayCast2D
@onready var player_inventory := $"/root/PlayerInventory"
@onready var flood_warning_system := $"/root/GameWorld/FloodWarningSystem"

enum FloodInteractions {
    MOVE_FURNITURE,
    RELOCATE_VEHICLE,
    SANDBAGGING,
    TURN_OFF_ELECTRICITY,
    RESCUE_PET,
    GRAB_EMERGENCY_KIT
}

var current_interaction_target: Node2D = null

func _ready():
    interaction_ray.target_position = Vector2(interaction_range, 0)

func _process(delta):
    update_interaction_target()
    
    if Input.is_action_just_pressed("interact") and current_interaction_target:
        handle_flood_interaction(current_interaction_target)

func update_interaction_target():
    interaction_ray.force_raycast_update()
    if interaction_ray.is_colliding():
        current_interaction_target = interaction_ray.get_collider()
        show_interaction_prompt(current_interaction_target.name)
    else:
        current_interaction_target = null
        hide_interaction_prompt()

func handle_flood_interaction(target: Node2D):
    match target.get_groups():
        ["movable_furniture"]:
            move_to_higher_ground(target)
        ["vehicle"]:
            relocate_vehicle(target)
        ["sandbag_station"]:
            build_sandbag_barrier()
        ["electrical_panel"]:
            turn_off_electricity()
        ["pet"]:
            rescue_pet(target)
        ["emergency_kit"]:
            grab_emergency_kit(target)
        _:
            print("No valid flood interaction")

# === FLOOD-SPECIFIC INTERACTIONS ===

func move_to_higher_ground(furniture: Node2D):
    if player_inventory.has_item("moving_dolly"):
        var upstairs_position = $"/root/GameWorld/UpstairsArea".get_random_position()
        furniture.start_moving(upstairs_position)
        player_inventory.consume_item("moving_dolly")
        show_message("Moved %s to upper floor" % furniture.furniture_name)
    else:
        show_message("Need moving dolly to lift heavy items!")

func relocate_vehicle(vehicle: Node2D):
    if flood_warning_system.flood_warning_level < 2:  # Warning levels 0-3
        vehicle.start_evacuation_route()
        show_message("Vehicle relocated to safe zone")
    else:
        show_message("Too late! Water already too high")

func build_sandbag_barrier():
    if player_inventory.has_item("sandbags"):
        var barrier_strength = player_inventory.use_sandbags(5)
        $"/root/GameWorld".update_flood_barrier(barrier_strength)
        show_message("Built sandbag barrier (Strength: +%d%%)" % barrier_strength)
    else:
        show_message("Need sandbags from storage first!")

func turn_off_electricity():
    $"/root/GameWorld/PowerSystem".shut_off_main_power()
    show_message("Main power shut off - preventing electrocution")

func rescue_pet(pet: Node2D):
    if player_inventory.has_item("pet_carrier"):
        pet.load_into_carrier()
        player_inventory.add_item("rescued_pet")
        show_message("%s safely rescued!" % pet.pet_name)
    else:
        show_message("Need pet carrier from garage")

func grab_emergency_kit(kit: Node2D):
    player_inventory.add_items({
        "flashlight": 1,
        "bottled_water": 4,
        "non_perishable_food": 3
    })
    kit.queue_free()
    show_message("Emergency supplies acquired!")

# === UI FEEDBACK ===

func show_interaction_prompt(object_name: String):
    $UI/InteractionPrompt.text = "[E] %s" % object_name
    $UI/InteractionPrompt.visible = true

func hide_interaction_prompt():
    $UI/InteractionPrompt.visible = false

func show_message(text: String):
    $UI/MessageDisplay.display_message(text)