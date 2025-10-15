extends HSlider

@export var audio_bus_name: String


var audio_bus_id: int


func _ready() -> void:
	audio_bus_id = AudioServer.get_bus_index(audio_bus_name)


func _on_value_changed(new_value: float) -> void:
	var db: float = linear_to_db(new_value)
	AudioServer.set_bus_volume_db(audio_bus_id, db)
