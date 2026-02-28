extends Control

var battle_manager: BattleManager
var player_units: Array[BattleUnit] = []
var enemy_units: Array[BattleUnit] = []
var selected_skill: SkillData = null
var selecting_target: bool = false

func _ready():
	battle_manager = $BattleManager
	battle_manager.unit_ready.connect(_on_unit_ready)
	battle_manager.battle_log.connect(_on_battle_log)
	battle_manager.battle_ended.connect(_on_battle_ended)
	battle_manager.atb_updated.connect(_update_atb_bars)
	
	_setup_battle()

func _setup_battle():
	# Create player party
	var player1 = BattleUnit.new()
	player1.unit_name = "剑修·云逸"
	player1.is_player = true
	player1.max_hp = 120; player1.hp = 120
	player1.max_mp = 60; player1.mp = 60
	player1.attack = 20; player1.defense = 8
	player1.agility = 75; player1.spirit = 10
	player1.realm = "炼气期九层"
	player1.skills = [
		SkillData.create("御剑术", "剑气斩击单个敌人", 10, 25, SkillData.TargetType.SINGLE_ENEMY, SkillData.DamageType.PHYSICAL),
		SkillData.create("万剑归宗", "剑雨攻击全体敌人", 25, 15, SkillData.TargetType.ALL_ENEMIES, SkillData.DamageType.MAGICAL),
		SkillData.create("聚灵诀", "恢复自身生命", 15, 30, SkillData.TargetType.SELF, SkillData.DamageType.HEAL),
	]
	
	var player2 = BattleUnit.new()
	player2.unit_name = "丹修·灵溪"
	player2.is_player = true
	player2.max_hp = 90; player2.hp = 90
	player2.max_mp = 100; player2.mp = 100
	player2.attack = 10; player2.defense = 6
	player2.agility = 55; player2.spirit = 25
	player2.realm = "炼气期七层"
	player2.skills = [
		SkillData.create("灵火术", "灵火灼烧单个敌人", 12, 30, SkillData.TargetType.SINGLE_ENEMY, SkillData.DamageType.MAGICAL),
		SkillData.create("天火焚原", "烈焰焚烧全体敌人", 30, 20, SkillData.TargetType.ALL_ENEMIES, SkillData.DamageType.MAGICAL),
		SkillData.create("回春术", "恢复自身生命", 18, 40, SkillData.TargetType.SELF, SkillData.DamageType.HEAL),
	]
	
	player_units = [player1, player2]
	
	# Create enemies
	var enemy1 = BattleUnit.new()
	enemy1.unit_name = "妖狼"
	enemy1.is_player = false
	enemy1.max_hp = 80; enemy1.hp = 80
	enemy1.max_mp = 20; enemy1.mp = 20
	enemy1.attack = 15; enemy1.defense = 5
	enemy1.agility = 65; enemy1.spirit = 5
	
	var enemy2 = BattleUnit.new()
	enemy2.unit_name = "毒蛇精"
	enemy2.is_player = false
	enemy2.max_hp = 60; enemy2.hp = 60
	enemy2.max_mp = 30; enemy2.mp = 30
	enemy2.attack = 18; enemy2.defense = 3
	enemy2.agility = 80; enemy2.spirit = 12
	
	var enemy3 = BattleUnit.new()
	enemy3.unit_name = "石魔"
	enemy3.is_player = false
	enemy3.max_hp = 150; enemy3.hp = 150
	enemy3.max_mp = 10; enemy3.mp = 10
	enemy3.attack = 22; enemy3.defense = 15
	enemy3.agility = 30; enemy3.spirit = 3
	
	enemy_units = [enemy1, enemy2, enemy3]
	
	battle_manager.start_battle(player_units, enemy_units)
	_update_all_ui()

func _update_all_ui():
	_update_player_panels()
	_update_enemy_panels()
	_update_atb_bars()

func _update_player_panels():
	for i in range(player_units.size()):
		var u = player_units[i]
		var panel = get_node_or_null("BattleField/PlayerSide/Player%d" % (i + 1))
		if panel:
			panel.get_node("Name").text = u.unit_name
			panel.get_node("Realm").text = u.realm
			panel.get_node("HP").text = "HP: %d/%d" % [u.hp, u.max_hp]
			panel.get_node("MP").text = "MP: %d/%d" % [u.mp, u.max_mp]
			panel.get_node("HPBar").value = float(u.hp) / u.max_hp * 100
			panel.get_node("MPBar").value = float(u.mp) / u.max_mp * 100
			panel.modulate = Color(1, 1, 1, 0.3) if u.is_dead else Color(1, 1, 1, 1)

func _update_enemy_panels():
	for i in range(enemy_units.size()):
		var u = enemy_units[i]
		var panel = get_node_or_null("BattleField/EnemySide/Enemy%d" % (i + 1))
		if panel:
			panel.get_node("Name").text = u.unit_name
			panel.get_node("HP").text = "HP: %d/%d" % [u.hp, u.max_hp]
			panel.get_node("HPBar").value = float(u.hp) / u.max_hp * 100
			panel.modulate = Color(1, 1, 1, 0.3) if u.is_dead else Color(1, 1, 1, 1)

func _update_atb_bars():
	for i in range(player_units.size()):
		var bar = get_node_or_null("ATBPanel/ATB_P%d/Bar" % (i + 1))
		var label = get_node_or_null("ATBPanel/ATB_P%d/Label" % (i + 1))
		if bar and label:
			bar.value = player_units[i].atb
			label.text = player_units[i].unit_name
	for i in range(enemy_units.size()):
		var bar = get_node_or_null("ATBPanel/ATB_E%d/Bar" % (i + 1))
		var label = get_node_or_null("ATBPanel/ATB_E%d/Label" % (i + 1))
		if bar and label:
			bar.value = enemy_units[i].atb
			label.text = enemy_units[i].unit_name

func _on_unit_ready(unit: BattleUnit):
	_update_all_ui()
	# Show action buttons
	$ActionPanel.visible = true
	$ActionPanel/UnitLabel.text = "【%s 的回合】" % unit.unit_name
	$TargetPanel.visible = false
	selected_skill = null
	selecting_target = false
	
	# Setup skill buttons
	for i in range(3):
		var btn = $ActionPanel/Skills.get_node_or_null("Skill%d" % (i + 1))
		if btn:
			if i < unit.skills.size():
				var sk = unit.skills[i]
				btn.text = "%s (MP:%d)" % [sk.skill_name, sk.mp_cost]
				btn.visible = true
				btn.disabled = unit.mp < sk.mp_cost
				# Disconnect old signals
				if btn.pressed.is_connected(_on_skill_pressed):
					btn.pressed.disconnect(_on_skill_pressed)
				btn.pressed.connect(_on_skill_pressed.bind(i))
			else:
				btn.visible = false
	
	# Attack button
	if $ActionPanel/AttackBtn.pressed.is_connected(_on_attack):
		$ActionPanel/AttackBtn.pressed.disconnect(_on_attack)
	$ActionPanel/AttackBtn.pressed.connect(_on_attack)

func _on_attack():
	selected_skill = null
	_show_target_selection()

func _on_skill_pressed(idx: int):
	var unit = battle_manager.current_unit
	if idx < unit.skills.size():
		selected_skill = unit.skills[idx]
		if selected_skill.target_type == SkillData.TargetType.SELF:
			battle_manager.execute_skill(unit, selected_skill, unit)
			$ActionPanel.visible = false
			_update_all_ui()
		elif selected_skill.target_type == SkillData.TargetType.ALL_ENEMIES:
			var enemies = enemy_units.filter(func(u): return not u.is_dead)
			if not enemies.is_empty():
				battle_manager.execute_skill(unit, selected_skill, enemies[0])
			$ActionPanel.visible = false
			_update_all_ui()
		else:
			_show_target_selection()

func _show_target_selection():
	$ActionPanel.visible = false
	$TargetPanel.visible = true
	selecting_target = true
	
	# Create target buttons
	for child in $TargetPanel/Targets.get_children():
		child.queue_free()
	
	var alive_enemies = enemy_units.filter(func(u): return not u.is_dead)
	for i in range(alive_enemies.size()):
		var btn = Button.new()
		btn.text = "%s (HP:%d/%d)" % [alive_enemies[i].unit_name, alive_enemies[i].hp, alive_enemies[i].max_hp]
		btn.custom_minimum_size = Vector2(250, 40)
		btn.pressed.connect(_on_target_selected.bind(alive_enemies[i]))
		$TargetPanel/Targets.add_child(btn)

func _on_target_selected(target: BattleUnit):
	$TargetPanel.visible = false
	selecting_target = false
	var unit = battle_manager.current_unit
	if selected_skill:
		battle_manager.execute_skill(unit, selected_skill, target)
	else:
		battle_manager.execute_attack(unit, target)
	_update_all_ui()

func _on_battle_log(text: String):
	$LogPanel/Log.text += text + "\n"
	# Auto scroll
	await get_tree().process_frame
	$LogPanel/Log.scroll_vertical = $LogPanel/Log.get_v_scroll_bar().max_value

func _on_battle_ended(won: bool):
	$ActionPanel.visible = false
	$TargetPanel.visible = false
	# Show result
	var result = $ResultPanel
	result.visible = true
	result.get_node("ResultLabel").text = "🎉 战斗胜利！获得修为 +50" if won else "💀 道消身陨..."
	result.get_node("ReturnBtn").pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
