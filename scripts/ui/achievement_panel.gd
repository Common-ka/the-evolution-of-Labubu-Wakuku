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

        var scroll := ScrollContainer.new()
        scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

        var list := VBoxContainer.new()
        list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        list.size_flags_vertical = Control.SIZE_EXPAND_FILL
        list.theme_override_constants.separation = 6

        var items := AchievementManager.get_achievements_by_category(category_id)
        for a in items:
            var row := HBoxContainer.new()
            row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            row.theme_override_constants.separation = 8

            var icon := Label.new()
            icon.text = a.icon
            icon.theme_override_font_sizes.font_size = 20

            var name_label := Label.new()
            name_label.text = a.name
            name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

            var progress := ProgressBar.new()
            progress.max_value = max(1, int(a.target))
            # Попробуем получить текущий прогресс из типа
            var current := 0
            match a.type:
                "cumulative_clicks":
                    current = AchievementManager.progress.cumulative_clicks
                "total_currency":
                    current = AchievementManager.progress.total_currency
                "upgrades_purchased":
                    current = AchievementManager.progress.upgrades_purchased
                "total_levels":
                    current = AchievementManager.progress.total_levels
            progress.value = clamp(current, 0, int(progress.max_value))
            progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL

            var status := Label.new()
            status.text = a.is_unlocked ? "✅" : "🔒"

            row.add_child(icon)
            row.add_child(name_label)
            row.add_child(progress)
            row.add_child(status)

            list.add_child(row)

        scroll.add_child(list)
        tab.add_child(scroll)
        tab_container.add_child(tab)
        tab_container.set_tab_title(tab_container.get_tab_count() - 1, _get_category_title(category_id))

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
    progress_label.text = "Прогресс: %d / %d" % [unlocked, total]
    progress_bar.max_value = max(1, total)
    progress_bar.value = unlocked


