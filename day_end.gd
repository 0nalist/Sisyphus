extends Control

signal continue_pressed

@onready var result_label: Label = %ResultLabel
@onready var continue_button: Button = %ContinueButton
@onready var double_mountain_button: Button = %DoubleMountainButton


var full_text := ""
var reveal_tween: Tween

func setup(progress_percent: float, reached_summit: bool) -> void:
	# Choose the message
	if reached_summit:
		full_text = "After toiling all day, you reach the summit of the mountain! As the boulder slips away and rolls all the way back down the mountain, you are filled with a sense of accomplishment."
		
	elif progress_percent >= 50.0:
		full_text = "With the summit in sight, the day comes to an end, and the boulder slips away and rolls all the way back down the mountain."
	else:
		full_text = "After a long hard day with little to show for it but suffering, the boulder slips away and rolls all the way back down the mountain."

	# Fade in the label container (whole scene if desired)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.6)

	# Start the typewriter text reveal
	result_label.visible_characters = 0
	result_label.text = full_text

	reveal_tween = create_tween()
	reveal_tween.tween_property(result_label, "visible_characters", full_text.length(), 4.0).set_trans(Tween.TRANS_LINEAR)

	# Enable button after full text reveal
	reveal_tween.tween_callback(Callable(self, "_on_text_reveal_finished"))
	
	if reached_summit:
		double_mountain_button.visible = true
	
	continue_button.disabled = true
	continue_button.visible = false

func _on_text_reveal_finished() -> void:
	continue_button.disabled = false
	continue_button.visible = true
	double_mountain_button.disabled = false

func _on_continue_button_pressed() -> void:
	continue_pressed.emit()
	queue_free()
