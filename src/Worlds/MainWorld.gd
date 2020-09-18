extends Node2D


onready var playerStatusLabel = $CanvasLayer/PlayerStatus
onready var playerDirectionLabel = $CanvasLayer/playerDirection

func _on_Player_status_changed(status):
	playerStatusLabel.text = status


func _on_Player_direction_changed(direction):
	playerDirectionLabel.text = "Direction: %d" % direction
