@tool
extends Resource
class_name Upgrade


enum CurrencyType { MEANING, HAPPINESS }

@export var name: String
@export var description: String
@export var base_cost: float = 1.0
@export var currency: CurrencyType = CurrencyType.MEANING
@export var max_purchases: int = -1  # -1 = unlimited
@export var effect_id: String
@export var value: float = 0.0  # How much this upgrade changes the variable

@export var times_purchased: int = 0
var on_purchase: Callable = func(): pass

func can_afford(player_node: Node) -> bool:
	var cost = get_scaled_cost()
	match currency:
		CurrencyType.MEANING:
			return player_node.meaning >= cost
		CurrencyType.HAPPINESS:
			return player_node.happiness >= cost
	return false

func is_available() -> bool:
	return max_purchases < 0 or times_purchased < max_purchases

func purchase(player_node: Node) -> bool:
	var cost = get_scaled_cost()
	if not can_afford(player_node) or not is_available():
		return false

	match currency:
		CurrencyType.MEANING:
			player_node.meaning -= cost
		CurrencyType.HAPPINESS:
			player_node.happiness -= cost

	times_purchased += 1
	on_purchase.call()
	return true

func get_scaled_cost() -> float:
	var raw_cost = base_cost * pow(1.1, times_purchased)
	return round(raw_cost * 100.0) / 100.0
