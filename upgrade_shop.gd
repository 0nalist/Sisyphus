extends Control

signal shop_closed

@export var upgrade_button_scene: PackedScene
@export var upgrade_folder_path: String = "res://upgrades/"
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

func _ready() -> void:
	print("🧪 upgrade_shop.gd ready called")


func setup(tartarus: Node) -> void:
	print("setting up")
	tartarus_ref = tartarus
	_load_upgrades()
	update_ui()

func _load_upgrades():
	print("🧪 Loading upgrades from: ", upgrade_folder_path)
	var dir := DirAccess.open(upgrade_folder_path)
	if not dir:
		print("❌ Could not open upgrade folder!")
		return

	for file in dir.get_files():
		print("➡️ Found file: ", file)
		if file.ends_with(".tres"):
			var path = upgrade_folder_path + file
			var upgrade_res = load(path)
			if upgrade_res is Upgrade:
				print("✅ Loaded Upgrade: ", upgrade_res.name)
				_add_upgrade_button(upgrade_res)
			else:
				print("⚠️ Not an Upgrade resource: ", path)


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
'''
	# Strength gain
	strength_gain_button.text = "+0.05 Strength per Suffering\nCost: 1 Meaning"
	strength_gain_button.disabled = tartarus_ref.meaning < 1

	# Strength cost reduction
	strength_cost_button.text = "-10% Strength Cost\nCost: 1 Meaning"
	strength_cost_button.disabled = tartarus_ref.meaning < 1

	# Weight gain
	weight_gain_button.text = "+0.05 Weight per Strength\nCost: 1 Meaning"
	weight_gain_button.disabled = tartarus_ref.meaning < 1

	# Weight cost reduction
	weight_cost_button.text = "-10% Weight Cost\nCost: 1 Meaning"
	weight_cost_button.disabled = tartarus_ref.meaning < 1

	# Autobuy strength
	if tartarus_ref.autobuy_strength_enabled:
		autobuy_strength_button.text = "Autobuy Strength\n✓ Purchased"
		autobuy_strength_button.disabled = true
	else:
		autobuy_strength_button.text = "Enable Autobuy Strength\nCost: 100 Happiness"
		autobuy_strength_button.disabled = tartarus_ref.happiness < 100

	# Autobuy weight
	if tartarus_ref.autobuy_weight_enabled:
		autobuy_weight_button.text = "Autobuy Weight\n✓ Purchased"
		autobuy_weight_button.disabled = true
	else:
		autobuy_weight_button.text = "Enable Autobuy Weight\nCost: 100 Happiness"
		autobuy_weight_button.disabled = tartarus_ref.happiness < 100
'''

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
