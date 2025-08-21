extends Control

# Магазин апгрейдов: загружает список из JSON и позволяет покупать за основную валюту

var upgrades: Dictionary = {}

@onready var list_container: VBoxContainer = $Panel/Margin/VBox/Items
@onready var close_button: Button = $Panel/Margin/VBox/CloseButton
@onready var overlay: ColorRect = $Overlay
@onready var panel: Panel = $Panel

var _show_tween: SceneTreeTween
var _hide_tween: SceneTreeTween
const SHOW_DURATION := 0.22
const HIDE_DURATION := 0.18
const SCALE_MIN := 0.95

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	
	_prepare_initial_state()
	
	_load_upgrades()
	_render_items()

func _on_close_pressed() -> void:
	animate_hide()

func _prepare_initial_state() -> void:
	overlay.visible = true
	overlay.modulate.a = 0.0
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.visible = true
	panel.scale = Vector2(SCALE_MIN, SCALE_MIN)
	panel.modulate.a = 0.0
	animate_show()

func animate_show() -> void:
	if _hide_tween:
		_hide_tween.kill()
	if _show_tween:
		_show_tween.kill()
	_show_tween = create_tween()
	_show_tween.set_parallel(true)
	_show_tween.tween_property(overlay, "modulate:a", 1.0, SHOW_DURATION).set_ease(Tween.EASE_OUT)
	_show_tween.tween_property(panel, "modulate:a", 1.0, SHOW_DURATION).set_ease(Tween.EASE_OUT)
	_show_tween.tween_property(panel, "scale", Vector2(1, 1), SHOW_DURATION).set_ease(Tween.EASE_OUT)

func animate_hide() -> void:
	if _show_tween:
		_show_tween.kill()
	if _hide_tween:
		_hide_tween.kill()
	_hide_tween = create_tween()
	_hide_tween.set_parallel(true)
	_hide_tween.tween_property(overlay, "modulate:a", 0.0, HIDE_DURATION).set_ease(Tween.EASE_IN)
	_hide_tween.tween_property(panel, "modulate:a", 0.0, HIDE_DURATION).set_ease(Tween.EASE_IN)
	_hide_tween.tween_property(panel, "scale", Vector2(SCALE_MIN, SCALE_MIN), HIDE_DURATION).set_ease(Tween.EASE_IN)
	_hide_tween.finished.connect(func(): queue_free())

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
	for child in list_container.get_children():
		child.queue_free()
	for upg_id in upgrades.keys():
		var data: Dictionary = upgrades[upg_id]
		var h := HBoxContainer.new()
		h.custom_minimum_size = Vector2(0, 32)
		h.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
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
		print("[ShopPanel] purchase ", upg_id, ": applying ", stat, " +", value)
		GameManager.apply_upgrade_effect(stat, value)
		print("[ShopPanel] after apply: click_multiplier=", GameManager.click_multiplier, ", level=", GameManager.get_upgrade_level(upg_id))
	EventBus.emit_signal("upgrade_purchased", upg_id)
	_render_items()
