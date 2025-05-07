extends PanelContainer

@onready var label: Label = %UpgradeLabel
@onready var button: Button = %UpgradeButton

var upgrade: Upgrade
var tartarus: Node
var shop: Node

func setup(upg: Upgrade, tart: Node, shop_ref: Node):
	await ready
	upgrade = upg
	tartarus = tart
	shop = shop_ref

	var scaled_cost = upgrade.get_scaled_cost()

	if not button.is_connected("pressed", _on_upgrade_button_pressed):
		button.pressed.connect(_on_upgrade_button_pressed)

	label.text = "%s\nCost: %.2f %s%s" % [
		upgrade.name,
		scaled_cost,
		"Meaning" if upgrade.currency == Upgrade.CurrencyType.MEANING else "Happiness",
		"\n(Permanent)" if upgrade.permanent else ""
	]


	button.text = "MAXXED" if not _can_buy_more() else "BUY"
	button.disabled = not _can_afford(scaled_cost) or not _can_buy_more()


func _can_afford(cost: int) -> bool:
	match upgrade.currency:
		Upgrade.CurrencyType.MEANING:
			return tartarus.meaning >= cost
		Upgrade.CurrencyType.HAPPINESS:
			return tartarus.happiness >= cost
	return false


func _can_buy_more() -> bool:
	return upgrade.max_purchases < 0 or upgrade.times_purchased < upgrade.max_purchases

func _on_upgrade_button_pressed() -> void:
	var cost = upgrade.get_scaled_cost()
	if not _can_afford(cost) or not _can_buy_more():
		return

	match upgrade.currency:
		Upgrade.CurrencyType.MEANING:
			tartarus.meaning -= cost
		Upgrade.CurrencyType.HAPPINESS:
			tartarus.happiness -= cost

	if upgrade.effect_id in tartarus.upgrade_effects:
		tartarus.upgrade_effects[upgrade.effect_id].call(upgrade.value)

	upgrade.times_purchased += 1

	await get_tree().process_frame
	setup(upgrade, tartarus, shop)
	shop.update_ui()

func refresh():
	var scaled_cost = upgrade.get_scaled_cost()
	button.disabled = not _can_afford(scaled_cost) or not _can_buy_more()
	button.text = "MAXXED" if not _can_buy_more() else "BUY"
	label.text = "%s\nCost: %.2f %s%s" % [
		upgrade.name,
		scaled_cost,
		"Meaning" if upgrade.currency == Upgrade.CurrencyType.MEANING else "Happiness",
		"\n(Permanent)" if upgrade.permanent else ""
	]
