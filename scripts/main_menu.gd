extends Control

func _ready():
	$VBox/StartBtn.pressed.connect(_on_start)
	$VBox/MultiplayerBtn.pressed.connect(_on_multiplayer)
	$VBox/SettingsBtn.pressed.connect(_on_settings)

func _on_start():
	get_tree().change_scene_to_file("res://scenes/battle_test.tscn")

func _on_multiplayer():
	# TODO: multiplayer lobby
	pass

func _on_settings():
	# TODO: settings
	pass
