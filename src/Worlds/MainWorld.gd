extends Node2D


onready var playerStatusLabel = $CanvasLayer/PlayerStatus


func _on_Player_status_changed(status):
	playerStatusLabel.text = status
