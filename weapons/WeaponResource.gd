# WeaponResource.gd
extends Resource
class_name WeaponResource

@export var weapon_name: String = "Default Weapon"
@export var display_text: String = "WEAPON"
## Scene for the visual representation (MUST have a BaseWeaponLogi script attached)
@export var weapon_visual_scene: PackedScene
# Add other static data later: ammo type, max ammo, etc.
