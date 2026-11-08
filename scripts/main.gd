extends Control

var press_count: int = 0

@onready var target_button: Button = %Target
@onready var count_label: Label = %Count
@onready var reset_button: Button = %Reset


func _ready() -> void:
	target_button.pressed.connect(_on_target_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	_update_count()


func _on_target_pressed() -> void:
	press_count += 1
	_update_count()


func _on_reset_pressed() -> void:
	press_count = 0
	_update_count()


func _update_count() -> void:
	count_label.text = str(press_count)
	reset_button.disabled = press_count == 0