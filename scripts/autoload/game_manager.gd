extends Node

# Основной менеджер игровой логики и состояния

# Игровое состояние
var current_currency: int = 0
var current_level: int = 1
var current_experience: int = 0
var experience_to_next_level: int = 100

# Множители и бонусы
var click_multiplier: float = 1.0
var auto_click_rate: float = 0.0
var global_multiplier: float = 1.0
var auto_click_timer: Timer

# Статистика
var total_clicks: int = 0
var total_currency_earned: int = 0
var game_start_time: int = 0

# Покупки апгрейдов: хранит уровень каждого апгрейда по его id
var purchased_upgrades: Dictionary = {}

func _ready() -> void:
	# Инициализация таймера для авто-кликов
	auto_click_timer = Timer.new()
	auto_click_timer.wait_time = 1.0
	auto_click_timer.timeout.connect(_on_auto_click_timer_timeout)
	add_child(auto_click_timer)
	
	# Подключение сигналов
	EventBus.click_performed.connect(_on_click_performed)
	EventBus.upgrade_purchased.connect(_on_upgrade_purchased)
	EventBus.particle_effect_requested.connect(_on_particle_effect_requested)
	
	# Запуск авто-кликов если есть
	if auto_click_rate > 0:
		auto_click_timer.start()

# Обработка клика игрока
func perform_click() -> void:
	var click_value: int = get_click_value()

	current_currency += click_value
	total_clicks += 1
	total_currency_earned += click_value
	
	# Проверка опыта и уровня
	add_experience(1)
	
	# Эмиссия сигналов
	EventBus.emit_signal("click_performed", click_value)
	EventBus.emit_signal("currency_changed", current_currency)
	EventBus.emit_signal("game_state_changed")

# Получение значения клика
func get_click_value() -> int:
	var base_value = 5.0 * click_multiplier
	var final_value = base_value * global_multiplier
	return int(ceil(final_value))

# Добавление валюты
func add_currency(amount: int) -> void:
	current_currency += amount
	total_currency_earned += amount
	EventBus.emit_signal("currency_changed", current_currency)

# Трата валюты
func spend_currency(amount: int) -> bool:
	if current_currency >= amount:
		current_currency -= amount
		EventBus.emit_signal("currency_changed", current_currency)
		return true
	return false

# Добавление опыта
func add_experience(amount: int) -> void:
	current_experience += amount
	
	# Проверка повышения уровня
	while current_experience >= experience_to_next_level:
		level_up()

# Повышение уровня
func level_up() -> void:
	current_experience -= experience_to_next_level
	current_level += 1
	experience_to_next_level = calculate_next_level_exp()
	
	EventBus.emit_signal("level_up", current_level)
	EventBus.emit_signal("game_state_changed")

# Расчет опыта для следующего уровня
func calculate_next_level_exp() -> int:
	return int(100 * pow(1.2, current_level - 1))

# Применение эффекта апгрейда по статистике
func apply_upgrade_effect(stat: String, effect_value: float) -> void:
	match stat:
		"click_multiplier":
			var before := click_multiplier
			click_multiplier += effect_value
			print("[GameManager] click_multiplier: %f -> %f (+%f)" % [before, click_multiplier, effect_value])

		"auto_click_rate":
			var before := auto_click_rate
			auto_click_rate += effect_value
			print("[GameManager] auto_click_rate: %f -> %f (+%f)" % [before, auto_click_rate, effect_value])
			if auto_click_rate > 0 and not auto_click_timer.is_stopped():
				auto_click_timer.start()

		"global_multiplier":
			var before := global_multiplier
			global_multiplier += effect_value
			print("[GameManager] global_multiplier: %f -> %f (+%f)" % [before, global_multiplier, effect_value])
	
	EventBus.emit_signal("upgrade_effect_applied", stat, effect_value)

# Получение данных для сохранения
func get_save_data() -> Dictionary:
	return {
		"current_currency": current_currency,
		"current_level": current_level,
		"current_experience": current_experience,
		"experience_to_next_level": experience_to_next_level,
		"click_multiplier": click_multiplier,
		"auto_click_rate": auto_click_rate,
		"global_multiplier": global_multiplier,
		"total_clicks": total_clicks,
		"total_currency_earned": total_currency_earned,
		"game_start_time": game_start_time,
		"purchased_upgrades": purchased_upgrades
	}

# Загрузка данных
func load_save_data(data: Dictionary) -> void:
	current_currency = data.get("current_currency", 0)
	current_level = data.get("current_level", 1)
	current_experience = data.get("current_experience", 0)
	experience_to_next_level = data.get("experience_to_next_level", 100)
	click_multiplier = data.get("click_multiplier", 1.0)
	auto_click_rate = data.get("auto_click_rate", 0.0)
	global_multiplier = data.get("global_multiplier", 1.0)
	total_clicks = data.get("total_clicks", 0)
	total_currency_earned = data.get("total_currency_earned", 0)
	game_start_time = data.get("game_start_time", 0)
	
	# Апгрейды
	purchased_upgrades = data.get("purchased_upgrades", {})
	
	# Применяем эффекты апгрейдов повторно для консистентности
	# Сбрасываем базовые множители перед применением
	click_multiplier = 1.0
	auto_click_rate = 0.0
	global_multiplier = 1.0
	
	# Применяем все купленные апгрейды
	for upg_id in purchased_upgrades.keys():
		var level: int = int(purchased_upgrades[upg_id])
		if level <= 0:
			continue
			
		# Получаем данные апгрейда из JSON
		var upgrade_data = _get_upgrade_data(upg_id)
		if upgrade_data.is_empty():
			continue
			
		var stat = upgrade_data.get("stat", "")
		var value = float(upgrade_data.get("value", 0.0))
		var stack = upgrade_data.get("stack", "add")
		
		if stat != "" and value > 0:
			# Применяем эффект level раз
			for i in level:
				apply_upgrade_effect(stat, value)
	
	# Обновление авто-кликов
	if auto_click_rate > 0:
		auto_click_timer.start()
	
	# Эмиссия сигналов обновления
	EventBus.emit_signal("currency_changed", current_currency)
	EventBus.emit_signal("level_up", current_level)
	EventBus.emit_signal("game_state_changed")

# Получить уровень апгрейда
func get_upgrade_level(upgrade_id: String) -> int:
	return int(purchased_upgrades.get(upgrade_id, 0))

# Увеличить уровень апгрейда (без списания валюты)
func increment_upgrade_level(upgrade_id: String) -> void:
	var level: int = get_upgrade_level(upgrade_id) + 1
	purchased_upgrades[upgrade_id] = level

# Сброс игры
func reset_game() -> void:
	current_currency = 0
	current_level = 1
	current_experience = 0
	experience_to_next_level = 100
	click_multiplier = 1.0
	auto_click_rate = 0.0
	global_multiplier = 1.0
	total_clicks = 0
	total_currency_earned = 0
	game_start_time = Time.get_unix_time_from_system()
	# Сброс купленных апгрейдов
	purchased_upgrades = {}
	
	auto_click_timer.stop()
	
	EventBus.emit_signal("currency_changed", current_currency)
	EventBus.emit_signal("level_up", current_level)
	EventBus.emit_signal("game_state_changed")

# Сигналы
func _on_click_performed(amount: int) -> void:
	# Создаем Floating Text для показа получаемой валюты
	_create_floating_text(amount)

# Создание Floating Text
func _create_floating_text(click_value: int) -> void:
	# Получаем позицию кликабельного объекта
	var game_scene = get_tree().current_scene
	if not game_scene:
		print("[GameManager] Не удалось найти текущую сцену")
		return
	
	var clickable_object = game_scene.get_node_or_null("GameArea/ClickableObject")
	if not clickable_object:
		print("[GameManager] Не удалось найти ClickableObject")
		return
	
	# Получаем мировую позицию объекта
	var world_position = clickable_object.global_position
	
	# Создаем Floating Text из пула
	var floating_text = FloatingTextPool.get_floating_text()
	
	# Добавляем в UI сцены
	var ui_node = game_scene.get_node_or_null("UI")
	if ui_node:
		ui_node.add_child(floating_text)
		floating_text.show_value(click_value, world_position)
		print("[GameManager] Создан Floating Text для значения: ", click_value)
	else:
		print("[GameManager] Не удалось найти UI узел")
		# Возвращаем объект в пул если не удалось добавить
		FloatingTextPool.return_text_to_pool(floating_text)

func _on_upgrade_purchased(upgrade_id: String) -> void:
	# Обработка покупки апгрейда (будет расширена)
	pass

# Обработчик запроса эффекта частиц
func _on_particle_effect_requested(effect_type: String, position: Vector2) -> void:
	print("[GameManager] Запрошен эффект частиц: ", effect_type, " в позиции: ", position)
	# Здесь можно добавить дополнительную логику для разных типов эффектов

func _on_auto_click_timer_timeout() -> void:
	if auto_click_rate > 0:
		add_currency(int(auto_click_rate))

# Получить данные апгрейда из JSON файла
func _get_upgrade_data(upgrade_id: String) -> Dictionary:
	var path := "res://data/upgrades.json"
	if not FileAccess.file_exists(path):
		return {}
		
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return {}
		
	var txt := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) == OK:
		var data = json.data
		return data.get(upgrade_id, {})
	
	return {}
