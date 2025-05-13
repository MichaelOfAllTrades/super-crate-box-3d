# LaserTip.gd
extends Area3D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(100)