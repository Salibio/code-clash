extends Control

@onready var inputname: LineEdit = $TouchScreenButton/VBoxContainer/Input_Name
@onready var namelabel: Label = $TouchScreenButton/VBoxContainer/Name_Label


func _ready():
	inputname.text_submitted.connect(_on_LineEdit_text_entered)

func _on_LineEdit_text_entered(new_text: String):
	namelabel.text = "Your Name is: " + new_text
