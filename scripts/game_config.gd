extends Resource
## Balancing values: edit data/game_config.tres in the Inspector.
@export_range(0.0, 1.0) var anomaly_chance: float = 0.65
@export var bell_rooms: Array[int] = [2, 3, 5]
@export_range(2, 20) var final_room: int = 7
@export var walk_speed: float = 2.7
@export var sprint_speed: float = 5.5
@export_range(3.5, 20.0) var stamina_seconds: float = 6.0
@export_range(0.1, 3.0) var stamina_recovery: float = .8
@export_range(0.0, 5.0) var stamina_recovery_delay: float = 1.5
@export var mouse_sensitivity: float = 0.0022
@export var eye_contact_seconds: float = 1.8
@export var chase_seconds: float = 3.0
@export var chase_speed: float = 3.7
@export var first_room_safe: bool = true
@export var explain_failures: bool = false
@export var debug_enabled: bool = false
## -1=random, 0=normal, 1..27=anomaly. First-room safety takes precedence.
@export_range(-1, 27) var forced_anomaly: int = -1

