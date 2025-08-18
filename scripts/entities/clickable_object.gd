extends Area2D

# Скрипт для обработки кликов на кликабельный объект

# Ссылки на узлы
@onready var triangle: Polygon2D = $Triangle

# Анимация клика
var click_tween: Tween

func _ready() -> void:
	# Подключение сигналов
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

# Обработка клика
func _on_input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	print("ClickableObject: Получено событие ввода - ", event.get_class())
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("ClickableObject: Обработка клика мыши")
		perform_click()
	elif event is InputEventScreenTouch and event.pressed:
		print("ClickableObject: Обработка тач-нажатия")
		perform_click()

# Обработка входа мыши
func _on_mouse_entered() -> void:
	# Визуальная обратная связь при наведении
	create_hover_effect()

# Обработка выхода мыши
func _on_mouse_exited() -> void:
	# Убираем эффект наведения
	remove_hover_effect()

# Выполнение клика
func perform_click() -> void:
	print("ClickableObject: perform_click() вызван")
	
	# Вызываем GameManager для обработки клика
	GameManager.perform_click()
	
	# Создаем визуальный эффект клика
	create_click_effect()
	
	# Создаем анимацию масштабирования
	create_scale_animation()

# Создание эффекта клика
func create_click_effect() -> void:
	# Здесь можно добавить частицы или другие эффекты
	# Пока просто меняем цвет на короткое время
	var original_color = triangle.color
	triangle.color = Color.WHITE
	
	# Возвращаем исходный цвет через 0.1 секунды
	await get_tree().create_timer(0.1).timeout
	triangle.color = original_color

# Создание анимации масштабирования
func create_scale_animation() -> void:
	# Останавливаем предыдущую анимацию если она есть
	if click_tween:
		click_tween.kill()
	
	click_tween = create_tween()
	click_tween.set_parallel(true)
	
	# Увеличиваем масштаб
	click_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	# Возвращаем к нормальному размеру
	click_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.1)

# Создание эффекта наведения
func create_hover_effect() -> void:
	# Легкое увеличение масштаба при наведении
	var hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)

# Убираем эффект наведения
func remove_hover_effect() -> void:
	# Возвращаем к нормальному размеру
	var hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
