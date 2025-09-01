extends HBoxContainer

class_name AchievementItem

@onready var icon_label: Label = $Icon
@onready var name_label: Label = $Info/Name
@onready var description_label: Label = $Info/Description
@onready var progress_bar: ProgressBar = $Info/ProgressRow/ProgressBar
@onready var progress_text: Label = $Info/ProgressRow/ProgressText
@onready var reward_label: Label = $Info/Reward
@onready var status_label: Label = $Status

var achievement: Achievement
var _is_ready: bool = false

func _ready() -> void:
    _is_ready = true
    if achievement != null:
        _refresh()

func setup(achievement_data: Achievement) -> void:
    achievement = achievement_data
    if _is_ready:
        _refresh()
    else:
        call_deferred("_refresh")

func _refresh() -> void:
    if achievement == null:
        return

    if icon_label == null or name_label == null or description_label == null:
        # Узлы ещё не готовы; попробуем повторить после кадра
        call_deferred("_refresh")
        return
    icon_label.text = achievement.icon
    name_label.text = achievement.name
    description_label.text = achievement.get_description_with_target()

    var current := 0
    match achievement.type:
        "cumulative_clicks":
            current = AchievementManager.progress.cumulative_clicks
        "total_currency":
            current = AchievementManager.progress.total_currency
        "upgrades_purchased":
            current = AchievementManager.progress.upgrades_purchased
        "total_levels":
            current = AchievementManager.progress.total_levels

    var target := int(achievement.target)
    progress_bar.max_value = max(1, target)
    progress_bar.value = clamp(current, 0, target)
    progress_text.text = str(min(current, target), "/", target)

    if achievement.is_unlocked:
        status_label.text = "✅"
        reward_label.text = "Получено"
    else:
        status_label.text = "🔒"
        reward_label.text = "Награда: " + _format_reward()

func _format_reward() -> String:
    match achievement.reward_type:
        "currency":
            return "+%d валюты" % int(achievement.reward_amount)
        "multiplier":
            return "x" + str(achievement.reward_amount)
        "unlock":
            return "разблокировка"
        _:
            return ""


