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
	
	# Отладочная информация
	print("[GameManager] _ready: click_multiplier = ", click_multiplier)
	
	# Запуск авто-кликов если есть
	if auto_click_rate > 0:
		auto_click_timer.start()

# Обработка клика игрока
func perform_click() -> void:
	var click_value: int = get_click_value()
	print("[GameManager] perform_click: click_multiplier=", click_multiplier, ", click_value=", click_value)
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
	return int(ceil(5.0 * click_multiplier))

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
			print("[GameManager] apply_upgrade_effect: ", stat, " +", effect_value, " => ", before, " -> ", click_multiplier)
		"auto_click_rate":
			auto_click_rate += effect_value
			if auto_click_rate > 0 and not auto_click_timer.is_stopped():
				auto_click_timer.start()
	
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
	total_clicks = data.get("total_clicks", 0)
	total_currency_earned = data.get("total_currency_earned", 0)
	game_start_time = data.get("game_start_time", 0)
	
	# Апгрейды
	purchased_upgrades = data.get("purchased_upgrades", {})
	# Применяем эффекты апгрейдов повторно для консистентности
	# Сбрасываем базовые множители перед применением
	click_multiplier = 1.0  # Сбрасываем к базовому значению
	for upg_id in purchased_upgrades.keys():
		var level: int = int(purchased_upgrades[upg_id])
		# Применяем эффект level раз для каждого апгрейда
		if upg_id == "upg_click_1":
			for i in level:
				apply_upgrade_effect("click_multiplier", 0.2)
		elif upg_id == "upg_click_2":
			for i in level:
				apply_upgrade_effect("click_multiplier", 0.5)
	
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
	total_clicks = 0
	total_currency_earned = 0
	game_start_time = Time.get_unix_time_from_system()
	# Сброс купленных апгрейдов
	purchased_upgrades = {}
	
	print("[GameManager] reset_game: click_multiplier reset to ", click_multiplier)
	
	auto_click_timer.stop()
	
	EventBus.emit_signal("currency_changed", current_currency)
	EventBus.emit_signal("level_up", current_level)
	EventBus.emit_signal("game_state_changed")

# Сигналы
func _on_click_performed(amount: int) -> void:
	# Обработка клика (может быть расширена)
	pass

func _on_upgrade_purchased(upgrade_id: String) -> void:
	# Обработка покупки апгрейда (будет расширена)
	pass

func _on_auto_click_timer_timeout() -> void:
	if auto_click_rate > 0:
		add_currency(int(auto_click_rate))
