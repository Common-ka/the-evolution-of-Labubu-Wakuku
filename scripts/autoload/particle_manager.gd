extends Node

# Автозагружаемый скрипт для управления эффектами частиц
# Использует object pooling для оптимизации производительности

var available_effects: Array = []
var active_effects: Array = []
var effect_scenes: Dictionary = {}

# Настройки пула
const INITIAL_POOL_SIZE := 15
const MAX_POOL_SIZE := 40

# Конфигурация эффектов
const EFFECT_CONFIGS := {
	"click_stars": {
		"particle_count": 4,
		"lifetime": 0.8,
		"velocity_min": 60,
		"velocity_max": 120,
		"scale_min": 0.4,
		"scale_max": 0.7,
		"colors": ["#FFD700", "#FFA500", "#FFFF00", "#FF6B35"]
	}
}

func _ready() -> void:
	# Предзагружаем сцены эффектов
	effect_scenes["click_stars"] = preload("res://scenes/entities/particle_effects.tscn")
	_prepopulate_pool()
	print("[ParticleManager] Пул инициализирован с ", INITIAL_POOL_SIZE, " объектами")

# Создание эффекта клика
func create_click_effect(position: Vector2) -> void:
	var effect = _get_effect_from_pool()
	if not effect:
		print("[ParticleManager] Не удалось получить эффект из пула")
		return
	
	print("[ParticleManager] Получен эффект из пула: ", effect.name, " класса: ", effect.get_class())
	
	# Проверяем, что эффект имеет нужные методы
	if not effect.has_method("setup_effect"):
		print("[ParticleManager] ОШИБКА: Эффект не имеет метода setup_effect")
		return
	
	# Настраиваем эффект
	effect.global_position = position
	effect.setup_effect("click_stars")
	
	# Добавляем в активные
	active_effects.append(effect)
	
	print("[ParticleManager] Создан эффект клика в позиции: ", position)

# Получить эффект из пула
func _get_effect_from_pool() -> Node2D:
	var effect: Node2D
	
	if available_effects.is_empty():
		# Создаем новый объект если пул пуст
		effect = effect_scenes["click_stars"].instantiate()
		effect.effect_finished.connect(_on_effect_finished)
		print("[ParticleManager] Создан новый эффект")
	else:
		# Берем объект из пула
		effect = available_effects.pop_back()
		print("[ParticleManager] Взят эффект из пула. Осталось: ", available_effects.size())
	
	return effect

# Обработчик завершения эффекта
func _on_effect_finished(effect: Node2D) -> void:
	return_effect_to_pool(effect)

# Возврат эффекта в пул
func return_effect_to_pool(effect: Node2D) -> void:
	# Убираем из активных
	active_effects.erase(effect)
	
	# Удаляем эффект из сцены перед возвратом в пул
	if effect.get_parent():
		effect.get_parent().remove_child(effect)
	
	# Возвращаем в пул или удаляем
	if available_effects.size() < MAX_POOL_SIZE:
		available_effects.append(effect)
		print("[ParticleManager] Эффект возвращен в пул. Размер пула: ", available_effects.size())
	else:
		effect.queue_free()
		print("[ParticleManager] Эффект удален (пул переполнен)")

# Предварительное заполнение пула
func _prepopulate_pool() -> void:
	for i in INITIAL_POOL_SIZE:
		var effect = effect_scenes["click_stars"].instantiate()
		effect.effect_finished.connect(_on_effect_finished)
		available_effects.append(effect)

# Получить статистику пула
func get_pool_stats() -> Dictionary:
	return {
		"available": available_effects.size(),
		"active": active_effects.size(),
		"total": available_effects.size() + active_effects.size(),
		"max_size": MAX_POOL_SIZE
	}

# Очистка всех активных эффектов (для перезагрузки сцены)
func clear_all_effects() -> void:
	for effect in active_effects:
		if effect.get_parent():
			effect.get_parent().remove_child(effect)
		effect.queue_free()
	
	active_effects.clear()
	print("[ParticleManager] Все активные эффекты очищены")
