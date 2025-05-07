#main scene tartarus.gd
extends Control
 
@export var upgrade_shop_scene: PackedScene
@export var day_end_scene: PackedScene

var is_in_shop: bool = false
var autobuy_strength_enabled := false
var autobuy_weight_enabled := false


@onready var progress_bar: ProgressBar = %ProgressBar
@onready var suffering_label: Label = %SufferingLabel
@onready var strength_label: Label = %StrengthLabel
@onready var day_label: Label = %DayLabel
@onready var strength_button: Button = %StrengthButton
@onready var weight_button: Button = %WeightButton
@onready var boulder_weight_label: Label = %BoulderWeightLabel
@onready var speed_label: Label = %SpeedLabel


@onready var purchase_amount_dropdown: OptionButton = %PurchaseAmountDropdown

@onready var autobuy_strength_check_box: CheckBox = %AutobuyStrengthCheckBox
@onready var autobuy_weight_check_box: CheckBox = %AutobuyWeightCheckBox



@onready var meaning_label: Label = %MeaningLabel
@onready var happiness_label: Label = %HappinessLabel
@onready var summit_label: Label = %SummitLabel


var selected_purchase_amount: String = "1"

var boulder_weight: float = 1.0
var summit_height: float = 10000
var progress: float = 0.0

var strength: float = 1.0

var suffering: float = 0.0
var meaning: float = 0.0
var happiness: float = 0.0
var summits: int = 0

# --- Upgradeable Economy Variables ---
@export var strength_cost: float = 1.0
@export var weight_cost: float = 1.0
@export var meaning_conversion_rate: float = 1.0
@export var happiness_conversion_rate: float = 0.01
@export var reduced_meaning_rate: float = 0.1
@export var strength_gain: float = 0.1
@export var weight_gain: float = 0.1

var upgrade_effects = {
	"strength_gain_up": func(value): strength_gain += value,
	"strength_cost_down": func(value): strength_cost *= (1.0 - value), # value = 0.1 means -10%
	"weight_gain_up": func(value): weight_gain += value,
	"weight_cost_down": func(value): weight_cost *= (1.0 - value),
	"add_day_seconds": func(value): day_duration += value,
	"double_day_length": func(value): 
		#if not day_length_mult_purchased:
		day_duration *= value,
		#	day_length_mult_purchased = true,
	"enable_autobuy_strength": func(_value): autobuy_strength_enabled = true,
	"enable_autobuy_weight": func(_value): autobuy_weight_enabled = true,
}





# --- Time System ---
@export var day_duration: float = 10.0  # seconds to summit or fail
var day_timer: float = 0.0
var day_count: int = 1


func _ready() -> void:
	purchase_amount_dropdown.add_item("1")
	purchase_amount_dropdown.add_item("5")
	purchase_amount_dropdown.add_item("10")
	purchase_amount_dropdown.add_item("25")
	purchase_amount_dropdown.add_item("Max")
	
	autobuy_strength_check_box.button_pressed = autobuy_strength_enabled
	autobuy_weight_check_box.button_pressed = autobuy_weight_enabled
	
func _process(delta: float) -> void:
	if is_in_shop:
		%AnimationPlayer.stop()
		return
	%AnimationPlayer.play("roll")
	# Accumulate suffering & progress
	suffering += boulder_weight * delta
	progress += strength/boulder_weight * delta

	var projected_meaning = suffering * (meaning_conversion_rate if progress >= summit_height else reduced_meaning_rate)
	meaning_label.text = "Meaning: %.2f \n(%.2f banked + %.2f projected)" % [
		meaning + projected_meaning,
		meaning,
		projected_meaning
	]
	
	happiness_label.text = "Happiness: %.2f" % happiness
	summit_label.text = "Summits: %d" % summits
	
	# Advance the day timer
	day_timer += delta

	# Update UI
	progress_bar.value = progress / summit_height * 100.0

	suffering_label.text = "Suffering: " + ("%.2f" % suffering)
	boulder_weight_label.text = "Weight: " + ("%.2f" % boulder_weight)
	strength_label.text = "Strength: " + ("%.2f" % strength)
	var time_left = max(day_duration - day_timer, 0.0)
	day_label.text = "Day %d — %.1fs left" % [day_count, time_left]
	speed_label.text = "Speed: " + ("%.2f" % (strength/boulder_weight)) + "m/s"
	var strength_units = get_purchase_units(get_affordable_strength_units())
	var weight_units = get_purchase_units(get_affordable_weight_units())

	var total_strength_gain = strength_gain * strength_units
	var total_strength_cost = strength_units * strength_cost

	var total_weight_gain = weight_gain * weight_units
	var total_weight_cost = weight_units * weight_cost

	strength_button.text = "+%.2f Strength (Cost: %.2f Suffering)" % [
		total_strength_gain, total_strength_cost
	]
	weight_button.text = "+%.2f Weight (Cost: %.2f Strength)" % [
		total_weight_gain, total_weight_cost
	]

	
	strength_button.disabled = strength_units <= 0
	weight_button.disabled = weight_units <= 0
	
	
	
	autobuy()
	
	
	
	# Success condition
	if progress >= summit_height:
		_handle_end_of_day(true)

	# Failure condition
	if day_timer >= day_duration:
		_handle_end_of_day(false)
	
	autobuy()

func autobuy():
	# --- AUTOBUY STRENGTH ---
	if autobuy_strength_check_box.button_pressed and autobuy_strength_enabled:
		var strength_units = get_affordable_strength_units()
		if strength_units >= 1:
			suffering -= strength_cost
			strength += strength_gain
			suffering = max(suffering, 0.0)

	# --- AUTOBUY WEIGHT ---
	if autobuy_weight_check_box.button_pressed and autobuy_weight_enabled:
		var weight_units = get_affordable_weight_units()
		if weight_units >= 1:
			strength -= weight_cost
			boulder_weight += weight_gain
			strength = max(strength, 0.0)




func _handle_end_of_day(success: bool) -> void:
	var meaning_gain = suffering * (meaning_conversion_rate if success else reduced_meaning_rate)
	meaning += meaning_gain

	if success:
		happiness += meaning * happiness_conversion_rate
		summits += 1

	# Prepare result screen
	is_in_shop = true
	var result_popup = day_end_scene.instantiate()
	add_child(result_popup)

	var progress_percent = (progress / summit_height) * 100.0
	result_popup.setup(progress_percent, success)
	result_popup.continue_pressed.connect(_on_end_of_day_result_closed)

	# Reset day progress
	progress = 0.0
	suffering = 0.0
	boulder_weight = 1.0
	strength = 1.0
	day_timer = 0.0
	day_count += 1

func _on_end_of_day_result_closed() -> void:
	var shop = upgrade_shop_scene.instantiate()
	add_child(shop)
	await get_tree().process_frame
	shop.setup(self)
	shop.shop_closed.connect(_on_shop_closed)


func _on_shop_closed() -> void:
	is_in_shop = false


func get_affordable_strength_units() -> int:
	return floor(suffering / strength_cost)

func get_affordable_weight_units() -> int:
	return floor(strength / weight_cost)

func get_purchase_units(affordable: int) -> int:
	match selected_purchase_amount:
		"1": return 1
		"5": return min(5, affordable)
		"10": return min(10, affordable)
		"25": return min(25, affordable)
		"Max": return affordable
		_: return 1




func _on_strength_button_pressed() -> void:
	var affordable_units = get_affordable_strength_units()
	var units = get_purchase_units(affordable_units)

	if units > 0 and (units * strength_cost) <= suffering:
		suffering -= units * strength_cost
		strength += units * strength_gain
		suffering = max(suffering, 0.0)  # Clamp suffering just in case


func _on_weight_button_pressed() -> void:
	var affordable_units = get_affordable_weight_units()
	var units = get_purchase_units(affordable_units)

	if units > 0 and (units * weight_cost) <= strength:
		strength -= units * weight_cost
		boulder_weight += units * weight_gain
		strength = max(strength, 0.0)




func _on_purchase_amount_dropdown_item_selected(index: int) -> void:
	selected_purchase_amount = purchase_amount_dropdown.get_item_text(index)


func _on_music_button_toggled(toggled_on: bool) -> void:
	print("Toggled:", toggled_on)
	if toggled_on:
		%MusicPlayer.play()
	else:
		%MusicPlayer.stop()


func _on_autobuy_strength_check_box_toggled(toggled_on: bool) -> void:
	autobuy_strength_enabled = toggled_on

func _on_autobuy_weight_check_box_toggled(toggled_on: bool) -> void:
	autobuy_weight_enabled = toggled_on
