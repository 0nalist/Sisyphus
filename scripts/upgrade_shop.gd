extends Control

signal shop_closed

@export var upgrade_button_scene: PackedScene
@export var upgrade_resources: Array[Resource] = []
@onready var upgrade_container: GridContainer = %UpgradeContainer


@onready var meaning_label: Label = %MeaningLabel
@onready var happiness_label: Label = %HappinessLabel

@onready var strength_gain_button: Button = %StrengthGainButton
@onready var strength_cost_button: Button = %StrengthCostButton
@onready var weight_gain_button: Button = %WeightGainButton
@onready var weight_cost_button: Button = %WeightCostButton
@onready var autobuy_strength_button: Button = %AutobuyStrengthButton
@onready var autobuy_weight_button: Button = %AutobuyWeightButton
@onready var day_length_flat_button: Button = %DayLengthFlatButton
@onready var day_length_mult_button: Button = %DayLengthMultButton


@onready var exit_button: Button = %ExitButton

var tartarus_ref: Node
var upgrade_buttons := []

var wave_scroll_speed: int = 4


func _ready() -> void:
	print("🧪 upgrade_shop.gd ready called")
	set_process(true)

func setup(tartarus: Node) -> void:
	print("setting up")
	tartarus_ref = tartarus

	# Pass upgrades to tartarus so it can reset them on ascend
	if tartarus_ref.has_method("set_upgrades_to_reset"):
		tartarus_ref.set_upgrades_to_reset(upgrade_resources)

	_load_upgrades()
	update_ui()


func _load_upgrades():
	for upgrade_res in upgrade_resources:
		if upgrade_res is Upgrade:
			print("✅ Loaded Upgrade: ", upgrade_res.name)
			_add_upgrade_button(upgrade_res)
		else:
			print("⚠️ Skipped non-upgrade resource")


func _add_upgrade_button(upgrade: Upgrade):
	var button = upgrade_button_scene.instantiate()
	button.setup(upgrade, tartarus_ref, self)
	upgrade_container.add_child(button)
	upgrade_buttons.append(button)


func update_ui() -> void:
	meaning_label.text = "Meaning: %.1f" % tartarus_ref.meaning
	happiness_label.text = "Happiness: %.1f" % tartarus_ref.happiness

	for button in upgrade_buttons:
		button.refresh()


func _process(_delta: float) -> void:
	%Parallax2D.autoscroll.x = wave_scroll_speed
	%Parallax2D2.autoscroll.x = -wave_scroll_speed

func _on_strength_upgrade_button_pressed() -> void:
	if tartarus_ref.meaning >= 10:
		tartarus_ref.meaning -= 10
		tartarus_ref.strength_gain += 0.1
		update_ui()

func _on_strength_cost_upgrade_button_pressed() -> void:
	if tartarus_ref.happiness >= 10:
		tartarus_ref.happiness -= 10
		tartarus_ref.strength_cost = max(tartarus_ref.strength_cost - 0.1, 0.1)
		update_ui()



func _on_exit_button_pressed() -> void:
	shop_closed.emit()
	queue_free()


func _on_strength_gain_button_pressed() -> void:
	if tartarus_ref.meaning >= 1:
		tartarus_ref.meaning -= 1
		tartarus_ref.strength_gain += 0.05
		update_ui()

func _on_strength_cost_button_pressed() -> void:
	if tartarus_ref.meaning >= 1:
		tartarus_ref.meaning -= 1
		tartarus_ref.strength_cost *= 0.9
		update_ui()

func _on_weight_gain_button_pressed() -> void:
	if tartarus_ref.meaning >= 1:
		tartarus_ref.meaning -= 1
		tartarus_ref.weight_gain += 0.05
		update_ui()

func _on_weight_cost_button_pressed() -> void:
	if tartarus_ref.meaning >= 1:
		tartarus_ref.meaning -= 1
		tartarus_ref.weight_cost *= 0.9
		update_ui()

func _on_autobuy_strength_button_pressed() -> void:
	if tartarus_ref.happiness >= 100 and not tartarus_ref.autobuy_strength_enabled:
		tartarus_ref.happiness -= 100
		tartarus_ref.autobuy_strength_enabled = true
		autobuy_strength_button.disabled = true
		update_ui()

func _on_autobuy_weight_button_pressed() -> void:
	if tartarus_ref.happiness >= 100 and not tartarus_ref.autobuy_weight_enabled:
		tartarus_ref.happiness -= 100
		tartarus_ref.autobuy_weight_enabled = true
		autobuy_weight_button.disabled = true
		update_ui()


func _on_day_length_flat_button_pressed() -> void:
	pass # Replace with function body.


func _on_day_length_mult_button_pressed() -> void:
	pass # Replace with function body.


func _on_faster_scroll_button_pressed() -> void:
	wave_scroll_speed *= 1.5


func _on_rest_scroll_button_2_pressed() -> void:
	wave_scroll_speed = 4
