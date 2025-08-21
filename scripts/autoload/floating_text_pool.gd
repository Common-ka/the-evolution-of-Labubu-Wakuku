extends Node

# Автозагружаемый скрипт для управления пулом Floating Text объектов
# Использует пул объектов (object pooling) для оптимизации производительности

var available_texts: Array = []
var active_texts: Array = []
var floating_text_scene: PackedScene

# Настройки пула
const INITIAL_POOL_SIZE := 10
const MAX_POOL_SIZE := 30

func _ready() -> void:
	# Предзагружаем сцену Floating Text
	floating_text_scene = preload("res://scenes/ui/floating_text.tscn")
	_prepopulate_pool()
	print("[FloatingTextPool] Пул инициализирован с ", INITIAL_POOL_SIZE, " объектами")

# Получить Floating Text из пула
func get_floating_text() -> Control:
	var text: Control
	
	if available_texts.is_empty():
		# Создаем новый объект если пул пуст
		text = floating_text_scene.instantiate()
		text.animation_finished.connect(_on_text_animation_finished)
		print("[FloatingTextPool] Создан новый Floating Text")
	else:
		# Берем объект из пула
		text = available_texts.pop_back()
		print("[FloatingTextPool] Взят Floating Text из пула. Осталось: ", available_texts.size())
	
	# Добавляем в активные
	active_texts.append(text)
	return text

# Обработчик завершения анимации
func _on_text_animation_finished(text: Control) -> void:
	return_text_to_pool(text)

# Публичный метод для возврата текста в пул
func return_text_to_pool(text: Control) -> void:
	# Убираем из активных
	active_texts.erase(text)
	
	# Удаляем текст из сцены перед возвратом в пул
	if text.get_parent():
		text.get_parent().remove_child(text)
	
	# Возвращаем в пул или удаляем
	if available_texts.size() < MAX_POOL_SIZE:
		available_texts.append(text)
		print("[FloatingTextPool] Floating Text возвращен в пул. Размер пула: ", available_texts.size())
	else:
		text.queue_free()
		print("[FloatingTextPool] Floating Text удален (пул переполнен)")

# Предварительное заполнение пула
func _prepopulate_pool() -> void:
	for i in INITIAL_POOL_SIZE:
		var text = floating_text_scene.instantiate()
		text.animation_finished.connect(_on_text_animation_finished)
		available_texts.append(text)

# Получить статистику пула
func get_pool_stats() -> Dictionary:
	return {
		"available": available_texts.size(),
		"active": active_texts.size(),
		"total": available_texts.size() + active_texts.size(),
		"max_size": MAX_POOL_SIZE
	}
