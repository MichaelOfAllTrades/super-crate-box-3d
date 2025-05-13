# MineRaycastEvents.gd
extends Node

# Emitted by Player every physics frame when mine weapon is active
# target_transform: Where the shadow should be and how it should be oriented
# can_deploy: True if the current position is valid for deployment.
signal mine_shadow_update(target_transform: Transform3D, can_deploy: bool)

# Emitted by Player when the fire button is pressed and conditions are met for mine deployment.
# deploy_transform: The final transform where the mine should be placed.
signal mine_deploy_requested(deploy_transform: Transform3D)