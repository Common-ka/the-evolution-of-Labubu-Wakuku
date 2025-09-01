extends Control

# Скрипт для главного меню

# Ссылки на кнопки
@onready var start_button: Button = $ButtonsContainer/StartButton
@onready var continue_button: Button = $ButtonsContainer/ContinueButton
@onready var achievements_button: Button = $ButtonsContainer/AchievementsButton
@onready var settings_button: Button = $ButtonsContainer/SettingsButton
@onready var quit_button: Button = $ButtonsContainer/QuitButton

func _ready() -> void:
	# Подключение сигналов кнопок
	start_button.pressed.connect(_on_start_button_pressed)
	continue_button.pressed.connect(_on_continue_button_pressed)
	achievements_button.pressed.connect(_on_achievements_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	# Проверяем наличие сохранения для кнопки "Продолжить"
	update_continue_button()

# Обработка нажатия "Начать игру"
func _on_start_button_pressed() -> void:
	print("Начинаем новую игру")
	
	# Сбрасываем игру к начальному состоянию
	GameManager.reset_game()
	
	# Переходим к игровой сцене
	change_scene_to_game()

# Обработка нажатия "Продолжить"
func _on_continue_button_pressed() -> void:
	print("Продолжаем игру")
	
	# Загружаем сохранение
	SaveSystem.load_game()
	
	# Переходим к игровой сцене
	change_scene_to_game()

func _on_achievements_button_pressed() -> void:
	print("Открываем панель достижений")
	var panel = load("res://scenes/ui/achievement_panel.tscn").instantiate()
	add_child(panel)
	panel.show()

# Обработка нажатия "Настройки"
func _on_settings_button_pressed() -> void:
	print("Открываем настройки")
	# TODO: Реализовать открытие настроек
	# EventBus.emit_signal("settings_requested")

# Обработка нажатия "Выход"
func _on_quit_button_pressed() -> void:
	print("Выходим из игры")
	get_tree().quit()

# Переход к игровой сцене
func change_scene_to_game() -> void:
	# Используем change_scene_to_file для перехода к Game сцене
	get_tree().change_scene_to_file("res://scenes/main/game.tscn")

# Обновление состояния кнопки "Продолжить"
func update_continue_button() -> void:
	# Проверяем наличие сохранения
	if SaveSystem.has_save_data():
		continue_button.disabled = false
		continue_button.text = "Продолжить"
	else:
		continue_button.disabled = true
		continue_button.text = "Нет сохранения"
