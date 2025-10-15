extends TextureButton

func _on_pressed() -> void:
	get_tree().change_scene_to_file("uid://bk7f11a367b30")

func _on_mouse_entered() -> void:
	$hover_fx.play()
