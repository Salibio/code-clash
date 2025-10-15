extends CanvasLayer


@onready
var hover_sfx: AudioStreamPlayer = $hover_fx


func _on_yes_button_pressed() -> void:
	get_tree().change_scene_to_file("uid://coa2mfgcnskhv")


func _on_no_button_pressed() -> void:
	get_tree().quit()


func _on_mouse_entered() -> void:
	hover_sfx.play()
