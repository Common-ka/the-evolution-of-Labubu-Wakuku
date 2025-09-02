extends Control

# Скрипт для Floating Text - всплывающий текст с анимацией
# Показывает получаемую валюту при клике

signal animation_finished(text: Control)

@onready var label: Label = $Label
var tween: Tween

# Константы анимации
const ANIMATION_DURATION := 1.5
const FLOAT_DISTANCE := 80.0
const FADE_START_TIME := 0.8
const SCALE_UP_TIME := 0.2
const SCALE_DOWN_TIME := 0.3

# Показ значения валюты с анимацией
func show_value(value: int, start_position: Vector2) -> void:
	# Настройка текста
	label.text = "+" + str(value)
	
	# Позиционирование с случайным смещением для разнообразия
	var random_offset = Vector2(
		randf_range(-20.0, 20.0),
		randf_range(-10.0, 10.0)
	)
	position = start_position + random_offset
	
	# Настройка цвета в зависимости от значения
	if value >= 10:
		label.modulate = Color.GOLD
	elif value >= 5:
		label.modulate = Color.GREEN
	else:
		label.modulate = Color.LIGHT_GREEN
	
	# Сброс прозрачности
	label.modulate.a = 1.0
	
	# Сброс масштаба
	scale = Vector2.ONE
	
	# Запуск анимации
	_start_animation()

# Запуск анимации
func _start_animation() -> void:
	# Проверяем валидность объекта
	if not is_instance_valid(self):
		print("[FloatingText] Объект невалиден, пропускаем анимацию")
		return
	
	# Останавливаем предыдущую анимацию если есть
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	
	# Движение вверх
	tween.tween_property(self, "position:y", position.y - FLOAT_DISTANCE, ANIMATION_DURATION).set_ease(Tween.EASE_OUT)
	
	# Затухание (начинается через FADE_START_TIME)
	tween.tween_property(label, "modulate:a", 0.0, ANIMATION_DURATION - FADE_START_TIME).set_delay(FADE_START_TIME).set_ease(Tween.EASE_IN)
	
	# Анимация масштаба: увеличение, затем уменьшение
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), SCALE_UP_TIME).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), SCALE_DOWN_TIME).set_delay(SCALE_UP_TIME).set_ease(Tween.EASE_IN_OUT)
	
	# Завершение анимации
	tween.tween_callback(_on_animation_complete).set_delay(ANIMATION_DURATION)

# Обработчик завершения анимации
func _on_animation_complete() -> void:
	print("[FloatingText] Анимация завершена для значения: ", label.text)
	animation_finished.emit(self)
