# Скрипт для попапа достижений
# Показывает уведомления о разблокированных достижениях

extends Control

signal achievement_shown(achievement_id: String)

@onready var panel: Panel = $Panel
@onready var icon_label: Label = $Panel/Margin/HBox/Icon
@onready var name_label: Label = $Panel/Margin/HBox/VBox/AchievementName
@onready var description_label: Label = $Panel/Margin/HBox/VBox/Description
@onready var reward_label: Label = $Panel/Margin/HBox/VBox/Reward
@onready var auto_close_timer: Timer = Timer.new()

# Константы анимации
const ANIMATION_DURATION := 0.5
const DISPLAY_DURATION := 3.0

func _ready() -> void:
	# Подключаемся к EventBus для получения уведомлений о достижениях
	EventBus.achievement_condition_met.connect(_on_achievement_unlocked)
	
	# Настройка таймера
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
	# Проверяем валидность объекта
	if not is_instance_valid(self):
		print("[AchievementPopup] Объект невалиден, пропускаем анимацию")
		return
	
	# Дополнительные проверки безопасности
	if not is_inside_tree():
		print("[AchievementPopup] Узел не в дереве сцены, пропускаем анимацию")
		return
	
	if is_queued_for_deletion():
		print("[AchievementPopup] Узел помечен на удаление, пропускаем анимацию")
		return
	
	# Начальное состояние: скрыто
	modulate.a = 0.0
	
	# Показываем
	show()
	
	# Анимация появления через TweenManager с отложенным запуском
	var tween = TweenManager.create_delayed_tween_for_node(self, 0.05)
	if tween:
		# В Godot 4 задержка устанавливается на Tweener'е
		tween.tween_property(self, "modulate:a", 1.0, ANIMATION_DURATION).set_delay(0.05)
		print("[AchievementPopup] Анимация появления запущена")
	else:
		print("[AchievementPopup] Не удалось создать Tween для анимации появления")

# Анимация исчезновения
func _animate_out() -> void:
	# Проверяем валидность объекта
	if not is_instance_valid(self):
		print("[AchievementPopup] Объект невалиден, пропускаем анимацию")
		return
	
	# Дополнительные проверки безопасности
	if not is_inside_tree():
		print("[AchievementPopup] Узел не в дереве сцены, пропускаем анимацию")
		return
	
	if is_queued_for_deletion():
		print("[AchievementPopup] Узел помечен на удаление, пропускаем анимацию")
		return
	
	# Анимация исчезновения через TweenManager с отложенным запуском
	var tween = TweenManager.create_delayed_tween_for_node(self, 0.05)
	if tween:
		# В Godot 4 задержка устанавливается на Tweener'е
		tween.tween_property(self, "modulate:a", 0.0, ANIMATION_DURATION).set_delay(0.05)
		
		# Скрываем после завершения анимации
		tween.tween_callback(hide)
		
		print("[AchievementPopup] Анимация исчезновения запущена")
	else:
		print("[AchievementPopup] Не удалось создать Tween для анимации исчезновения")
		# Fallback: скрываем сразу
		hide()

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
	# Останавливаем таймер
	if auto_close_timer:
		auto_close_timer.queue_free()
	
	# TweenManager автоматически очистит все Tween'ы для этого узла
	print("[AchievementPopup] Очистка завершена")
