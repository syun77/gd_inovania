extends Node2D
# ==============================================
# 実績.
# ==============================================
class_name Achievement

# ----------------------------------------------
# const.
# ----------------------------------------------
## 種別.
enum eType {
	NORMAL_COMPLETED,
	MIN_COMPLETED,
	FAKE_COMPLETED,
	ALL_COMPLETED,
	SPEEDRUN_40SEC,
	SPEEDRUN_60SEC,
}
## 概要.
const TITLE = [
	"通常クリア",
	"ミニマムクリア",
	"コンプリート(?)クリア",
	"コンプリートクリア",
	"40秒クリア",
	"60秒クリア",
]

## 詳細.
const DETAIL = [
	"3種の神器を集める",
	"収集アイテムx3でクリアする",
	"収集アイテムx18でクリアする",
	"すべての収集アイテムを集める",
	"40秒以内でクリアする",
	"60秒以内でクリアする",
]

# ----------------------------------------------
# public functions.
# ----------------------------------------------
## すべての実績開放チェック.
static func check_all() -> void:
	for id in range(Achievement.eType.size()):
		if check(id):
			# 実績開放.
			print(get_title(id))
			
				
## 実績開放チェック.
static func check(id:eType) -> bool:
	assert(false, "未定義の実績:%d"%id)	
	return false
	
## 通常クリアチェック.
static func check_normal_completed() -> bool:
	for id in Map.ITEM_LEGENDS:
		if Common.gained_item(id) == false:
			return false
	return true
	
static func unlock(id:eType) -> void:
	Common.unlock_achievement(id)
static func unlocked(id:eType) -> bool:
	return Common.unlocked_achievement(id)
	
static func get_title(id:eType) -> String:
	return TITLE[id]
static func get_detail(id:eType) -> String:
	return DETAIL[id]
