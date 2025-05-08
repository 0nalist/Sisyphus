extends Control

signal shop_closed

@export var upgrade_button_scene: PackedScene
@export var upgrade_resources: Array[Resource] = []
@onready var upgrade_container: GridContainer = %UpgradeContainer
@onready var perm_upgrade_container: GridContainer = %PermUpgradeContainer


@onready var meaning_label: Label = %MeaningLabel
@onready var happiness_label: Label = %HappinessLabel


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
	
	if upgrade.permanent:
		perm_upgrade_container.add_child(button)
	else:
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


func _on_exit_button_pressed() -> void:
	shop_closed.emit()
	queue_free()




func _on_faster_scroll_button_pressed() -> void:
	wave_scroll_speed *= 1.5


func _on_rest_scroll_button_2_pressed() -> void:
	wave_scroll_speed = 4
