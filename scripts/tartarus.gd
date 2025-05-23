#main scene tartarus.gd
extends Control
 
@export var upgrade_shop_scene: PackedScene
@export var day_end_scene: PackedScene

var is_in_shop: bool = false
var autobuy_strength_enabled := false
var autobuy_weight_enabled := false
var autoreflect_enabled := false
var autoascend_enabled := false

var double_suffering_enabled := false

var upgrades_to_reset: Array[Upgrade] = []
var all_upgrades: Array[Upgrade] = []

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
@onready var autoreflect_check_box: CheckBox = %AutoreflectCheckBox
@onready var auto_ascend_check_box: CheckBox = %AutoAscendCheckBox



@onready var meaning_label: Label = %MeaningLabel
@onready var happiness_label: Label = %HappinessLabel
@onready var summit_label: Label = %SummitLabel
@onready var mountain_heigh_label: Label = %MountainHeightLabel

@onready var playtime_label: Label = %PlaytimeLabel
var total_playtime := 0.0

var selected_purchase_amount: String = "1"

var boulder_weight: float = 1.0
var summit_height: int = 32
var progress: float = 0.0

var strength: float = 1.0

var suffering: float = 0.0
var meaning: float = 0.0
var happiness: float = 0.0
var summits: int = 0

var morning_strength: float = 1.0
var morning_weight: float = 1.0


var passive_meaning_rate := 0.0
var permanent_passive_meaning:= 0.0

var happiness_sacrifice_rate := 0.0

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
	"add_day_seconds_temp": func(value): day_length_bonus_temporary += value,
	"add_day_seconds_permanent": func(value): day_length_bonus_permanent += value,
	"double_day_length": func(value): 
		#if not day_length_mult_purchased:
		day_length_bonus_permanent *= value
		day_length_bonus_temporary *= value,
		#	day_length_mult_purchased = true,
	"enable_autobuy_strength": func(_value):
		autobuy_strength_enabled = true
		autobuy_strength_check_box.visible = true,
	"meaning_per_second_up": func(value): passive_meaning_rate += value,
	"enable_autobuy_weight": func(_value):
		autobuy_weight_enabled = true
		autobuy_weight_check_box.visible = true,
	"enable_autoreflect": func(_value):
		autoreflect_check_box.visible = true,
	"enable_autoascend": func(_value):
		auto_ascend_check_box.visible = true,
	"get_sticker": func(_value):
		get_next_sticker(),
	"passive_meaning_per_1000_happiness": func(value):
		permanent_passive_meaning += value,
	"double_suffering": func(_value):
		double_suffering_enabled = true,
	"starting_strength": func(value):
		pass,
		#morning_strength += value,
		#print("🔁 Upgrade applied: morning_strength is now", morning_strength),
	"starting_weight": func(value):
		pass,
		#morning_weight += value,
	"sacrifice_happiness": func(value):
		happiness_sacrifice_rate += value
}

const MOUNTAIN_NAMES = [
	"Orvilos", "Erymanthos", "Falakro", "Vasilitsa", "Athamanika", "Lakmos",
	"Tymfristos", "Varnous", "Sternes", "Svourichti", "Aroania", "Bournelos", "Gavala",
	"Kyllini", "Thodoris", "Mesa Soros", "Trocharis", "Taygetus", "Pachnes", "Timios Stavros",
	"Parnassus", "Vardousia", "Tymfi", "Giona", "Gramos", "Kaimaktsalan", "Smolikas", "Olympus",
	"Olympus 2", "Olympus 3", "Olympus 4", "Olympus 5", "Olympus 6", "Olympus 7", "Olympus 9", "Olympus 10", 
	"Olympus 11", "Olympus 12",  "Olympus 13",  "Olympus 14",  "Olympus 15",  "Olympus 16", "Olympus 17",
	"Olympus 18",  "Olympus 19",  "Olympus 20",  "Olympus 21",  "Olympus 22",  "Olympus 23", "Olympus 24", 
	"Olympus 25", "Olympus 26", "Olympus 27", "Olympus 28", "Olympus 29",  
]


func get_current_mountain_name() -> String:
	return "Mount " + MOUNTAIN_NAMES[min(summits, MOUNTAIN_NAMES.size() - 1)]




# --- Time System ---
@export var day_duration: float = 10.0  # seconds to summit or fail
var day_length_bonus_temporary := 0.0
var day_length_bonus_permanent := 0.0
var day_timer: float = 0.0
var day_count: int = 1
@onready var timer: Timer = %Timer

func _ready() -> void:
	purchase_amount_dropdown.add_item("1")
	purchase_amount_dropdown.add_item("5")
	purchase_amount_dropdown.add_item("10")
	purchase_amount_dropdown.add_item("25")
	purchase_amount_dropdown.add_item("Max")
	
	autobuy_strength_check_box.button_pressed = autobuy_strength_enabled
	autobuy_weight_check_box.button_pressed = autobuy_weight_enabled
	
	update_mountain_height_label()
	
	
	autoreflect_check_box.hide()
	auto_ascend_check_box.hide()
	autobuy_strength_check_box.hide()
	autobuy_weight_check_box.hide()
	
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	if is_in_shop:
		return
	var percent_increase = (summits) / 100.0
	strength += strength * percent_increase


func _process(delta: float) -> void:
	total_playtime += delta
	# Update label every 30 frames
	if Engine.get_frames_drawn() % 30 == 0:
		var hours = int(total_playtime) / 3600
		var minutes = (int(total_playtime) % 3600) / 60
		var seconds = int(total_playtime) % 60
		playtime_label.text = "Playtime: %02d:%02d:%02d" % [hours, minutes, seconds]
	
	
	if is_in_shop:
		%AnimationPlayer.stop()
		return
	
	
	if strength / boulder_weight < 0.05:
		%AnimationPlayer.play("struggle")
	else:
		%AnimationPlayer.play("roll")
	# Accumulate suffering & progress
	if double_suffering_enabled:
		suffering += boulder_weight * delta * 2
	else:
		suffering += boulder_weight * delta
	progress += strength/boulder_weight * delta
	
	meaning += passive_meaning_rate * delta
	var happiness_thousands = int(happiness/1000)
	meaning += permanent_passive_meaning * happiness_thousands * delta
	var projected_meaning = suffering * (meaning_conversion_rate if progress >= summit_height else reduced_meaning_rate)
	meaning_label.text = "%.2f Meaning \n(%.2f banked + %.2f projected)" % [
		meaning + projected_meaning,
		meaning,
		projected_meaning
	] 
	
	happiness_label.text = "%.2f Happiness" % happiness
	if summits == 1:
		summit_label.text = "%d Ascent " % summits
	else:
		summit_label.text = "%d Ascents" % summits
	
	# Advance the day timer
	day_timer += delta

	# Update UI
	progress_bar.value = progress / summit_height * 100.0

	var scroll_speed = (strength / boulder_weight)*2
	%Parallax2D.autoscroll.x = -scroll_speed
	%Parallax2D2.autoscroll = Vector2(2, -1) * -scroll_speed
	if %Parallax2D2.scroll_offset.y > 727.5:
		%Parallax2D2.scroll_offset = Vector2(1820, 42)
	#print("Sprite Global Pos:", background_sprite.global_position)
	
	
	suffering_label.text = "Suffering: " + ("%.2f" % suffering)
	boulder_weight_label.text = "Weight: " + ("%.2f" % boulder_weight)
	strength_label.text = "Strength: " + ("%.2f" % strength)
	var time_left = max(get_day_duration() - day_timer, 0.0)
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
	
	if happiness > 0:
		happiness -= happiness_sacrifice_rate * delta
		suffering += happiness_sacrifice_rate * delta
	
	autobuy()
	
	

	
	# Success condition
	if progress >= summit_height:
		_handle_end_of_day(true)

	# Failure condition
	if day_timer >= get_day_duration():
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

func apply_starting_stat_upgrades():
	morning_strength = 1.0
	morning_weight = 1.0
	for upgrade in all_upgrades:
		match upgrade.effect_id:
			"starting_strength":
				morning_strength += upgrade.value * upgrade.times_purchased
			"starting_weight":
				morning_weight += upgrade.value * upgrade.times_purchased



var stickers: Array[Texture] = [
	
]
func get_next_sticker():
	
	stickers.pop_front()


func update_mountain_height_label():
	%MountainNameLabel.text = get_current_mountain_name()
	%MountainHeightLabel.text = str(summit_height) + "m"

func _handle_end_of_day(success: bool) -> void:
	var meaning_gain = suffering * (meaning_conversion_rate if success else reduced_meaning_rate)
	meaning += meaning_gain

	var mountain_name = get_current_mountain_name()

	if success:
		happiness += meaning * happiness_conversion_rate
		summits += 1


	# Reset day progress
	progress = 0.0
	suffering = 0.0
	boulder_weight = morning_weight
	strength = morning_strength
	day_timer = 0.0
	day_count += 1

	# Continue as normal...
	is_in_shop = true
	var result_popup = day_end_scene.instantiate()
	add_child(result_popup)

	if autoascend_enabled and success:
		await get_tree().create_timer(.4).timeout
		result_popup._on_ascend_button_pressed()
		_on_ascend_pressed()
		is_in_shop = false
	elif autoreflect_enabled:
		await get_tree().create_timer(.4).timeout
		result_popup._on_continue_button_pressed()
		is_in_shop = false

	var progress_percent = (progress / summit_height) * 100.0
	result_popup.setup(progress_percent, success, mountain_name, total_playtime)
	result_popup.continue_pressed.connect(_on_end_of_day_result_closed)
	result_popup.ascend_pressed.connect(_on_ascend_pressed)

func _on_end_of_day_result_closed() -> void:
	var shop = upgrade_shop_scene.instantiate()
	add_child(shop)
	await get_tree().process_frame
	shop.setup(self)
	shop.shop_closed.connect(_on_shop_closed)
	if autoreflect_enabled:
		await get_tree().create_timer(0.2).timeout
		shop.exit_button.emit_signal("pressed")
	%Parallax2D2.scroll_offset = Vector2(1820,991)

func _on_ascend_pressed() -> void:
	summit_height *= 2
	_reset_progress(true)
	
	is_in_shop = false
	update_mountain_height_label()
	%Parallax2D2.scroll_offset = Vector2(1820,991)

func _reset_progress(preserve_happiness: bool = false) -> void:
	progress = 0.0
	suffering = 0.0
	boulder_weight = 1.0
	strength = 1.0
	day_timer = 0.0
	#day_count = 1

	meaning = 0.0
	if not preserve_happiness:
		happiness = 0.0

	strength_cost = 1.0
	weight_cost = 1.0
	strength_gain = 0.1
	weight_gain = 0.1

	##Commenting out to make autobuys permanent
	'''
	autobuy_strength_enabled = false
	autobuy_weight_enabled = false
	autobuy_strength_check_box.visible = false
	autobuy_weight_check_box.visible = false
	autobuy_strength_check_box.button_pressed = false
	autobuy_weight_check_box.button_pressed = false
	autoreflect_check_box.visible = false
	autoreflect_check_box.button_pressed = false
	'''
	
	passive_meaning_rate = 0
	double_suffering_enabled = false
	
	happiness_sacrifice_rate = 0
	
	## Reset upgrades
	for upgrade in upgrades_to_reset:
		if upgrade is Upgrade:
			if not upgrade.permanent:
				upgrade.times_purchased = 0

func _on_shop_closed() -> void:
	is_in_shop = false
	for upgrade in all_upgrades:
		if upgrade.effect_id in upgrade_effects:
			var effect_func = upgrade_effects[upgrade.effect_id]
			for i in upgrade.times_purchased:
				effect_func.call(upgrade.value)
	
	apply_starting_stat_upgrades()

	# Set strength/weight
	strength = morning_strength
	boulder_weight = morning_weight

	print("New morning_strength:", morning_strength)
	print("New morning_weight:", morning_weight)

func get_day_duration() -> float:
	var base := day_duration + get_day_length_bonus("add_day_seconds_temp") + get_day_length_bonus("add_day_seconds_permanent")
	var multiplier := 1.0 + get_day_length_bonus("double_day_length")  # e.g. value 1.0 means double
	return base * multiplier

func get_day_length_bonus(effect_id: String) -> float:
	var total := 0.0
	for upgrade in all_upgrades:
		if upgrade.effect_id == effect_id:
			total += upgrade.value * upgrade.times_purchased
	return total


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


func set_upgrades_to_reset(resources: Array[Resource]) -> void:
	upgrades_to_reset.clear()
	all_upgrades.clear()
	for res in resources:
		if res is Upgrade:
			all_upgrades.append(res)
			if not res.permanent:
				upgrades_to_reset.append(res)

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


func _on_autoreflect_check_box_toggled(toggled_on: bool) -> void:
	autoreflect_enabled = toggled_on


func _on_auto_ascend_check_box_toggled(toggled_on: bool) -> void:
	autoascend_enabled = toggled_on
