class_name BattleUnit
extends Resource

@export var unit_name: String = ""
@export var is_player: bool = true
@export var max_hp: int = 100
@export var hp: int = 100
@export var max_mp: int = 50
@export var mp: int = 50
@export var attack: int = 15
@export var defense: int = 8
@export var agility: int = 50  # 敏捷 - 决定ATB充能速度
@export var spirit: int = 10   # 灵根 - 法术强度
@export var realm: String = "炼气期"  # 境界

var atb: float = 0.0  # ATB gauge 0-100
var is_dead: bool = false
var skills: Array = []

func get_atb_speed() -> float:
	return 1.0 + agility / 100.0

func take_damage(dmg: int) -> int:
	var actual = max(1, dmg - defense / 2)
	hp = max(0, hp - actual)
	if hp <= 0:
		is_dead = true
	return actual

func use_mp(cost: int) -> bool:
	if mp >= cost:
		mp -= cost
		return true
	return false
