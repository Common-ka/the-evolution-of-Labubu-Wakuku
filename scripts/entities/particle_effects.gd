extends Node2D

# Скрипт для управления эффектами частиц
# Настраивает CPUParticles2D и эмитирует сигнал завершения

signal effect_finished(effect: Node2D)

@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var debug_label: Label = $DebugLabel

# Таймер для автоматического завершения эффекта
var effect_timer: Timer

func _ready() -> void:
	# Проверяем, что узлы найдены
	if not particles:
		print("[ParticleEffects] ОШИБКА: CPUParticles2D узел не найден!")
		return
	
	if not debug_label:
		print("[ParticleEffects] ОШИБКА: DebugLabel узел не найден!")
		return
	
	# Создаем таймер для завершения эффекта
	effect_timer = Timer.new()
	effect_timer.one_shot = true
	effect_timer.timeout.connect(_on_effect_timer_timeout)
	add_child(effect_timer)
	
	# Подключаем сигнал завершения частиц
	particles.finished.connect(_on_particles_finished)
	
	print("[ParticleEffects] _ready: узлы инициализированы успешно")

# Настройка эффекта
func setup_effect(effect_type: String) -> void:
	# Проверяем, что частицы доступны
	if not particles:
		print("[ParticleEffects] ОШИБКА: Нельзя настроить эффект - particles = null")
		return
	
	match effect_type:
		"click_stars":
			_setup_click_stars()
		_:
			print("[ParticleEffects] Неизвестный тип эффекта: ", effect_type)
			return
	
	# Запускаем эффект
	particles.emitting = true
	print("[ParticleEffects] particles.emitting установлен в: ", particles.emitting)
	
	# Принудительный restart для гарантии
	particles.restart()
	print("[ParticleEffects] particles.restart() вызван")
	
	# Запускаем таймер как fallback (используем время жизни частиц + запас)
	var timer_duration = particles.lifetime + 0.5
	effect_timer.start(timer_duration)
	
	print("[ParticleEffects] Эффект ", effect_type, " запущен, таймер на ", timer_duration, " сек")

# Настройка эффекта звездочек для клика
func _setup_click_stars() -> void:
	print("[ParticleEffects] Настройка эффекта звездочек")
	
	# НЕ переопределяем настройки - используем из сцены!
	# Просто проверяем текущие настройки
	print("[ParticleEffects] Количество частиц: ", particles.amount)
	print("[ParticleEffects] Время жизни: ", particles.lifetime)
	print("[ParticleEffects] Цвет: ", particles.color)
	print("[ParticleEffects] Размер: ", particles.scale_amount_min, " - ", particles.scale_amount_max)
	print("[ParticleEffects] Эмиссия: ", particles.emitting)
	
	print("[ParticleEffects] Эффект звездочек настроен успешно")

# Создание градиента цветов
func _create_color_ramp(colors: Array) -> Gradient:
	var gradient = Gradient.new()
	for i in colors.size():
		var color = colors[i]
		var offset = float(i) / (colors.size() - 1)
		gradient.add_point(offset, color)
	return gradient

# Обработчик завершения частиц
func _on_particles_finished() -> void:
	_cleanup_effect()

# Обработчик таймера (fallback)
func _on_effect_timer_timeout() -> void:
	_cleanup_effect()

# Очистка эффекта
func _cleanup_effect() -> void:
	# Останавливаем таймер
	if effect_timer:
		effect_timer.stop()
	
	# Сбрасываем состояние частиц
	particles.emitting = false
	particles.restart()
	
	# Эмитируем сигнал завершения
	effect_finished.emit(self)
	
	print("[ParticleEffects] Эффект завершен")

# Показать/скрыть отладочную информацию
func set_debug_visible(visible: bool) -> void:
	if debug_label:
		debug_label.visible = visible
