extends Control

signal continue_pressed
signal ascend_pressed

@onready var result_label: Label = %ResultLabel
@onready var continue_button: Button = %ContinueButton
@onready var ascend_button: Button = %AscendButton


var full_text := ""
var reveal_tween: Tween
var summited: bool = false

func setup(progress_percent: float, reached_summit: bool) -> void:
	ascend_button.hide()
	continue_button.hide()
	
	# Choose the message
	if reached_summit:
		full_text = "After toiling all day, you reach the summit of the mountain! As the boulder slips away and rolls all the way back down the mountain, you are filled with a sense of accomplishment."
		summited = true
	elif progress_percent >= 50.0:
		full_text = "With the summit in sight, the day comes to an end, and the boulder slips away and rolls all the way back down the mountain."
		summited = false
	else:
		full_text = "After a long hard day with little to show for it but suffering, the boulder slips away and rolls all the way back down the mountain."
		summited = false
	
	# Fade in the label container
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.6)

	# Typewriter text reveal
	result_label.visible_characters = 0
	result_label.text = full_text

	reveal_tween = create_tween()
	reveal_tween.tween_property(result_label, "visible_characters", full_text.length(), 4.0).set_trans(Tween.TRANS_LINEAR)

	# Enable button after full text reveal
	reveal_tween.tween_callback(Callable(self, "_on_text_reveal_finished"))
	
	
	continue_button.disabled = true
	continue_button.visible = false

func _on_text_reveal_finished() -> void:
	continue_button.disabled = false
	continue_button.visible = true
	if summited:
		ascend_button.disabled = false
		ascend_button.visible = true

func _on_continue_button_pressed() -> void:
	continue_pressed.emit()
	queue_free()


func _on_ascend_button_pressed() -> void:
	ascend_pressed.emit()
	
	queue_free()
