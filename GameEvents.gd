# GameEvents.gd
extends Node

# Signal emitted when a crate is collected/teleported
# Optionally pass the crate node itself
signal crate_collected

# Signals for lazer rifle charging state
signal lazer_charging_started
signal lazer_charging_stoppped

# Signal for player death
signal game_over
# Signal for player respawn
signal game_restarted