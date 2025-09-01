extends Node

# Основной менеджер системы достижений
var achievements: Dictionary = {}
var progress: AchievementProgress
var unlocked_achievements: Array[String] = []

func _ready() -> void:
	progress = AchievementProgress.new()
	_load_achievements()
	_connect_signals()
	print("[AchievementManager] Система достижений инициализирована")

func _connect_signals() -> void:
	# Подключение к существующим сигналам
	EventBus.click_performed.connect(_on_click_performed)
	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.upgrade_purchased.connect(_on_upgrade_purchased)
	EventBus.level_up.connect(_on_level_up)
	EventBus.achievement_unlocked.connect(_on_achievement_unlocked)
	print("[AchievementManager] Сигналы подключены")

func _load_achievements() -> void:
	var file = FileAccess.open("res://data/achievements.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		if parse_result == OK:
			var data = json.data
			_parse_achievements(data.achievements)
			print("[AchievementManager] Загружено достижений: ", achievements.size())
		else:
			push_error("[AchievementManager] Ошибка парсинга JSON достижений")
		file.close()
	else:
		push_error("[AchievementManager] Не удалось открыть файл достижений")

func _parse_achievements(achievements_data: Dictionary) -> void:
	for category_id in achievements_data:
		var category = achievements_data[category_id]
		for tier in category.tiers:
			var achievement = Achievement.new()
			achievement.id = tier.id
			achievement.name = tier.name
			achievement.description = tier.description
			achievement.icon = category.icon
			achievement.category = category_id
			achievement.type = category.type
			achievement.target = tier.target
			achievement.reward_type = tier.reward.type
			achievement.reward_amount = tier.reward.amount
			
			achievements[tier.id] = achievement
			print("[AchievementManager] Создано достижение: ", achievement.name, " (", achievement.id, ")")

func check_achievements() -> void:
	for achievement_id in achievements:
		var achievement = achievements[achievement_id]
		if not achievement.is_unlocked:
			_check_achievement_condition(achievement)

func _check_achievement_condition(achievement: Achievement) -> void:
	match achievement.type:
		"cumulative_clicks":
			achievement.update_progress(progress.cumulative_clicks)
		"total_currency":
			achievement.update_progress(progress.total_currency)
		"upgrades_purchased":
			achievement.update_progress(progress.upgrades_purchased)
		"total_levels":
			achievement.update_progress(progress.total_levels)

# Обработка выдачи наград и фиксация анлоков
func _on_achievement_unlocked(achievement_id: String) -> void:
	# Исключаем повторную выдачу
	if unlocked_achievements.has(achievement_id):
		return

	var a: Achievement = achievements.get(achievement_id, null)
	if a == null:
		return

	# Фиксируем анлок, чтобы не дублировать награды
	unlocked_achievements.append(achievement_id)
	print("[AchievementManager] Выдача награды за достижение: ", achievement_id)

	match a.reward_type:
		"currency":
			GameManager.add_currency(int(a.reward_amount))
			print("[AchievementManager] Награда валютой: +", a.reward_amount)
		"multiplier":
			GameManager.apply_upgrade_effect("global_multiplier", float(a.reward_amount))
			print("[AchievementManager] Награда множителем: +", a.reward_amount)
		"unlock":
			# Хук для будущих разблокировок контента
			EventBus.emit_signal("game_state_changed")
			print("[AchievementManager] Награда: разблокировка контента (hook)")

	# Сигнал для UI/уведомлений
	EventBus.emit_signal("achievement_condition_met", achievement_id)

# Обработчики событий
func _on_click_performed(click_value: int) -> void:
	progress.update_clicks(progress.cumulative_clicks + 1)
	check_achievements()

func _on_currency_changed(new_amount: int) -> void:
	progress.update_currency(new_amount)
	check_achievements()

func _on_upgrade_purchased(upgrade_id: String) -> void:
	progress.update_upgrades(progress.upgrades_purchased + 1)
	check_achievements()

func _on_level_up(new_level: int) -> void:
	progress.update_levels(new_level)
	check_achievements()

# Публичные методы
func get_achievement(achievement_id: String) -> Achievement:
	return achievements.get(achievement_id, null)

func get_all_achievements() -> Array[Achievement]:
	return achievements.values()

func get_achievements_by_category(category: String) -> Array[Achievement]:
	var result: Array[Achievement] = []
	for achievement in achievements.values():
		if achievement.category == category:
			result.append(achievement)
	return result

func get_unlocked_count() -> int:
	return unlocked_achievements.size()

func get_total_count() -> int:
	return achievements.size()

# Сохранение и загрузка
func get_save_data() -> Dictionary:
	return {
		"unlocked": unlocked_achievements,
		"progress": {
			"cumulative_clicks": progress.cumulative_clicks,
			"total_currency": progress.total_currency,
			"upgrades_purchased": progress.upgrades_purchased,
			"total_levels": progress.total_levels
		}
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("unlocked"):
		unlocked_achievements = data.unlocked as Array[String]
		# Обновляем состояние достижений
		for achievement_id in unlocked_achievements:
			if achievements.has(achievement_id):
				achievements[achievement_id].is_unlocked = true
	
	if data.has("progress"):
		var progress_data = data.progress
		progress.cumulative_clicks = progress_data.get("cumulative_clicks", 0)
		progress.total_currency = progress_data.get("total_currency", 0)
		progress.upgrades_purchased = progress_data.get("upgrades_purchased", 0)
		progress.total_levels = progress_data.get("total_levels", 0)
	
	print("[AchievementManager] Данные достижений загружены")
