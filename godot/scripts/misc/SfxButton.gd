extends TextureButton


var sfx_bus: int = AudioServer.get_bus_index("SFX")

func _on_pressed() -> void:
	AudioServer.set_bus_mute(sfx_bus, not AudioServer.is_bus_mute(sfx_bus))
