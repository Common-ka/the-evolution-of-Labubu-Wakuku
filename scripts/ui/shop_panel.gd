extends Control

# Магазин апгрейдов: загружает список из JSON и позволяет покупать за основную валюту
# Теперь с поддержкой категорий и вкладок

var upgrades: Dictionary = {}
var categories: Dictionary = {}
var current_category: String = ""

@onready var list_container: VBoxContainer = $Panel/Margin/VBox/TabContainer/Магазин/Items/VBoxContainer
@onready var upgrade_stats_container: VBoxContainer = $Panel/Margin/VBox/TabContainer/Апгрейды/UpgradeStats/VBoxContainer
@onready var close_button: Button = $Panel/Margin/VBox/CloseButton
@onready var overlay: ColorRect = $Overlay
@onready var panel: Panel = $Panel
@onready var tab_container: TabContainer = $Panel/Margin/VBox/TabContainer

var _show_tween: Tween
var _hide_tween: Tween
const SHOW_DURATION := 0.22
const HIDE_DURATION := 0.18
const SCALE_MIN := 0.95

# Константы для анимации кнопок
const BUTTON_HOVER_SCALE := 1.05
const BUTTON_PRESS_SCALE := 0.95
const BUTTON_ANIM_DURATION := 0.15
const BUTTON_DISABLED_ALPHA := 0.6
const BUTTON_ENABLED_ALPHA := 1.0

# Константы для категорий
const CATEGORY_BUTTON_HEIGHT := 40
const CATEGORY_BUTTON_MARGIN := 8

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	tab_container.tab_changed.connect(_on_tab_changed)
	
	_prepare_initial_state()
	
	_load_upgrades()
	_setup_categories()
	_render_items()
	_render_upgrade_stats()

func _on_close_pressed() -> void:
	animate_hide()

func _on_tab_changed(tab: int) -> void:
	# Обновляем содержимое при смене вкладки
	if tab == 0: # Магазин
		_render_items()
	elif tab == 1: # Апгрейды
		_render_upgrade_stats()

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
		categories = {}
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		upgrades = {}
		categories = {}
		return
	var txt := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) == OK:
		var data = json.data
		upgrades = {}
		categories = data.get("categories", {})
		
		# Загружаем только апгрейды (исключаем секцию categories)
		for key in data.keys():
			if key != "categories":
				upgrades[key] = data[key]
	else:
		push_warning("Failed to parse upgrades.json")
		upgrades = {}
		categories = {}

func _setup_categories() -> void:
	# Устанавливаем названия вкладок на основе категорий
	if categories.has("click_upgrades"):
		tab_container.set_tab_title(0, categories["click_upgrades"]["name"])
	if categories.has("auto_click_upgrades"):
		tab_container.set_tab_title(1, categories["auto_click_upgrades"]["name"])
	
	# Если нет категорий, используем стандартные названия
	if categories.is_empty():
		tab_container.set_tab_title(0, "Магазин")
		tab_container.set_tab_title(1, "Апгрейды")

func _render_items() -> void:
	for child in list_container.get_children():
		child.queue_free()
	
	# Группируем апгрейды по категориям
	var categorized_upgrades: Dictionary = {}
	for upg_id in upgrades.keys():
		var data: Dictionary = upgrades[upg_id]
		var category = data.get("category", "unknown")
		if not categorized_upgrades.has(category):
			categorized_upgrades[category] = []
		categorized_upgrades[category].append(upg_id)
	
	# Рендерим апгрейды по категориям
	for category_id in categorized_upgrades.keys():
		if categories.has(category_id):
			var category_data = categories[category_id]
			
			# Заголовок категории
			var category_header := HBoxContainer.new()
			category_header.custom_minimum_size = Vector2(0, 24)
			category_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var icon_label := Label.new()
			icon_label.text = category_data.get("icon", "📦")
			icon_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			icon_label.custom_minimum_size = Vector2(20, 0)
			category_header.add_child(icon_label)
			
			var name_label := Label.new()
			name_label.text = category_data.get("name", category_id)
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name_label.modulate = Color(1.0, 0.8, 0.0, 1.0)  # Яркий желтый цвет для заголовков
			category_header.add_child(name_label)
			
			list_container.add_child(category_header)
			
			# Разделитель
			var separator := HSeparator.new()
			separator.modulate = Color(0.6, 0.6, 0.6, 1.0)
			list_container.add_child(separator)
			
			# Апгрейды категории
			for upg_id in categorized_upgrades[category_id]:
				_render_upgrade_item(upg_id, upgrades[upg_id], category_data)

func _render_upgrade_item(upg_id: String, data: Dictionary, category_data: Dictionary) -> void:
	var h := HBoxContainer.new()
	h.custom_minimum_size = Vector2(0, 40)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Иконка категории
	var icon_label := Label.new()
	icon_label.text = category_data.get("icon", "📦")
	icon_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_label.custom_minimum_size = Vector2(20, 0)
	h.add_child(icon_label)
	
	# Информация об апгрейде
	var info_container := VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var name_label := Label.new()
	name_label.text = "%s (ур.%d)" % [String(data.get("name", upg_id)), GameManager.get_upgrade_level(upg_id)]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_contents = true
	info_container.add_child(name_label)
	
	if data.has("description"):
		var desc_label := Label.new()
		desc_label.text = String(data.get("description", ""))
		desc_label.modulate = Color(0.8, 0.8, 0.8, 1.0)
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_label.clip_contents = true
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_container.add_child(desc_label)
	
	h.add_child(info_container)
	
	# Стоимость
	var cost: int = _calc_cost(upg_id, data)
	var cost_label := Label.new()
	cost_label.text = "%d 💰" % cost
	cost_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cost_label.custom_minimum_size = Vector2(50, 0)
	h.add_child(cost_label)
	
	# Кнопка покупки
	var buy := Button.new()
	buy.text = "Купить"
	buy.disabled = GameManager.current_currency < cost or GameManager.get_upgrade_level(upg_id) >= int(data.get("max_level", 1))
	buy.pressed.connect(func(): _on_buy_pressed(upg_id))
	buy.custom_minimum_size = Vector2(60, 28)
	buy.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Настройка анимаций для кнопки покупки
	_setup_button_animations(buy)
	
	h.add_child(buy)
	list_container.add_child(h)

func _render_upgrade_stats() -> void:
	for child in upgrade_stats_container.get_children():
		child.queue_free()
	
	# Заголовок статистики
	var stats_header := Label.new()
	stats_header.text = "Статистика апгрейдов"
	stats_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_stats_container.add_child(stats_header)
	
	# Разделитель
	var separator := HSeparator.new()
	upgrade_stats_container.add_child(separator)
	
	# Общая статистика
	var total_upgrades := 0
	var total_levels := 0
	var total_spent := 0
	
	for upg_id in upgrades.keys():
		var level = GameManager.get_upgrade_level(upg_id)
		if level > 0:
			total_upgrades += 1
			total_levels += level
			# Примерный расчет потраченной валюты
			var data = upgrades[upg_id]
			var base_cost = float(data.get("base_cost", 0))
			var growth = float(data.get("growth", 1.0))
			for i in range(level):
				total_spent += int(base_cost * pow(growth, i))
	
	# Отображаем статистику
	var stats_container := VBoxContainer.new()
	stats_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var total_label := Label.new()
	total_label.text = "Всего апгрейдов: %d" % total_upgrades
	stats_container.add_child(total_label)
	
	var levels_label := Label.new()
	levels_label.text = "Общий уровень: %d" % total_levels
	stats_container.add_child(levels_label)
	
	var spent_label := Label.new()
	spent_label.text = "Потрачено валюты: %d" % total_spent
	stats_container.add_child(spent_label)
	
	upgrade_stats_container.add_child(stats_container)

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
	_render_upgrade_stats()

# Настройка анимаций для кнопки
func _setup_button_animations(button: Button) -> void:
	# Подключаем сигналы для анимаций
	button.mouse_entered.connect(func(): _on_button_mouse_entered(button))
	button.mouse_exited.connect(func(): _on_button_mouse_exited(button))
	button.button_down.connect(func(): _on_button_pressed_visual(button))
	button.button_up.connect(func(): _on_button_released_visual(button))
	
	# Устанавливаем начальное состояние
	button.modulate.a = BUTTON_ENABLED_ALPHA if not button.disabled else BUTTON_DISABLED_ALPHA

# Эффект при наведении мыши на кнопку
func _on_button_mouse_entered(button: Button) -> void:
	if button.disabled:
		return
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(BUTTON_HOVER_SCALE, BUTTON_HOVER_SCALE), BUTTON_ANIM_DURATION).set_ease(Tween.EASE_OUT)

# Убираем эффект при уходе мыши с кнопки
func _on_button_mouse_exited(button: Button) -> void:
	if button.disabled:
		return
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE, BUTTON_ANIM_DURATION).set_ease(Tween.EASE_OUT)

# Визуальный эффект при нажатии кнопки
func _on_button_pressed_visual(button: Button) -> void:
	if button.disabled:
		return
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(BUTTON_PRESS_SCALE, BUTTON_PRESS_SCALE), BUTTON_ANIM_DURATION * 0.5).set_ease(Tween.EASE_OUT)

# Визуальный эффект при отпускании кнопки
func _on_button_released_visual(button: Button) -> void:
	if button.disabled:
		return
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(BUTTON_HOVER_SCALE, BUTTON_HOVER_SCALE), BUTTON_ANIM_DURATION * 0.5).set_ease(Tween.EASE_OUT)
