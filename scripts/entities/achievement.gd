class_name Achievement
extends Resource

# Основные данные достижения
@export var id: String
@export var name: String
@export var description: String
@export var icon: String
@export var category: String
@export var type: String
@export var target: int
@export var reward_type: String
@export var reward_amount: int

# Состояние достижения
var is_unlocked: bool = false
var progress: int = 0
var progress_percentage: float = 0.0

# Методы
func update_progress(new_progress: int) -> bool:
	progress = new_progress
	progress_percentage = float(progress) / float(target)
	
	if progress >= target and not is_unlocked:
		unlock()
		return true
	return false

func unlock() -> void:
	is_unlocked = true
	EventBus.emit_signal("achievement_unlocked", id)
	print("[Achievement] Разблокировано достижение: ", name, " (", id, ")")

func get_description_with_target() -> String:
	return description.replace("{target}", str(target))

func get_progress_text() -> String:
	return "%d/%d" % [progress, target]

func is_completed() -> bool:
	return progress >= target
