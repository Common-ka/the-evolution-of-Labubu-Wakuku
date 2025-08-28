extends Control

# Магазин апгрейдов: загружает список из JSON и позволяет покупать за основную валюту
# Теперь с поддержкой категорий и вкладок

var upgrades: Dictionary = {}
var categories: Dictionary = {}
var current_category: String = ""
var active_tab_index: int = 0  # Сохраняем активную вкладку

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
	
	_prepare_initial_state()
	
	_load_upgrades()
	_setup_categories()
	_render_items()
	# _render_upgrade_stats()

func _on_close_pressed() -> void:
	animate_hide()

func _on_tab_changed(tab: int) -> void:
	# Сохраняем активную вкладку
	active_tab_index = tab
	
	print("[ShopPanel] Переключение на вкладку: ", tab, " из ", tab_container.get_tab_count())
	
	# Проверяем, что вкладка существует и имеет корректные мета-данные
	var current_tab = tab_container.get_current_tab_control()
	if not current_tab:
		print("[ShopPanel] _on_tab_changed: нет активной вкладки")
		return
	
	# Проверяем, что у вкладки есть необходимые мета-данные
	if not current_tab.has_meta("list_container") or not current_tab.has_meta("category_id"):
		print("[ShopPanel] _on_tab_changed: у вкладки отсутствуют необходимые мета-данные: ", current_tab.name)
		return
	
	# Обновляем содержимое при смене вкладки
	# if tab == tab_container.get_tab_count() - 1: # Последняя вкладка - "Апгрейды"
	# 	print("[ShopPanel] Рендерим статистику апгрейдов")
	# 	_render_upgrade_stats()
	# else: # Вкладки категорий
	print("[ShopPanel] Рендерим апгрейды для категории")
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
		
		print("[ShopPanel] Загружены категории: ", categories.keys())
		print("[ShopPanel] Загружены апгрейды: ", upgrades.keys())
		
		# Загружаем только апгрейды (исключаем секцию categories)
		for key in data.keys():
			if key != "categories":
				upgrades[key] = data[key]
		
		print("[ShopPanel] После фильтрации апгрейды: ", upgrades.keys())
	else:
		push_warning("Failed to parse upgrades.json")
		upgrades = {}
		categories = {}

func _setup_categories() -> void:
	print("[ShopPanel] Настройка категорий...")
	print("[ShopPanel] Доступные категории: ", categories.keys())
	
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
		print("[ShopPanel] Проверяем категорию: ", category_id)
		if categories.has(category_id):
			print("[ShopPanel] Создаем вкладку для: ", category_id)
			_create_category_tab(category_id)
		else:
			print("[ShopPanel] Категория не найдена: ", category_id)
	
	print("[ShopPanel] Всего вкладок создано: ", tab_container.get_tab_count())
	
	# Устанавливаем активную вкладку
	if active_tab_index < tab_container.get_tab_count():
		tab_container.current_tab = active_tab_index
	else:
		tab_container.current_tab = 0
		active_tab_index = 0

func _create_category_tab(category_id: String) -> void:
	var category_data = categories[category_id]
	print("[ShopPanel] Создание вкладки для категории: ", category_id)
	print("[ShopPanel] Данные категории: ", category_data)
	
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
	
	print("[ShopPanel] Создана вкладка: ", tab_title, " для категории: ", category_data.get("name", category_id))
	
	# Сохраняем ссылку на контейнер для рендеринга
	tab_container_node.set_meta("list_container", vbox_container)
	tab_container_node.set_meta("category_id", category_id)
	
	# Проверяем, что мета-данные установлены корректно
	print("[ShopPanel] Проверка мета-данных для вкладки: ", category_id)
	print("[ShopPanel] list_container установлен: ", tab_container_node.has_meta("list_container"))
	print("[ShopPanel] category_id установлен: ", tab_container_node.has_meta("category_id"))

func _render_items() -> void:
	# Получаем текущую активную вкладку
	var current_tab = tab_container.get_current_tab_control()
	if not current_tab:
		print("[ShopPanel] _render_items: нет активной вкладки")
		return
	
	print("[ShopPanel] _render_items: активная вкладка: ", current_tab.name)
	print("[ShopPanel] _render_items: класс вкладки: ", current_tab.get_class())
	
	# Проверяем, что это не вкладка статистики
	# if current_tab.name == "Апгрейды":
	# 	print("[ShopPanel] _render_items: пропускаем вкладку статистики")
	# 	return
	
	# Проверяем, что у вкладки есть необходимые мета-данные
	if not current_tab.has_meta("list_container") or not current_tab.has_meta("category_id"):
		print("[ShopPanel] _render_items: у вкладки отсутствуют необходимые мета-данные: ", current_tab.name)
		print("[ShopPanel] _render_items: list_container: ", current_tab.has_meta("list_container"))
		print("[ShopPanel] _render_items: category_id: ", current_tab.has_meta("category_id"))
		print("[ShopPanel] _render_items: все мета-ключи: ", current_tab.get_meta_list())
		return
	
	# Получаем контейнер для рендеринга
	var list_container = current_tab.get_meta("list_container", null)
	if not list_container:
		print("[ShopPanel] _render_items: нет list_container для вкладки: ", current_tab.name)
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
	print("[ShopPanel] Найдено апгрейдов для категории ", category_id, ": ", category_upgrades.size())
	
	# Рендерим апгрейды
	for upg_id in category_upgrades:
		print("[ShopPanel] Рендерим апгрейд: ", upg_id)
		var upgrade_item = _render_upgrade_item(upg_id, upgrades[upg_id], category_data)
		list_container.add_child(upgrade_item)

func _get_upgrades_by_category(category_id: String) -> Array:
	var result: Array = []
	print("[ShopPanel] Поиск апгрейдов для категории: ", category_id)
	print("[ShopPanel] Всего апгрейдов в словаре: ", upgrades.size())
	
	for upg_id in upgrades.keys():
		var data: Dictionary = upgrades[upg_id]
		var upgrade_category = data.get("category", "")
		print("[ShopPanel] Апгрейд ", upg_id, " имеет категорию: ", upgrade_category)
		if upgrade_category == category_id:
			result.append(upg_id)
			print("[ShopPanel] Добавлен апгрейд: ", upg_id)
	
	print("[ShopPanel] Итого найдено для категории ", category_id, ": ", result.size())
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
	
	return h

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
	# _render_upgrade_stats()

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
