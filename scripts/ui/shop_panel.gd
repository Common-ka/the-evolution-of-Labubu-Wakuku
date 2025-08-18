extends Control

# Магазин апгрейдов: загружает список из JSON и позволяет покупать за основную валюту

var upgrades: Dictionary = {}

@onready var list_container: VBoxContainer = $Panel/Margin/VBox/Items
@onready var close_button: Button = $Panel/Margin/VBox/CloseButton

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	_load_upgrades()
	_render_items()

func _on_close_pressed() -> void:
	queue_free()

func _load_upgrades() -> void:
	var path := "res://data/upgrades.json"
	if not FileAccess.file_exists(path):
		push_warning("upgrades.json not found: %s" % path)
		upgrades = {}
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		upgrades = {}
		return
	var txt := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) == OK:
		upgrades = json.data
	else:
		push_warning("Failed to parse upgrades.json")
		upgrades = {}

func _render_items() -> void:
	list_container.queue_free_children()
	for upg_id in upgrades.keys():
		var data: Dictionary = upgrades[upg_id]
		var h := HBoxContainer.new()
		h.custom_minimum_size = Vector2(0, 32)
		var name_label := Label.new()
		name_label.text = "%s (ур.%d)" % [String(data.get("name", upg_id)), GameManager.get_upgrade_level(upg_id)]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(name_label)
		var cost: int = _calc_cost(upg_id, data)
		var cost_label := Label.new()
		cost_label.text = "%d" % cost
		h.add_child(cost_label)
		var buy := Button.new()
		buy.text = "Купить"
		buy.disabled = GameManager.current_currency < cost or GameManager.get_upgrade_level(upg_id) >= int(data.get("max_level", 1))
		buy.pressed.connect(func(): _on_buy_pressed(upg_id))
		h.add_child(buy)
		list_container.add_child(h)

func _calc_cost(upg_id: String, data: Dictionary) -> int:
	var lvl := GameManager.get_upgrade_level(upg_id)
	var base_cost := float(data.get("base_cost", 1))
	var growth := float(data.get("growth", 1.0))
	return int(floor(base_cost * pow(growth, lvl)))

func _on_buy_pressed(upg_id: String) -> void:
	var data: Dictionary = upgrades.get(upg_id, {})
	if data.is_empty():
		return
	var cost := _calc_cost(upg_id, data)
	if not GameManager.spend_currency(cost):
		return
	# повысить уровень
	GameManager.increment_upgrade_level(upg_id)
	# применить эффект
	var stat := String(data.get("stat", ""))
	var value := float(data.get("value", 0.0))
	if stat != "":
		GameManager.apply_upgrade_effect(stat, value)
	EventBus.emit_signal("upgrade_purchased", upg_id)
	_render_items()

