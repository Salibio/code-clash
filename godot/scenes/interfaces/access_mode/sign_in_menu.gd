extends CanvasLayer

@onready
var hover_sfx: AudioStreamPlayer = $hover_fx

@onready
var email_input: LineEdit = $SignInMenu/VBoxContainer/Email
@onready
var pass_input: LineEdit = $SignInMenu/VBoxContainer2/pass

@onready
var status: RichTextLabel = $SignInMenu/AuthStatusLabel

@onready
var login_btn: Button = $SignInMenu/Login_Button

# New variable to track password visibility state
var is_password_visible = false


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("uid://coa2mfgcnskhv")


func _on_mouse_entered() -> void:
	hover_sfx.play()


func _on_login_button_pressed() -> void:
	login_btn.disabled = true
	var auth_status: String = await Auth.login(email_input.text, pass_input.text)
	status.text = auth_status
	login_btn.disabled = false

	if auth_status == "Success":
		get_tree().change_scene_to_file("uid://bk7f11a367b30")

# --- New Function to Toggle Password Visibility ---
func _on_show_password_pressed() -> void:
	# 1. Toggle the state variable
	is_password_visible = not is_password_visible

	# 2. Update the LineEdit's 'secret' property
	# If is_password_visible is true, 'secret' must be false (to show the text)
	# If is_password_visible is false, 'secret' must be true (to hide the text)
	pass_input.secret = not is_password_visible

	# Optional: Logic to change the TextureButton's icon (eye-open/eye-closed)
	# If your toggle button is named 'show_password' in the scene:
	# var show_pass_button = $SignInMenu/VBoxContainer2/show_password
	# if is_password_visible:
	#     show_pass_button.texture_normal = load("res://path/to/eye_open.png")
	# else:
	#     show_pass_button.texture_normal = load("res://path/to/eye_closed.png")
# --------------------------------------------------

func _on_back_button_menu_pressed():
	get_tree().change_scene_to_file("uid://coa2mfgcnskhv")
