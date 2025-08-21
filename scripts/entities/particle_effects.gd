extends Node2D

# Скрипт для управления эффектами частиц
# Настраивает CPUParticles2D и эмитирует сигнал завершения

signal effect_finished(effect: Node2D)

@onready var particles: CPUParticles2D = $CPUParticles2D

# Константы для эффектов
const TIMER_SAFETY_MARGIN := 0.5

# Таймер для автоматического завершения эффекта
var effect_timer: Timer

func _ready() -> void:
	# Проверяем, что узел CPUParticles2D найден
	if not particles:
		var found_particles = get_node_or_null("CPUParticles2D")
		if found_particles:
			particles = found_particles
		else:
			push_error("ParticleEffects: CPUParticles2D узел не найден!")
			return
	
	# Создаем таймер для завершения эффекта
	effect_timer = Timer.new()
	effect_timer.one_shot = true
	effect_timer.timeout.connect(_on_effect_timer_timeout)
	add_child(effect_timer)
	
	# Подключаем сигнал завершения частиц
	particles.finished.connect(_on_particles_finished)

# Настройка эффекта
func setup_effect() -> void:
	if not particles:
		push_error("ParticleEffects: Нельзя настроить эффект - particles = null")
		return
	
	# Запускаем эффект
	particles.emitting = true
	particles.restart()
	
	# Запускаем таймер как fallback (используем время жизни частиц + запас)
	var timer_duration = particles.lifetime + TIMER_SAFETY_MARGIN
	effect_timer.start(timer_duration)



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
