# MinimapEvents.gd
extends Node

# Signal emitted when an entity's position needs to be updated on the minimap
# - entity: The node itself (Player, Crate, Enemy instance)
# - entity_type: A string identifier ("player", "crate", "enemy")
# - position_2d: A Vector2 containing the X and Z coordinates
signal entity_position_updated(entity, entity_type, position_2d)

# Signal emitted when an entity is removed from the game (or should be removed from minimap)
# - entity: The node that was removed
signal entity_removed(entity)

# You could add more signals here later if needed, e.g., for specific events
# like the crate teleporting, etc., although position updates might cover that.