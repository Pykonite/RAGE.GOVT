@tool
extends Button

func _pressed() -> void:
	show_error("Button 'MainMenu.VBoxContainer.HBoxContainer.Quit' cannot find script 'scripts/ui/quit.gd'")

func show_error(message: String) -> void:
	OS.alert(message, "Fatal Error")
	get_tree().quit()
