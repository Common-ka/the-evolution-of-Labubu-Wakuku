extends Node

# Автозагружаемый скрипт для управления эффектами частиц
# Использует пул объектов (object pooling) для оптимизации производительности

var available_effects: Array = []
var active_effects: Array = []
var effect_scene: PackedScene

# Настройки пула (оптимизированы для производительности)
const INITIAL_POOL_SIZE := 6
const MAX_POOL_SIZE := 12
const MAX_ACTIVE_EFFECTS := 8  # Ограничение одновременных эффектов

func _ready() -> void:
	# Предзагружаем сцену эффектов
	effect_scene = preload("res://scenes/entities/particle_effects.tscn")
	
	if not effect_scene:
		push_error("ParticleManager: Не удалось загрузить particle_effects.tscn")
		return
	
	_prepopulate_pool()

# Создание эффекта клика (с ограничением производительности)
func create_click_effect(position: Vector2) -> void:
	# Проверяем лимит активных эффектов
	if active_effects.size() >= MAX_ACTIVE_EFFECTS:
		# Если лимит достигнут, заменяем самый старый эффект
		_replace_oldest_effect(position)
		return
	
	var effect = _get_effect_from_pool()
	if not effect:
		return
	
	# Добавляем эффект в текущую сцену
	var current_scene = get_tree().current_scene
	if not current_scene:
		return
	
	# Пытаемся добавить в UI слой, иначе в корень сцены
	var ui_node = current_scene.get_node_or_null("UI")
	var parent_node = ui_node if ui_node else current_scene
	parent_node.add_child(effect)
	
	# Ожидаем один кадр для завершения _ready()
	await get_tree().process_frame
	
	# Настраиваем эффект
	effect.global_position = position
	effect.setup_effect()
	
	# Добавляем в активные
	active_effects.append(effect)

# Замена самого старого эффекта для поддержания производительности
func _replace_oldest_effect(new_position: Vector2) -> void:
	if active_effects.is_empty():
		return
	
	# Находим самый старый эффект (первый в массиве)
	var oldest_effect = active_effects[0]
	
	# Убираем его из активных
	active_effects.remove_at(0)
	
	# Возвращаем в пул
	return_effect_to_pool(oldest_effect)
	
	# Создаем новый эффект на том же месте
	create_click_effect(new_position)

# Получить эффект из пула
func _get_effect_from_pool() -> Node2D:
	var effect: Node2D
	
	if available_effects.is_empty():
		# Создаем новый объект если пул пуст
		effect = effect_scene.instantiate()
		effect.effect_finished.connect(_on_effect_finished)
	else:
		# Берем объект из пула
		effect = available_effects.pop_back()
	
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
	else:
		effect.queue_free()

# Предварительное заполнение пула
func _prepopulate_pool() -> void:
	for i in INITIAL_POOL_SIZE:
		var effect = effect_scene.instantiate()
		effect.effect_finished.connect(_on_effect_finished)
		available_effects.append(effect)

# Получить статистику пула
func get_pool_stats() -> Dictionary:
	return {
		"available": available_effects.size(),
		"active": active_effects.size(),
		"total": available_effects.size() + active_effects.size(),
		"max_pool_size": MAX_POOL_SIZE,
		"max_active_effects": MAX_ACTIVE_EFFECTS,
		"performance_status": "optimal" if active_effects.size() < MAX_ACTIVE_EFFECTS else "at_limit"
	}

# Очистка всех активных эффектов (для перезагрузки сцены)
func clear_all_effects() -> void:
	for effect in active_effects:
		if effect.get_parent():
			effect.get_parent().remove_child(effect)
		effect.queue_free()
	
	active_effects.clear()

# Принудительная очистка для освобождения памяти
func force_cleanup() -> void:
	clear_all_effects()
	
	# Очищаем пул
	for effect in available_effects:
		effect.queue_free()
	available_effects.clear()
	
	# Пересоздаем базовый пул
	_prepopulate_pool()
