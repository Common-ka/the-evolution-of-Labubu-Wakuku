# Скрипт для кликабельного объекта (main_object)
# Обрабатывает клики и создает визуальные эффекты

extends Area2D

signal click_performed

# Ссылка на спрайт объекта
@onready var main_sprite: Sprite2D = $MainObjectSprite

# Tween для анимации клика
var click_tween: Tween

# Константы анимации
const CLICK_SCALE_MAX := 1.3
const CLICK_SCALE_MIN := 0.8
const CLICK_PHASE1_TIME := 0.1
const CLICK_PHASE2_TIME := 0.15
const CLICK_PHASE3_TIME := 0.2
const CLICK_ROTATION_MAX := 0.3
const CLICK_ROTATION_MIN := -0.2

# Константы для эффекта наведения
const HOVER_SCALE := 1.1
const HOVER_TIME := 0.2

func _ready() -> void:
	# Подключаем сигналы
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
	
	# Вызываем GameManager для обработки клика
	GameManager.perform_click()
	
	# Создаем эффект частиц
	create_particle_effect()
	
	# Создаем анимацию масштабирования
	create_scale_animation()

# Создание эффекта клика

# Создание эффекта частиц
func create_particle_effect() -> void:
	# Создаем эффект частиц через ParticleManager
	ParticleManager.create_click_effect(global_position)
	
	# Эмитируем сигнал для других систем
	EventBus.emit_signal("particle_effect_requested", "click_stars", global_position)

# Создание улучшенной анимации масштабирования и ротации
func create_scale_animation() -> void:
	# Проверяем валидность объекта
	if not is_instance_valid(self):
		return
	
	# Дополнительные проверки безопасности
	if not is_inside_tree():
		return
	
	if is_queued_for_deletion():
		return
	
	# Останавливаем предыдущую анимацию если она есть
	if click_tween and is_instance_valid(click_tween):
		click_tween.kill()
	
	# Создаем Tween через TweenManager
	click_tween = TweenManager.create_delayed_tween_for_node(self, 0.05)
	if not click_tween:
		return
	
	click_tween.set_parallel(true)
	
	# В Godot 4 задержка устанавливается на Tweener'е
	# Фаза 1: Быстрое увеличение с ротацией
	click_tween.tween_property(self, "scale", Vector2(CLICK_SCALE_MAX, CLICK_SCALE_MAX), CLICK_PHASE1_TIME).set_delay(0.05).set_ease(Tween.EASE_OUT)
	click_tween.tween_property(self, "rotation", CLICK_ROTATION_MAX, CLICK_PHASE1_TIME).set_delay(0.05).set_ease(Tween.EASE_OUT)
	
	# Фаза 2: Сжатие с обратной ротацией (эффект "отскока")
	click_tween.tween_property(self, "scale", Vector2(CLICK_SCALE_MIN, CLICK_SCALE_MIN), CLICK_PHASE2_TIME).set_delay(0.05 + CLICK_PHASE1_TIME).set_ease(Tween.EASE_IN_OUT)
	click_tween.tween_property(self, "rotation", CLICK_ROTATION_MIN, CLICK_PHASE2_TIME).set_delay(0.05 + CLICK_PHASE1_TIME).set_ease(Tween.EASE_IN_OUT)
	
	# Фаза 3: Возврат к нормальному состоянию
	click_tween.tween_property(self, "scale", Vector2(1.0, 1.0), CLICK_PHASE3_TIME).set_delay(0.05 + CLICK_PHASE1_TIME + CLICK_PHASE2_TIME).set_ease(Tween.EASE_OUT)
	click_tween.tween_property(self, "rotation", 0.0, CLICK_PHASE3_TIME).set_delay(0.05 + CLICK_PHASE1_TIME + CLICK_PHASE2_TIME).set_ease(Tween.EASE_OUT)

# Создание улучшенного эффекта наведения
func create_hover_effect() -> void:
	# Проверяем валидность объекта
	if not is_instance_valid(self) or not is_inside_tree() or is_queued_for_deletion():
		return
	
	# Легкое увеличение масштаба при наведении с плавным переходом
	var hover_tween = TweenManager.create_delayed_tween_for_node(self, 0.05)
	if hover_tween:
		# В Godot 4 задержка устанавливается на Tweener'е
		hover_tween.tween_property(self, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), HOVER_TIME).set_delay(0.05).set_ease(Tween.EASE_OUT)

# Убираем эффект наведения
func remove_hover_effect() -> void:
	# Проверяем валидность объекта
	if not is_instance_valid(self) or not is_inside_tree() or is_queued_for_deletion():
		return
	
	# Возвращаем к нормальному размеру с плавным переходом
	var hover_tween = TweenManager.create_delayed_tween_for_node(self, 0.05)
	if hover_tween:
		# В Godot 4 задержка устанавливается на Tweener'е
		hover_tween.tween_property(self, "scale", Vector2(1.0, 1.0), HOVER_TIME).set_delay(0.05).set_ease(Tween.EASE_OUT)

# Очистка при уничтожении
func _exit_tree() -> void:
	# TweenManager автоматически очистит все Tween'ы для этого узла
	pass
