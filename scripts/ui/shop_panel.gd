extends Control

# Магазин апгрейдов: загружает список из JSON и позволяет покупать за основную валюту
# Теперь с поддержкой категорий и вкладок

var upgrades: Dictionary = {}
var categories: Dictionary = {}
var current_category: String = ""
var active_tab_index: int = 0  # Сохраняем активную вкладку

# Словарь для хранения ссылок на вкладки
var tabs_by_id: Dictionary = {}

# @onready var upgrade_stats_container: VBoxContainer = $Panel/Margin/VBox/TabContainer/Апгрейды/UpgradeStats/VBoxContainer
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
	
	# Подписка на сигнал изменения валюты для обновления кнопок
	EventBus.currency_changed.connect(_on_currency_changed)
	
	_prepare_initial_state()
	
	_load_upgrades()
	_setup_categories()
	_render_items()
	# _render_upgrade_stats()
	
	# Логируем информацию о вкладках
	call_deferred("_log_tabs_info")
	
	# Настраиваем подсветки для новых вкладок
	# call_deferred("_setup_highlights")  # Отключено - убираем подсветку текста

func _on_close_pressed() -> void:
	animate_hide()

func _on_tab_changed(tab: int) -> void:
	# Сохраняем активную вкладку
	active_tab_index = tab
	
	
	# Проверяем, что вкладка существует и имеет корректные мета-данные
	var current_tab = tab_container.get_current_tab_control()
	if not current_tab:
		return
	
	# Проверяем, что у вкладки есть необходимые мета-данные
	if not current_tab.has_meta("list_container") or not current_tab.has_meta("category_id"):
		return
	
	# Получаем ID категории для текущей вкладки
	var category_id = current_tab.get_meta("category_id", "")
	if not category_id.is_empty():
		# Отмечаем вкладку как нажатую
		# ClickTracker.mark_as_clicked(category_id)  # Отключено - убираем подсветку
		pass
	
	# Обновляем содержимое при смене вкладки
	# if tab == tab_container.get_tab_count() - 1: # Последняя вкладка - "Апгрейды"
	# 	print("[ShopPanel] Рендерим статистику апгрейдов")
	# 	_render_upgrade_stats()
	# else: # Вкладки категорий
	_render_items()

func _prepare_initial_state() -> void:
	overlay.visible = true
	overlay.modulate.a = 0.0
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.visible = true
	panel.scale = Vector2(SCALE_MIN, SCALE_MIN)
	panel.modulate.a = 0.0
	animate_show()

func animate_show() -> void:
	# Проверяем валидность объектов
	if not is_instance_valid(self) or not is_instance_valid(overlay) or not is_instance_valid(panel):
		return
	
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
	# Проверяем валидность объектов
	if not is_instance_valid(self) or not is_instance_valid(overlay) or not is_instance_valid(panel):
		return
	
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
	
	# Удаляем все существующие вкладки кроме "Апгрейды"
	# while tab_container.get_tab_count() > 1:
	# 	tab_container.remove_child(tab_container.get_child(1))
	
	# Удаляем все существующие вкладки
	while tab_container.get_tab_count() > 0:
		tab_container.remove_child(tab_container.get_child(0))
	
	# Порядок категорий по важности
	var category_order = ["click_upgrades", "auto_click_upgrades", "multiplier_upgrades"]
	
	# Создаем вкладки для каждой категории
	for category_id in category_order:
		if categories.has(category_id):
			_create_category_tab(category_id)
	
	
	# Устанавливаем активную вкладку
	if active_tab_index < tab_container.get_tab_count():
		tab_container.current_tab = active_tab_index
	else:
		tab_container.current_tab = 0
		active_tab_index = 0

func _create_category_tab(category_id: String) -> void:
	var category_data = categories[category_id]
	
	# Создаем контейнер для вкладки
	var tab_container_node = VBoxContainer.new()
	tab_container_node.name = category_id
	
	# Создаем ScrollContainer для прокрутки
	var scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Создаем VBoxContainer для элементов
	var vbox_container = VBoxContainer.new()
	vbox_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(vbox_container)
	
	# Добавляем в иерархию
	tab_container_node.add_child(scroll_container)
	tab_container.add_child(tab_container_node)
	
	# Устанавливаем название вкладки только с иконкой
	var tab_title = category_data.get("icon", "📦")
	tab_container.set_tab_title(tab_container.get_tab_count() - 1, tab_title)
	
	# Добавляем tooltip для объяснения категории
	var tab_index = tab_container.get_tab_count() - 1
	tab_container.set_tab_tooltip(tab_index, category_data.get("name", category_id))
	
	
	# Сохраняем ссылку на контейнер для рендеринга
	tab_container_node.set_meta("list_container", vbox_container)
	tab_container_node.set_meta("category_id", category_id)
	
	# Сохраняем ссылку на вкладку для доступа
	tabs_by_id[category_id] = tab_container_node
	
	# Проверяем, что мета-данные установлены корректно

func _render_items() -> void:
	# Получаем текущую активную вкладку
	var current_tab = tab_container.get_current_tab_control()
	if not current_tab:
		return
	
	
	# Проверяем, что это не вкладка статистики
	# if current_tab.name == "Апгрейды":
	# 	print("[ShopPanel] _render_items: пропускаем вкладку статистики")
	# 	return
	
	# Проверяем, что у вкладки есть необходимые мета-данные
	if not current_tab.has_meta("list_container") or not current_tab.has_meta("category_id"):
		return
	
	# Получаем контейнер для рендеринга
	var list_container = current_tab.get_meta("list_container", null)
	if not list_container:
		return
	
	# Очищаем контейнер
	for child in list_container.get_children():
		child.queue_free()
	
	# Получаем ID категории
	var category_id = current_tab.get_meta("category_id", "")
	if category_id.is_empty():
		return
	
	# Получаем данные категории
	var category_data = categories.get(category_id, {})
	if category_data.is_empty():
		return
	
	# Получаем апгрейды для этой категории
	var category_upgrades = _get_upgrades_by_category(category_id)
	
	# Рендерим апгрейды
	for upg_id in category_upgrades:
		var upgrade_item = _render_upgrade_item(upg_id, upgrades[upg_id], category_data)
		if is_instance_valid(upgrade_item) and is_instance_valid(list_container):
			list_container.add_child(upgrade_item)

func _get_upgrades_by_category(category_id: String) -> Array:
	var result: Array = []
	
	for upg_id in upgrades.keys():
		var data: Dictionary = upgrades[upg_id]
		var upgrade_category = data.get("category", "")
		if upgrade_category == category_id:
			result.append(upg_id)
	
	return result

func _render_upgrade_item(upg_id: String, data: Dictionary, category_data: Dictionary) -> Control:
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
	
	# Кнопка покупки (покупки бесконечны)
	var buy := Button.new()
	buy.text = "Купить"
	# Сохраняем ID апгрейда в мета-данных кнопки для обновления состояния
	buy.set_meta("upgrade_id", upg_id)
	# Единственное ограничение — хватает ли валюты
	buy.disabled = GameManager.current_currency < cost
	buy.pressed.connect(func(): _on_buy_pressed(upg_id))
	buy.custom_minimum_size = Vector2(60, 28)
	buy.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Настройка анимаций для кнопки покупки
	_setup_button_animations(buy)
	
	h.add_child(buy)
	
	# Проверяем, что кнопка все еще существует перед возвратом
	if is_instance_valid(buy):
		return h
	else:
		# Если кнопка была удалена, возвращаем пустой контейнер
		var empty_container = VBoxContainer.new()
		empty_container.custom_minimum_size = Vector2(0, 40)
		return empty_container

# func _render_upgrade_stats() -> void:
# 	for child in upgrade_stats_container.get_children():
# 		child.queue_free()
# 	
# 	# Заголовок статистики
# 	var stats_header := Label.new()
# 	stats_header.text = "Статистика апгрейдов"
# 	stats_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
# 	stats_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
# 	upgrade_stats_container.add_child(stats_header)
# 	
# 	# Разделитель
# 	var separator := HSeparator.new()
# 	upgrade_stats_container.add_child(separator)
# 	
# 	# Общая статистика
# 	var total_upgrades := 0
# 	var total_levels := 0
# 	var total_spent := 0
# 	
# 	for upg_id in upgrades.keys():
# 		var level = GameManager.get_upgrade_level(upg_id)
# 		if level > 0:
# 			total_upgrades += 1
# 			total_levels += level
# 			# Примерный расчет потраченной валюты
# 			var data = upgrades[upg_id]
# 			var base_cost = float(data.get("base_cost", 0))
# 			var growth = float(data.get("growth", 1.0))
# 			for i in range(level):
# 				total_spent += int(base_cost * pow(growth, i))
# 	
# 	# Отображаем статистику
# 	var stats_container := VBoxContainer.new()
# 	stats_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
# 	
# 	var total_label := Label.new()
# 	total_label.text = "Всего апгрейдов: %d" % total_upgrades
# 	stats_container.add_child(total_label)
# 	
# 	var levels_label := Label.new()
# 	levels_label.text = "Общий уровень: %d" % total_levels
# 	stats_container.add_child(levels_label)
# 	
# 	var spent_label := Label.new()
# 	spent_label.text = "Потрачено валюты: %d" % total_spent
# 	stats_container.add_child(spent_label)
# 	
# 	upgrade_stats_container.add_child(stats_container)

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
	# повысить уровень (без ограничений)
	GameManager.increment_upgrade_level(upg_id)
	# применить эффект
	var stat := String(data.get("stat", ""))
	var value := float(data.get("value", 0.0))
	if stat != "":
		GameManager.apply_upgrade_effect(stat, value)
	EventBus.emit_signal("upgrade_purchased", upg_id)
	_render_items()
	# _render_upgrade_stats()

# Настройка анимаций для кнопки
func _setup_button_animations(button: Button) -> void:
	# Проверяем, что кнопка существует
	if not is_instance_valid(button):
		return
	
	# Подключаем сигналы для анимаций
	button.mouse_entered.connect(func(): _on_button_mouse_entered(button))
	button.mouse_exited.connect(func(): _on_button_mouse_exited(button))
	button.button_down.connect(func(): _on_button_pressed_visual(button))
	button.button_up.connect(func(): _on_button_released_visual(button))
	
	# Устанавливаем начальное состояние
	button.modulate.a = BUTTON_ENABLED_ALPHA if not button.disabled else BUTTON_DISABLED_ALPHA

# Эффект при наведении мыши на кнопку
func _on_button_mouse_entered(button: Button) -> void:
	if button.disabled or not is_instance_valid(button):
		return
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(BUTTON_HOVER_SCALE, BUTTON_HOVER_SCALE), BUTTON_ANIM_DURATION).set_ease(Tween.EASE_OUT)

# Убираем эффект при уходе мыши с кнопки
func _on_button_mouse_exited(button: Button) -> void:
	if button.disabled or not is_instance_valid(button):
		return
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE, BUTTON_ANIM_DURATION).set_ease(Tween.EASE_OUT)

# Визуальный эффект при нажатии кнопки
func _on_button_pressed_visual(button: Button) -> void:
	if button.disabled or not is_instance_valid(button):
		return
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(BUTTON_PRESS_SCALE, BUTTON_PRESS_SCALE), BUTTON_ANIM_DURATION * 0.5).set_ease(Tween.EASE_OUT)

# Визуальный эффект при отпускании кнопки
func _on_button_released_visual(button: Button) -> void:
	if button.disabled or not is_instance_valid(button):
		return
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(BUTTON_HOVER_SCALE, BUTTON_HOVER_SCALE), BUTTON_ANIM_DURATION * 0.5).set_ease(Tween.EASE_OUT)

# Методы доступа к вкладкам
func get_tab_by_id(tab_id: String) -> Control:
	return tabs_by_id.get(tab_id, null)

func get_all_tabs() -> Array[Control]:
	return tabs_by_id.values()

func get_tab_info() -> Dictionary:
	var info = {}
	for tab_id in tabs_by_id.keys():
		var tab = tabs_by_id[tab_id]
		var icon = categories[tab_id].get("icon", "📦")
		var name = categories[tab_id].get("name", tab_id)
		info[tab_id] = {"tab": tab, "icon": icon, "name": name}
	return info

# Логирование информации о вкладках
func _log_tabs_info() -> void:
	for tab_id in tabs_by_id.keys():
		var tab = tabs_by_id[tab_id]
		var icon = categories[tab_id].get("icon", "📦")
		var name = categories[tab_id].get("name", tab_id)
	

# Настройка подсветок для новых вкладок
func _setup_highlights() -> void:
	
	# Целевые вкладки для подсветки
	var target_tabs = ["auto_click_upgrades", "multiplier_upgrades"]
	
	for tab_id in target_tabs:
		if tabs_by_id.has(tab_id):
			var tab_control = tabs_by_id[tab_id]
			if is_instance_valid(tab_control):
				ClickTracker.highlight_tab_with_pulse(tab_control, tab_id)

# Обработчик изменения валюты
func _on_currency_changed(_new_amount: int) -> void:
	# Обновляем состояние всех кнопок "Купить" на текущей вкладке
	_update_buy_buttons()

# Обновление состояния кнопок "Купить" на текущей вкладке
func _update_buy_buttons() -> void:
	# Получаем текущую активную вкладку
	var current_tab = tab_container.get_current_tab_control()
	if not current_tab:
		return
	
	# Проверяем, что у вкладки есть необходимые мета-данные
	if not current_tab.has_meta("list_container"):
		return
	
	# Получаем контейнер для рендеринга
	var list_container = current_tab.get_meta("list_container", null)
	if not list_container:
		return
	
	# Проходим по всем элементам апгрейдов и обновляем кнопки
	for item_container in list_container.get_children():
		if not is_instance_valid(item_container):
			continue
		
		# Ищем кнопку "Купить" в контейнере
		var buy_button = _find_buy_button(item_container)
		if not buy_button:
			continue
		
		# Получаем ID апгрейда из мета-данных кнопки
		var upg_id: String = buy_button.get_meta("upgrade_id", "")
		if upg_id.is_empty():
			continue
		
		# Получаем данные апгрейда
		var data: Dictionary = upgrades.get(upg_id, {})
		if data.is_empty():
			continue
		
		# Пересчитываем стоимость
		var cost: int = _calc_cost(upg_id, data)
		
		# Обновляем состояние кнопки
		var was_disabled: bool = buy_button.disabled
		buy_button.disabled = GameManager.current_currency < cost
		
		# Обновляем визуальное состояние (прозрачность) если изменилось
		if was_disabled != buy_button.disabled:
			buy_button.modulate.a = BUTTON_ENABLED_ALPHA if not buy_button.disabled else BUTTON_DISABLED_ALPHA

# Поиск кнопки "Купить" в контейнере элемента апгрейда
func _find_buy_button(item_container: Control) -> Button:
	# Ищем кнопку среди дочерних элементов (кнопка - прямой дочерний элемент HBoxContainer)
	for child in item_container.get_children():
		if child is Button and child.text == "Купить":
			return child
	
	return null

# Очистка при уничтожении
func _exit_tree() -> void:
	# Сигналы автоматически отключаются при уничтожении узла, но явное отключение не помешает
	if EventBus.currency_changed.is_connected(_on_currency_changed):
		EventBus.currency_changed.disconnect(_on_currency_changed)
	
	# Останавливаем все активные Tween анимации
	if _show_tween:
		_show_tween.kill()
	if _hide_tween:
		_hide_tween.kill()
	
	# Останавливаем все подсветки
	# ClickTracker.stop_all_highlights()  # Отключено - убираем подсветку
