class_name AchievementProgress
extends Resource

# Отслеживание прогресса по типам достижений
var cumulative_clicks: int = 0
var total_currency: int = 0
var upgrades_purchased: int = 0
var total_levels: int = 0

# Методы обновления прогресса
func update_clicks(click_count: int) -> void:
	cumulative_clicks = click_count
	EventBus.emit_signal("achievement_progress_updated", "cumulative_clicks", cumulative_clicks)

func update_currency(currency_amount: int) -> void:
	total_currency = currency_amount
	EventBus.emit_signal("achievement_progress_updated", "total_currency", total_currency)

func update_upgrades(upgrade_count: int) -> void:
	upgrades_purchased = upgrade_count
	EventBus.emit_signal("achievement_progress_updated", "upgrades_purchased", upgrade_count)

func update_levels(level_count: int) -> void:
	total_levels = level_count
	EventBus.emit_signal("achievement_progress_updated", "total_levels", level_count)

# Получение прогресса по типу
func get_progress_by_type(progress_type: String) -> int:
	match progress_type:
		"cumulative_clicks":
			return cumulative_clicks
		"total_currency":
			return total_currency
		"upgrades_purchased":
			return upgrades_purchased
		"total_levels":
			return total_levels
		_:
			return 0

# Сброс прогресса (для тестирования)
func reset_progress() -> void:
	cumulative_clicks = 0
	total_currency = 0
	upgrades_purchased = 0
	total_levels = 0
