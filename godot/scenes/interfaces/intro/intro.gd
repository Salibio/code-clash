extends CanvasLayer


@onready
var anim_player: AnimationPlayer = $Control/AnimationPlayer
@onready
var intro_bg: AudioStreamPlayer = $Control/IntroBg


func _ready() -> void:
	anim_player.play("Fade in")
	intro_bg.play()
	await get_tree().create_timer(6.0).timeout
	anim_player.play("Fade out")
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("uid://bhnu738xunaln")
