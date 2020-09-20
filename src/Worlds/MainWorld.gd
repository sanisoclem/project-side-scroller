extends Node2D


onready var playerStatusLabel = $CanvasLayer/PlayerStatus
onready var playerDirectionLabel = $CanvasLayer/playerDirection

func _on_Adventurer_direction_changed(direction):
	playerDirectionLabel.text = "Direction: %d" % direction

func _on_Adventurer_status_changed(status):
	playerStatusLabel.text = status
