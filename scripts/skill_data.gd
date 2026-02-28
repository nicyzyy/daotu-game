class_name SkillData
extends Resource

enum TargetType { SINGLE_ENEMY, ALL_ENEMIES, SELF, SINGLE_ALLY, ALL_ALLIES }
enum DamageType { PHYSICAL, MAGICAL, HEAL, BUFF }

@export var skill_name: String = ""
@export var description: String = ""
@export var mp_cost: int = 0
@export var base_power: int = 0
@export var target_type: TargetType = TargetType.SINGLE_ENEMY
@export var damage_type: DamageType = DamageType.PHYSICAL
@export var cooldown: int = 0  # turns

static func create(n: String, desc: String, mp: int, power: int, 
		target: TargetType = TargetType.SINGLE_ENEMY, 
		dtype: DamageType = DamageType.PHYSICAL) -> SkillData:
	var s = SkillData.new()
	s.skill_name = n
	s.description = desc
	s.mp_cost = mp
	s.base_power = power
	s.target_type = target
	s.damage_type = dtype
	return s
