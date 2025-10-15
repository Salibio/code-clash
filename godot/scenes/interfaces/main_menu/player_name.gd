extends Control

@onready var start_button: Button = $BG/TouchScreenButton/start
@onready var line_edit: LineEdit = $BG/TouchScreenButton/Player_name
@onready var name_label: Label = $BG/TouchScreenButton/name


func _on_line_edit_text_entered(newtext: String) -> void:
	name_label.text = "PlayerName: " + newtext


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("uid://bmkjgidroq0ek")


func _on_start_mouse_entered() -> void:
	$BG/TouchScreenButton/hover_fx.play()
