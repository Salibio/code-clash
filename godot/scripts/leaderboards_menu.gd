extends Control

@onready var level_rank: Button = $HBoxContainer2/Level_Rank
@onready var global_rank: Button = $"HBoxContainer2/Global Rank"
@onready var level_panel: Panel = $HBoxContainer2/Level_Rank/NinePatchRect/level_Panel
@onready var global_panel: Panel = $"HBoxContainer2/Global Rank/NinePatchRect/Global_Panel"

func _ready():
	level_rank.visible =true
	level_panel.visible =false
	global_rank.visible = true
	global_panel.visible = false


func _on_level_rank_pressed() -> void:
	level_rank.visible =true
	level_panel.visible =true
	global_panel.visible =false



func _on_global_rank_pressed() -> void:
	global_rank.visible =true
	global_panel.visible =true
	level_panel.visible =false
