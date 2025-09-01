extends Control

# Скрипт для уведомлений о достижениях
# Автоматически появляется и исчезает

@onready var panel: Panel = $Panel
@onready var icon_label: Label = $Panel/Margin/HBox/Icon
@onready var title_label: Label = $Panel/Margin/HBox/VBox/Title
@onready var name_label: Label = $Panel/Margin/HBox/VBox/AchievementName
@onready var description_label: Label = $Panel/Margin/HBox/VBox/Description
@onready var reward_label: Label = $Panel/Margin/HBox/VBox/Reward

# Настройки анимации
const ANIMATION_DURATION: float = 0.3
const DISPLAY_DURATION: float = 4.0
const SLIDE_DISTANCE: float = 100.0

# Таймер для автоматического закрытия
var auto_close_timer: Timer

func _ready() -> void:
	# Подключаемся к EventBus для получения уведомлений о достижениях
	EventBus.achievement_condition_met.connect(_on_achievement_unlocked)
	
	# Создаем таймер для автоматического закрытия
	auto_close_timer = Timer.new()
	auto_close_timer.one_shot = true
	auto_close_timer.timeout.connect(_on_auto_close_timer_timeout)
	add_child(auto_close_timer)
	
	# Изначально скрываем попап
	hide()
	
	print("[AchievementPopup] Инициализирован и подключен к EventBus")

# Показать уведомление о достижении
func show_achievement(achievement_id: String) -> void:
	var achievement = AchievementManager.achievements.get(achievement_id, null)
	if achievement == null:
		push_error("[AchievementPopup] Достижение не найдено: ", achievement_id)
		return
	
	# Заполняем данные
	icon_label.text = achievement.icon
	name_label.text = achievement.name
	description_label.text = achievement.description
	
	# Формируем текст награды
	match achievement.reward_type:
		"currency":
			reward_label.text = "Награда: +%d валюты" % achievement.reward_amount
		"multiplier":
			reward_label.text = "Награда: множитель x%.1f" % achievement.reward_amount
		"unlock":
			reward_label.text = "Награда: разблокировка контента"
		_:
			reward_label.text = "Награда получена!"
	
	# Показываем с анимацией
	_animate_in()
	
	# Запускаем таймер автоматического закрытия
	auto_close_timer.start(DISPLAY_DURATION)
	
	print("[AchievementPopup] Показано уведомление для: ", achievement.name)

# Анимация появления
func _animate_in() -> void:
	# Начальное состояние: скрыто и сдвинуто вниз
	modulate.a = 0.0
	panel.position.y = SLIDE_DISTANCE
	
	# Показываем
	show()
	
	# Анимация появления
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade in
	tween.tween_property(self, "modulate:a", 1.0, ANIMATION_DURATION)
	# Slide up
	tween.tween_property(panel, "position:y", 0.0, ANIMATION_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	print("[AchievementPopup] Анимация появления запущена")

# Анимация исчезновения
func _animate_out() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, ANIMATION_DURATION)
	# Slide down
	tween.tween_property(panel, "position:y", SLIDE_DISTANCE, ANIMATION_DURATION).set_ease(Tween.EASE_IN)
	
	# Скрываем после завершения анимации
	tween.tween_callback(hide)
	
	print("[AchievementPopup] Анимация исчезновения запущена")

# Автоматическое закрытие по таймеру
func _on_auto_close_timer_timeout() -> void:
	_animate_out()

# Обработчик события разблокировки достижения
func _on_achievement_unlocked(achievement_id: String) -> void:
	show_achievement(achievement_id)

# Ручное закрытие (можно вызвать извне)
func close() -> void:
	if auto_close_timer.time_left > 0:
		auto_close_timer.stop()
	_animate_out()

# Очистка при уничтожении
func _exit_tree() -> void:
	if auto_close_timer:
		auto_close_timer.queue_free()
