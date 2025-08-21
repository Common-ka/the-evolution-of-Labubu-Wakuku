extends Area2D

# Скрипт для обработки кликов на кликабельный объект

# Константы анимации для легкой настройки
const CLICK_SCALE_MAX := 1.3
const CLICK_SCALE_MIN := 0.95
const CLICK_ROTATION_MAX := 0.1
const CLICK_ROTATION_MIN := -0.05
const CLICK_PHASE1_TIME := 0.08
const CLICK_PHASE2_TIME := 0.12
const CLICK_PHASE3_TIME := 0.1
const HOVER_SCALE := 1.05
const HOVER_TIME := 0.15

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
func _on_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		perform_click()
	elif event is InputEventScreenTouch and event.pressed:
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
	
	# Создаем эффект частиц
	create_particle_effect()
	
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

# Создание эффекта частиц
func create_particle_effect() -> void:
	# Создаем эффект частиц через ParticleManager
	ParticleManager.create_click_effect(global_position)
	
	# Эмитируем сигнал для других систем
	EventBus.emit_signal("particle_effect_requested", "click_stars", global_position)

# Создание улучшенной анимации масштабирования и ротации
func create_scale_animation() -> void:
	# Останавливаем предыдущую анимацию если она есть
	if click_tween:
		click_tween.kill()
	
	click_tween = create_tween()
	click_tween.set_parallel(true)
	
	# Фаза 1: Быстрое увеличение с ротацией
	click_tween.tween_property(self, "scale", Vector2(CLICK_SCALE_MAX, CLICK_SCALE_MAX), CLICK_PHASE1_TIME).set_ease(Tween.EASE_OUT)
	click_tween.tween_property(self, "rotation", CLICK_ROTATION_MAX, CLICK_PHASE1_TIME).set_ease(Tween.EASE_OUT)
	
	# Фаза 2: Сжатие с обратной ротацией (эффект "отскока")
	click_tween.tween_property(self, "scale", Vector2(CLICK_SCALE_MIN, CLICK_SCALE_MIN), CLICK_PHASE2_TIME).set_delay(CLICK_PHASE1_TIME).set_ease(Tween.EASE_IN_OUT)
	click_tween.tween_property(self, "rotation", CLICK_ROTATION_MIN, CLICK_PHASE2_TIME).set_delay(CLICK_PHASE1_TIME).set_ease(Tween.EASE_IN_OUT)
	
	# Фаза 3: Возврат к нормальному состоянию
	click_tween.tween_property(self, "scale", Vector2(1.0, 1.0), CLICK_PHASE3_TIME).set_delay(CLICK_PHASE1_TIME + CLICK_PHASE2_TIME).set_ease(Tween.EASE_OUT)
	click_tween.tween_property(self, "rotation", 0.0, CLICK_PHASE3_TIME).set_delay(CLICK_PHASE1_TIME + CLICK_PHASE2_TIME).set_ease(Tween.EASE_OUT)

# Создание улучшенного эффекта наведения
func create_hover_effect() -> void:
	# Легкое увеличение масштаба при наведении с плавным переходом
	var hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), HOVER_TIME).set_ease(Tween.EASE_OUT)

# Убираем эффект наведения
func remove_hover_effect() -> void:
	# Возвращаем к нормальному размеру с плавным переходом
	var hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", Vector2(1.0, 1.0), HOVER_TIME).set_ease(Tween.EASE_OUT)
