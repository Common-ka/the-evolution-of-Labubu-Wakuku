extends Node

# Система отслеживания нажатых элементов

# Данные о нажатых элементах
var clicked_elements: Array[String] = []

# Активные подсветки
var active_highlights: Dictionary = {}  # element_id -> tween

func _ready() -> void:
	pass

# Отметить элемент как нажатый
func mark_as_clicked(element_id: String) -> void:
	if not clicked_elements.has(element_id):
		clicked_elements.append(element_id)
		EventBus.emit_signal("element_clicked", element_id)

# Проверить, был ли элемент нажат
func was_clicked(element_id: String) -> bool:
	return clicked_elements.has(element_id)

# Получить данные для сохранения
func get_save_data() -> Dictionary:
	return {"clicked_elements": clicked_elements}

# Загрузить данные из сохранения
func load_save_data(data: Dictionary) -> void:
	var loaded_data = data.get("clicked_elements", [])
	clicked_elements.clear()
	
	# Безопасно приводим к Array[String]
	if loaded_data is Array:
		for item in loaded_data:
			if item is String:
				clicked_elements.append(item)
	

# Подсветить элемент пульсирующим эффектом
func highlight_tab_with_pulse(tab_control: Control, element_id: String) -> void:
	if not is_instance_valid(tab_control):
		return
	
	# Если элемент уже подсвечен, не создаем новую подсветку
	if active_highlights.has(element_id):
		return
	
	# Если элемент уже был нажат, не подсвечиваем
	if was_clicked(element_id):
		return
	
	
	# Создаем пульсирующий эффект
	var tween = create_tween()
	tween.set_loops()  # Бесконечный цикл
	tween.tween_property(tab_control, "modulate", Color(0.7, 0.9, 1.0, 0.8), 0.8).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(tab_control, "modulate", Color(0.9, 0.95, 1.0, 0.6), 0.8).set_ease(Tween.EASE_IN_OUT)
	
	# Сохраняем ссылку на tween
	active_highlights[element_id] = tween

# Убрать подсветку с элемента
func remove_highlight(element_id: String) -> void:
	if not active_highlights.has(element_id):
		return
	
	
	# Останавливаем tween
	var tween = active_highlights[element_id]
	if is_instance_valid(tween):
		tween.kill()
	
	# Удаляем из словаря
	active_highlights.erase(element_id)

# Остановить подсветку конкретного элемента
func stop_highlight(element_id: String) -> void:
	remove_highlight(element_id)

# Остановить все подсветки
func stop_all_highlights() -> void:
	for element_id in active_highlights.keys():
		remove_highlight(element_id)
