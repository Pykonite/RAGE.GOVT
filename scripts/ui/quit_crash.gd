@tool
extends Button

const nulltheme: Theme = preload("res://assets/themes/null.tres")

func _pressed() -> void:
	show_error("Button 'MainMenu.VBoxContainer.HBoxContainer.Quit' cannot find script 'scripts/ui/quit.gd'")

func show_error(message: String) -> void:
	var dialog := AcceptDialog.new()
	add_child(dialog)
	dialog.title = "Fatal Error"
	dialog.dialog_text = message
	dialog.force_native = true
	dialog.theme = nulltheme
	dialog.popup_centered()
	
	dialog.confirmed.connect(func ():
		dialog.queue_free()
		quit()
	)
	
	dialog.canceled.connect(dialog.queue_free)

func quit() -> void:
	get_tree().quit()
