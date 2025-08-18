extends Node2D

# Скрипт для UI игровой сцены

# Ссылки на UI элементы
@onready var currency_display: Label = $UI/HUD/CurrencyDisplay
@onready var level_display: Label = $UI/HUD/LevelDisplay
@onready var menu_button: Button = $UI/HUD/MenuButton

func _ready() -> void:
	# Подключение сигналов
	menu_button.pressed.connect(_on_menu_button_pressed)
	
	# Подключение сигналов GameManager для обновления UI
	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.level_up.connect(_on_level_up)
	
	# Инициализация UI
	update_currency_display()
	update_level_display()
	
	# Отладочная информация о HUD
	print("Game UI: HUD размеры - ", $UI/HUD.size)
	print("Game UI: HUD позиция - ", $UI/HUD.position)
	print("Game UI: HUD mouse_filter - ", $UI/HUD.mouse_filter)

# Обработка нажатия кнопки "Меню"
func _on_menu_button_pressed() -> void:
	print("Возвращаемся в главное меню")
	
	# Сохраняем игру перед выходом
	SaveSystem.save_game()
	
	# Переходим обратно в главное меню
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

# Обновление отображения валюты
func update_currency_display() -> void:
	currency_display.text = "Валюты: " + str(GameManager.current_currency)

# Обновление отображения уровня
func update_level_display() -> void:
	level_display.text = "Уровень: " + str(GameManager.current_level)

# Обработчики сигналов
func _on_currency_changed(new_amount: int) -> void:
	update_currency_display()

func _on_level_up(new_level: int) -> void:
	update_level_display()

# Отладочная обработка всех событий ввода
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("Game UI: Получен клик мыши в позиции ", event.position, " кнопка ", event.button_index)
		
		# Проверяем, попадает ли клик в область HUD
		var hud_rect = Rect2($UI/HUD.position, $UI/HUD.size)
		if hud_rect.has_point(event.position):
			print("Game UI: Клик попал в область HUD")
		else:
			print("Game UI: Клик НЕ попал в область HUD")
