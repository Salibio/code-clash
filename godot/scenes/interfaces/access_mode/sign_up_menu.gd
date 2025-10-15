extends CanvasLayer

@onready
var hover_sfx: AudioStreamPlayer = $hover_fx

@onready
var email_input: LineEdit = $SignUpMenu/VBoxContainer/Email
@onready
var pass_input: LineEdit = $SignUpMenu/VBoxContainer2/pass

@onready
var status: RichTextLabel = $SignUpMenu/AuthStatusLabel

@onready
var register_btn: Button = $SignUpMenu/RegisterButton

# New variable to track password visibility state
var is_password_visible: bool = false

func _on_back_button_menu_pressed() -> void:
	get_tree().change_scene_to_file("uid://coa2mfgcnskhv")


func _on_mouse_entered() -> void:
	hover_sfx.play()


func _on_register_button_pressed() -> void:
	register_btn.disabled = true
	var auth_status: String = await Auth.register(email_input.text, pass_input.text)
	status.text = auth_status
	register_btn.disabled = false

	if auth_status == "Success":
		get_tree().change_scene_to_file("uid://bk7f11a367b30")

# New function to toggle the password visibility
func _on_show_password_pressed() -> void:
		# 1. Toggle the state
	is_password_visible = not is_password_visible

	# 2. Update the LineEdit's 'secret' property
	# If 'is_password_visible' is TRUE, 'secret' becomes FALSE (password shows).
	# If 'is_password_visible' is FALSE, 'secret' becomes TRUE (password hides).
	pass_input.secret = not is_password_visible
