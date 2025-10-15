class_name Leaderboard_Table
extends VBoxContainer

@export
var entry_scene: PackedScene
@onready
var entries_container = $NinePatchRect/VBoxContainer


func _ready():
	add_entry("alice", 12.0, 15.0)
	add_entry("ryan", 12.0, 15.0)
	add_entry("goku", 12.0, 15.0)


func add_entry(player_name: String, speed: float, accuracy: float):
	var entry: LeaderboardEntry = entry_scene.instantiate()
	entry.player_name = player_name
	entry.speed = speed
	entry.accuracy = accuracy
	entries_container.add_child(entry)
