extends Control

# Панель достижений: базовая логика и связывание с AchievementManager

@onready var tab_container: TabContainer = $Panel/Margin/Root/Tabs
@onready var progress_label: Label = $Panel/Margin/Root/Footer/ProgressLabel
@onready var progress_bar: ProgressBar = $Panel/Margin/Root/Footer/ProgressBar
@onready var close_button: Button = $Panel/Margin/Root/Header/CloseButton

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	_build_tabs()
	_update_summary()

func _on_close_pressed() -> void:
	queue_free()

func _build_tabs() -> void:
	# Категории соответствуют ключам в achievements.json
	var categories: Array[String] = [
		"click_milestones",
		"currency_milestones",
		"upgrade_milestones",
		"level_milestones"
	]

	for category_id in categories:
		var tab := Control.new()
		tab.name = category_id
		# Вкладка должна растягиваться внутри TabContainer
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tab.set_anchors_preset(Control.PRESET_FULL_RECT)

		var scroll := ScrollContainer.new()
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.set_anchors_preset(Control.PRESET_FULL_RECT)

		var list := VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.size_flags_vertical = Control.SIZE_EXPAND_FILL
		list.set_anchors_preset(Control.PRESET_FULL_RECT)
		list.add_theme_constant_override("separation", 6)

		# Не создаём элементы сразу — отложим построение

		scroll.add_child(list)
		tab.add_child(scroll)
		tab_container.add_child(tab)
		var title = _get_category_title(category_id)
		var count = AchievementManager.get_achievements_by_category(category_id).size()
		tab_container.set_tab_title(tab_container.get_tab_count() - 1, "%s (%d)" % [title, count])

	# Подпишемся на смену вкладок и отложим построение активной
	tab_container.tab_changed.connect(_on_tab_changed)
	call_deferred("_on_tab_changed", tab_container.current_tab)

func _on_tab_changed(index: int) -> void:
	var tab := tab_container.get_tab_control(index)
	if tab == null:
		return
	var scroll := tab.get_child(0) as ScrollContainer
	if scroll == null:
		return
	var list := scroll.get_child(0) as VBoxContainer
	if list == null:
		return
	if list.get_child_count() > 0:
		return
	var category_id := tab.name
	call_deferred("_build_tab_items_async", tab, category_id)

func _build_tab_items_async(tab: Control, category_id: String) -> void:
	var item_scene: PackedScene = load("res://scenes/ui/achievement_item.tscn")
	var scroll := tab.get_child(0) as ScrollContainer
	var list := scroll.get_child(0) as VBoxContainer
	var items: Array = AchievementManager.get_achievements_by_category(category_id)
	# Синхронно создаём первые 15 элементов, остальные — батчами
	var first_sync: int = min(15, items.size())
	for i in range(first_sync):
		var item: AchievementListItem = item_scene.instantiate()
		list.add_child(item)
		item.setup(items[i])
	await get_tree().process_frame
	var batch: int = 30
	var i: int = first_sync
	while i < items.size():
		var end_i: int = min(i + batch, items.size())
		for j in range(i, end_i):
			var item2: AchievementListItem = item_scene.instantiate()
			list.add_child(item2)
			item2.setup(items[j])
		i = end_i
		await get_tree().process_frame

func _get_category_title(category_id: String) -> String:
	match category_id:
		"click_milestones":
			return "Клики"
		"currency_milestones":
			return "Валюта"
		"upgrade_milestones":
			return "Апгрейды"
		"level_milestones":
			return "Уровни"
		_:
			return category_id

func _update_summary() -> void:
	var unlocked := AchievementManager.get_unlocked_count()
	var total := AchievementManager.get_total_count()
	var percentage := (float(unlocked) / float(total)) * 100.0 if total > 0 else 0.0
	progress_label.text = "Прогресс: %d / %d (%.1f%%)" % [unlocked, total, percentage]
	progress_bar.max_value = max(1, total)
	progress_bar.value = unlocked
