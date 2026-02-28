extends Control

var battle_manager: BattleManager
var player_units: Array[BattleUnit] = []
var enemy_units: Array[BattleUnit] = []
var selected_skill: SkillData = null
var selecting_target: bool = false
var char_sprites: Dictionary = {}  # unit_name -> Sprite2D

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
	_spawn_sprites()
	battle_manager.start_battle(player_units, enemy_units)
	_update_all_ui()

func _spawn_sprites():
	var layer = $BattleField/CharacterLayer
	
	# Sprite configs: name, texture path, position, scale, flip
	var configs = [
		["剑修·云逸", "res://assets/sprites/sword_cultivator.png", Vector2(220, 420), 0.22, false],
		["丹修·灵溪", "res://assets/sprites/dan_cultivator.png", Vector2(100, 440), 0.20, false],
		["妖狼", "res://assets/sprites/wolf_monster.png", Vector2(780, 410), 0.22, true],
		["毒蛇精", "res://assets/sprites/snake_spirit.png", Vector2(930, 420), 0.20, true],
		["石魔", "res://assets/sprites/stone_golem.png", Vector2(1080, 380), 0.28, true],
	]
	
	for cfg in configs:
		var sprite = Sprite2D.new()
		sprite.name = cfg[0]
		var tex = load(cfg[1])
		if tex:
			sprite.texture = tex
		sprite.position = cfg[2]
		sprite.scale = Vector2(cfg[3], cfg[3])
		if cfg[4]:
			sprite.flip_h = true
		# Idle breathing animation
		var tween = create_tween().set_loops()
		tween.tween_property(sprite, "position:y", cfg[2].y - 5, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_property(sprite, "position:y", cfg[2].y + 5, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		
		layer.add_child(sprite)
		char_sprites[cfg[0]] = sprite

func _play_attack_anim(attacker_name: String, target_name: String):
	var attacker = char_sprites.get(attacker_name)
	var target = char_sprites.get(target_name)
	if not attacker or not target:
		return
	
	var original_pos = attacker.position
	var dir = (target.position - attacker.position).normalized()
	var lunge_pos = original_pos + dir * 60
	
	# Lunge forward
	var tween = create_tween()
	tween.tween_property(attacker, "position", lunge_pos, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(_play_hit_anim.bind(target_name))
	tween.tween_property(attacker, "position", original_pos, 0.3).set_ease(Tween.EASE_IN_OUT)

func _play_hit_anim(target_name: String):
	var target = char_sprites.get(target_name)
	if not target:
		return
	
	# Flash red and shake
	var tween = create_tween()
	tween.tween_property(target, "modulate", Color(1.5, 0.3, 0.3), 0.05)
	tween.tween_property(target, "position:x", target.position.x + 15, 0.05)
	tween.tween_property(target, "position:x", target.position.x - 15, 0.05)
	tween.tween_property(target, "position:x", target.position.x + 8, 0.05)
	tween.tween_property(target, "position:x", target.position.x, 0.05)
	tween.tween_property(target, "modulate", Color.WHITE, 0.2)

func _play_defeated_anim(unit_name: String):
	var sprite = char_sprites.get(unit_name)
	if not sprite:
		return
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.3, 0.5)
	tween.parallel().tween_property(sprite, "rotation", deg_to_rad(90), 0.5)
	tween.parallel().tween_property(sprite, "position:y", sprite.position.y + 30, 0.5)

func _play_heal_anim(unit_name: String):
	var sprite = char_sprites.get(unit_name)
	if not sprite:
		return
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(0.5, 1.5, 0.5), 0.2)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.4)

func _play_skill_anim(attacker_name: String, target_name: String):
	var attacker = char_sprites.get(attacker_name)
	if not attacker:
		return
	# Scale up briefly (power up)
	var tween = create_tween()
	tween.tween_property(attacker, "scale", attacker.scale * 1.15, 0.15)
	tween.tween_property(attacker, "modulate", Color(1.2, 1.2, 1.5), 0.1)
	tween.tween_callback(_play_hit_anim.bind(target_name))
	tween.tween_property(attacker, "scale", attacker.scale, 0.2)
	tween.tween_property(attacker, "modulate", Color.WHITE, 0.2)

func _update_all_ui():
	_update_player_panels()
	_update_enemy_panels()
	_update_atb_bars()

func _update_player_panels():
	for i in range(player_units.size()):
		var u = player_units[i]
		var panel = get_node_or_null("UI/TopBar/PlayerSide/Player%d" % (i + 1))
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
		var panel = get_node_or_null("UI/TopBar/EnemySide/Enemy%d" % (i + 1))
		if panel:
			panel.get_node("Name").text = u.unit_name
			panel.get_node("HP").text = "HP: %d/%d" % [u.hp, u.max_hp]
			panel.get_node("HPBar").value = float(u.hp) / u.max_hp * 100
			panel.modulate = Color(1, 1, 1, 0.3) if u.is_dead else Color(1, 1, 1, 1)

func _update_atb_bars():
	for i in range(player_units.size()):
		var bar = get_node_or_null("UI/ATBPanel/ATB_P%d/Bar" % (i + 1))
		var label = get_node_or_null("UI/ATBPanel/ATB_P%d/Label" % (i + 1))
		if bar and label:
			bar.value = player_units[i].atb
			label.text = player_units[i].unit_name
	for i in range(enemy_units.size()):
		var bar = get_node_or_null("UI/ATBPanel/ATB_E%d/Bar" % (i + 1))
		var label = get_node_or_null("UI/ATBPanel/ATB_E%d/Label" % (i + 1))
		if bar and label:
			bar.value = enemy_units[i].atb
			label.text = enemy_units[i].unit_name

func _on_unit_ready(unit: BattleUnit):
	_update_all_ui()
	# Highlight active unit
	var sprite = char_sprites.get(unit.unit_name)
	if sprite:
		var tween = create_tween().set_loops(3)
		tween.tween_property(sprite, "modulate", Color(1.3, 1.3, 1.0), 0.2)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	
	$UI/ActionPanel.visible = true
	$UI/ActionPanel/UnitLabel.text = "【%s 的回合】" % unit.unit_name
	$UI/TargetPanel.visible = false
	selected_skill = null
	selecting_target = false

	for i in range(3):
		var btn = $UI/ActionPanel/Skills.get_node_or_null("Skill%d" % (i + 1))
		if btn:
			if i < unit.skills.size():
				var sk = unit.skills[i]
				btn.text = "%s (MP:%d)" % [sk.skill_name, sk.mp_cost]
				btn.visible = true
				btn.disabled = unit.mp < sk.mp_cost
				if btn.pressed.is_connected(_on_skill_pressed):
					btn.pressed.disconnect(_on_skill_pressed)
				btn.pressed.connect(_on_skill_pressed.bind(i))
			else:
				btn.visible = false

	if $UI/ActionPanel/AttackBtn.pressed.is_connected(_on_attack):
		$UI/ActionPanel/AttackBtn.pressed.disconnect(_on_attack)
	$UI/ActionPanel/AttackBtn.pressed.connect(_on_attack)

func _on_attack():
	selected_skill = null
	_show_target_selection()

func _on_skill_pressed(idx: int):
	var unit = battle_manager.current_unit
	if idx < unit.skills.size():
		selected_skill = unit.skills[idx]
		if selected_skill.target_type == SkillData.TargetType.SELF:
			_play_heal_anim(unit.unit_name)
			battle_manager.execute_skill(unit, selected_skill, unit)
			$UI/ActionPanel.visible = false
			_update_all_ui()
		elif selected_skill.target_type == SkillData.TargetType.ALL_ENEMIES:
			var enemies = enemy_units.filter(func(u): return not u.is_dead)
			if not enemies.is_empty():
				for e in enemies:
					_play_skill_anim(unit.unit_name, e.unit_name)
				battle_manager.execute_skill(unit, selected_skill, enemies[0])
			$UI/ActionPanel.visible = false
			_update_all_ui()
			_check_defeated()
		else:
			_show_target_selection()

func _show_target_selection():
	$UI/ActionPanel.visible = false
	$UI/TargetPanel.visible = true
	selecting_target = true
	for child in $UI/TargetPanel/Targets.get_children():
		child.queue_free()
	var alive_enemies = enemy_units.filter(func(u): return not u.is_dead)
	for i in range(alive_enemies.size()):
		var btn = Button.new()
		btn.text = "%s (HP:%d/%d)" % [alive_enemies[i].unit_name, alive_enemies[i].hp, alive_enemies[i].max_hp]
		btn.custom_minimum_size = Vector2(250, 40)
		btn.pressed.connect(_on_target_selected.bind(alive_enemies[i]))
		$UI/TargetPanel/Targets.add_child(btn)

func _on_target_selected(target: BattleUnit):
	$UI/TargetPanel.visible = false
	selecting_target = false
	var unit = battle_manager.current_unit
	
	if selected_skill:
		_play_skill_anim(unit.unit_name, target.unit_name)
		battle_manager.execute_skill(unit, selected_skill, target)
	else:
		_play_attack_anim(unit.unit_name, target.unit_name)
		battle_manager.execute_attack(unit, target)
	_update_all_ui()
	_check_defeated()

func _check_defeated():
	for u in player_units + enemy_units:
		if u.is_dead and char_sprites.has(u.unit_name):
			var sprite = char_sprites[u.unit_name]
			if sprite.modulate.a > 0.5:
				_play_defeated_anim(u.unit_name)

func _on_battle_log(text: String):
	$UI/LogPanel/Log.text += text + "\n"
	await get_tree().process_frame
	$UI/LogPanel/Log.scroll_vertical = $UI/LogPanel/Log.get_v_scroll_bar().max_value
	_check_defeated()

func _on_battle_ended(won: bool):
	$UI/ActionPanel.visible = false
	$UI/TargetPanel.visible = false
	var result = $UI/ResultPanel
	result.visible = true
	result.get_node("ResultLabel").text = "🎉 战斗胜利！获得修为 +50" if won else "💀 道消身陨..."
	result.get_node("ReturnBtn").pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
