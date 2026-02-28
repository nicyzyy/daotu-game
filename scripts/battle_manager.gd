class_name BattleManager
extends Node

signal unit_ready(unit: BattleUnit)
signal battle_log(text: String)
signal battle_ended(won: bool)
signal atb_updated()

var all_units: Array[BattleUnit] = []
var player_units: Array[BattleUnit] = []
var enemy_units: Array[BattleUnit] = []
var current_unit: BattleUnit = null
var is_waiting_input: bool = false
var battle_active: bool = false
var atb_speed_scale: float = 30.0  # ATB base tick speed

func start_battle(players: Array[BattleUnit], enemies: Array[BattleUnit]):
	player_units = players
	enemy_units = enemies
	all_units = []
	all_units.append_array(players)
	all_units.append_array(enemies)
	
	# Randomize starting ATB based on agility
	for u in all_units:
		u.atb = randf_range(0, 20) + u.agility * 0.3
		u.is_dead = false
	
	battle_active = true
	battle_log.emit("⚔️ 战斗开始！")

func _process(delta):
	if not battle_active or is_waiting_input:
		return
	
	# Tick ATB for all alive units
	for u in all_units:
		if u.is_dead:
			continue
		u.atb += u.get_atb_speed() * atb_speed_scale * delta
	
	atb_updated.emit()
	
	# Check if any unit reached 100
	var ready_unit: BattleUnit = null
	var max_atb: float = 0
	for u in all_units:
		if u.is_dead:
			continue
		if u.atb >= 100.0 and u.atb > max_atb:
			max_atb = u.atb
			ready_unit = u
	
	if ready_unit:
		ready_unit.atb = 0.0
		current_unit = ready_unit
		if ready_unit.is_player:
			is_waiting_input = true
			unit_ready.emit(ready_unit)
		else:
			_enemy_ai(ready_unit)

func _enemy_ai(unit: BattleUnit):
	# Simple AI: attack random alive player
	var alive_players = player_units.filter(func(u): return not u.is_dead)
	if alive_players.is_empty():
		_check_battle_end()
		return
	
	var target = alive_players[randi() % alive_players.size()]
	execute_attack(unit, target)

func execute_attack(attacker: BattleUnit, target: BattleUnit):
	var dmg = attacker.attack + randi_range(-3, 3)
	var actual = target.take_damage(dmg)
	battle_log.emit("%s 攻击 %s，造成 %d 伤害！" % [attacker.unit_name, target.unit_name, actual])
	
	if target.is_dead:
		battle_log.emit("💀 %s 被击败了！" % target.unit_name)
	
	is_waiting_input = false
	current_unit = null
	_check_battle_end()

func execute_skill(attacker: BattleUnit, skill: SkillData, target: BattleUnit):
	if not attacker.use_mp(skill.mp_cost):
		battle_log.emit("灵力不足！")
		return
	
	var power = skill.base_power
	match skill.damage_type:
		SkillData.DamageType.PHYSICAL:
			power += attacker.attack
		SkillData.DamageType.MAGICAL:
			power += attacker.spirit * 2
		SkillData.DamageType.HEAL:
			target.hp = min(target.max_hp, target.hp + power + attacker.spirit)
			battle_log.emit("✨ %s 对 %s 使用 %s，恢复 %d 生命！" % [attacker.unit_name, target.unit_name, skill.skill_name, power + attacker.spirit])
			is_waiting_input = false
			current_unit = null
			return
	
	if skill.target_type == SkillData.TargetType.ALL_ENEMIES:
		var targets = enemy_units if attacker.is_player else player_units
		for t in targets:
			if not t.is_dead:
				var actual = t.take_damage(power)
				battle_log.emit("🔥 %s 对 %s 使用 %s，造成 %d 伤害！" % [attacker.unit_name, t.unit_name, skill.skill_name, actual])
				if t.is_dead:
					battle_log.emit("💀 %s 被击败了！" % t.unit_name)
	else:
		var actual = target.take_damage(power)
		battle_log.emit("⚡ %s 对 %s 使用 %s，造成 %d 伤害！" % [attacker.unit_name, target.unit_name, skill.skill_name, actual])
		if target.is_dead:
			battle_log.emit("💀 %s 被击败了！" % target.unit_name)
	
	is_waiting_input = false
	current_unit = null
	_check_battle_end()

func _check_battle_end():
	var alive_players = player_units.filter(func(u): return not u.is_dead)
	var alive_enemies = enemy_units.filter(func(u): return not u.is_dead)
	
	if alive_enemies.is_empty():
		battle_active = false
		battle_log.emit("🎉 战斗胜利！")
		battle_ended.emit(true)
	elif alive_players.is_empty():
		battle_active = false
		battle_log.emit("💀 战斗失败...")
		battle_ended.emit(false)
