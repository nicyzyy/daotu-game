class_name CharacterRenderer
extends Node2D

## Procedural 2D character renderer with layered equipment and pose animations
## All characters drawn with code - consistent style, dynamic equipment display

enum Pose { IDLE, ATTACK, DEFEND, HIT, DEBUFF, DEFEATED }
enum CharType { SWORD_CULTIVATOR, DAN_CULTIVATOR, WOLF_MONSTER, SNAKE_MONSTER, GOLEM_MONSTER }

@export var char_type: CharType = CharType.SWORD_CULTIVATOR
@export var facing_left: bool = false
@export var char_scale: float = 1.0

var current_pose: Pose = Pose.IDLE
var idle_time: float = 0.0
var anim_progress: float = 0.0
var is_animating: bool = false
var flash_alpha: float = 0.0
var debuff_time: float = 0.0
var defeated_progress: float = 0.0

# Equipment colors (can be changed dynamically)
var robe_color: Color = Color(0.2, 0.3, 0.7)    # 服装
var armor_color: Color = Color(0.4, 0.4, 0.5)    # 护甲
var hair_color: Color = Color(0.15, 0.1, 0.1)    # 发色
var skin_color: Color = Color(0.95, 0.85, 0.7)   # 肤色
var weapon_color: Color = Color(0.7, 0.75, 0.8)  # 武器
var aura_color: Color = Color(0.3, 0.6, 1.0, 0.3) # 灵气光环

# Equipment flags
var has_hat: bool = true
var has_weapon: bool = true
var has_armor: bool = false
var has_aura: bool = false
var weapon_type: int = 0  # 0=sword, 1=staff, 2=fan

func _ready():
	_apply_char_preset()

func _apply_char_preset():
	match char_type:
		CharType.SWORD_CULTIVATOR:
			robe_color = Color(0.15, 0.25, 0.65)
			hair_color = Color(0.1, 0.08, 0.15)
			weapon_color = Color(0.75, 0.8, 0.9)
			aura_color = Color(0.3, 0.5, 1.0, 0.25)
			has_weapon = true
			has_hat = true
			has_aura = true
			weapon_type = 0
		CharType.DAN_CULTIVATOR:
			robe_color = Color(0.6, 0.2, 0.3)
			hair_color = Color(0.2, 0.1, 0.05)
			weapon_color = Color(0.8, 0.6, 0.3)
			aura_color = Color(0.8, 0.4, 0.2, 0.25)
			has_weapon = true
			has_hat = true
			has_aura = true
			weapon_type = 1
		CharType.WOLF_MONSTER:
			skin_color = Color(0.45, 0.35, 0.25)
			hair_color = Color(0.3, 0.25, 0.2)
			robe_color = Color(0.35, 0.3, 0.2)
			has_weapon = false
			has_hat = false
			has_armor = false
			has_aura = false
		CharType.SNAKE_MONSTER:
			skin_color = Color(0.3, 0.5, 0.3)
			hair_color = Color(0.2, 0.35, 0.15)
			robe_color = Color(0.25, 0.4, 0.2)
			aura_color = Color(0.4, 0.7, 0.2, 0.2)
			has_weapon = false
			has_hat = false
			has_aura = true
		CharType.GOLEM_MONSTER:
			skin_color = Color(0.5, 0.45, 0.4)
			hair_color = Color(0.4, 0.35, 0.3)
			robe_color = Color(0.45, 0.4, 0.35)
			has_weapon = false
			has_hat = false
			has_armor = true
			has_aura = false
			char_scale = 1.4

func _process(delta):
	idle_time += delta
	if current_pose == Pose.DEBUFF:
		debuff_time += delta
	if flash_alpha > 0:
		flash_alpha -= delta * 3.0
	queue_redraw()

func _draw():
	var s = char_scale
	var flip = -1.0 if facing_left else 1.0
	var breath = sin(idle_time * 2.0) * 2.0  # Breathing motion
	
	match current_pose:
		Pose.IDLE:
			_draw_character(s, flip, breath, 0, 0)
		Pose.ATTACK:
			var offset_x = flip * anim_progress * 30.0
			_draw_character(s, flip, 0, offset_x, 0)
			_draw_attack_effect(s, flip)
		Pose.DEFEND:
			_draw_character(s, flip, 0, 0, 0)
			_draw_shield(s)
		Pose.HIT:
			var shake = sin(idle_time * 40.0) * 5.0 * (1.0 - anim_progress)
			_draw_character(s, flip, 0, shake + flip * -15.0 * anim_progress, 0)
		Pose.DEBUFF:
			var shake = sin(debuff_time * 6.0) * 3.0
			_draw_character(s, flip, breath, shake, 0)
			_draw_debuff_effect(s)
		Pose.DEFEATED:
			_draw_defeated(s, flip)

func _draw_character(s: float, flip: float, breath: float, offset_x: float, offset_y: float):
	var cx = offset_x
	var cy = offset_y - breath
	
	# Aura (behind character)
	if has_aura:
		var aura_pulse = sin(idle_time * 1.5) * 0.15 + 0.85
		var ac = aura_color
		ac.a *= aura_pulse
		draw_circle(Vector2(cx, cy - 35 * s), 50 * s, ac)
	
	# Shadow
	draw_ellipse(Vector2(cx, 5 * s), Vector2(25 * s, 8 * s), Color(0, 0, 0, 0.3))
	
	# Legs
	var leg_color = robe_color.darkened(0.2)
	draw_rect(Rect2(cx - 10 * s, cy - 5 * s, 7 * s, 18 * s), leg_color)
	draw_rect(Rect2(cx + 3 * s, cy - 5 * s, 7 * s, 18 * s), leg_color)
	# Boots
	draw_rect(Rect2(cx - 11 * s, cy + 12 * s, 9 * s, 5 * s), Color(0.25, 0.2, 0.15))
	draw_rect(Rect2(cx + 2 * s, cy + 12 * s, 9 * s, 5 * s), Color(0.25, 0.2, 0.15))
	
	# Body / Robe
	var body_points = PackedVector2Array([
		Vector2(cx - 18 * s, cy - 5 * s),
		Vector2(cx - 20 * s, cy - 35 * s),
		Vector2(cx - 15 * s, cy - 50 * s),
		Vector2(cx + 15 * s, cy - 50 * s),
		Vector2(cx + 20 * s, cy - 35 * s),
		Vector2(cx + 18 * s, cy - 5 * s),
	])
	draw_colored_polygon(body_points, robe_color)
	
	# Robe trim
	var trim_color = robe_color.lightened(0.3)
	draw_line(Vector2(cx, cy - 50 * s), Vector2(cx, cy - 5 * s), trim_color, 2.0)
	
	# Armor overlay
	if has_armor:
		var armor_points = PackedVector2Array([
			Vector2(cx - 15 * s, cy - 20 * s),
			Vector2(cx - 17 * s, cy - 40 * s),
			Vector2(cx - 12 * s, cy - 48 * s),
			Vector2(cx + 12 * s, cy - 48 * s),
			Vector2(cx + 17 * s, cy - 40 * s),
			Vector2(cx + 15 * s, cy - 20 * s),
		])
		draw_colored_polygon(armor_points, armor_color)
	
	# Belt / sash
	draw_rect(Rect2(cx - 18 * s, cy - 20 * s, 36 * s, 4 * s), trim_color)
	
	# Arms
	var arm_y = cy - 40 * s
	draw_rect(Rect2(cx - 24 * s, arm_y, 8 * s, 25 * s), robe_color.darkened(0.1))
	draw_rect(Rect2(cx + 16 * s, arm_y, 8 * s, 25 * s), robe_color.darkened(0.1))
	# Hands
	draw_circle(Vector2(cx - 20 * s, arm_y + 25 * s), 4 * s, skin_color)
	draw_circle(Vector2(cx + 20 * s, arm_y + 25 * s), 4 * s, skin_color)
	
	# Head
	var head_cy = cy - 60 * s
	draw_circle(Vector2(cx, head_cy), 14 * s, skin_color)
	
	# Hair
	var hair_points = PackedVector2Array([
		Vector2(cx - 14 * s, head_cy),
		Vector2(cx - 15 * s, head_cy - 8 * s),
		Vector2(cx - 10 * s, head_cy - 15 * s),
		Vector2(cx + 10 * s, head_cy - 15 * s),
		Vector2(cx + 15 * s, head_cy - 8 * s),
		Vector2(cx + 14 * s, head_cy),
	])
	draw_colored_polygon(hair_points, hair_color)
	# Hair strands falling
	draw_line(Vector2(cx - 14 * s, head_cy), Vector2(cx - 16 * s, head_cy + 20 * s), hair_color, 3.0)
	draw_line(Vector2(cx + 14 * s, head_cy), Vector2(cx + 16 * s, head_cy + 20 * s), hair_color, 3.0)
	
	# Eyes
	var eye_y = head_cy - 2 * s
	draw_circle(Vector2(cx - 5 * s * flip, eye_y), 2.5 * s, Color.WHITE)
	draw_circle(Vector2(cx + 5 * s * flip, eye_y), 2.5 * s, Color.WHITE)
	draw_circle(Vector2(cx - 5 * s * flip, eye_y), 1.5 * s, Color(0.1, 0.1, 0.2))
	draw_circle(Vector2(cx + 5 * s * flip, eye_y), 1.5 * s, Color(0.1, 0.1, 0.2))
	
	# Hat / headpiece
	if has_hat:
		var hat_top = head_cy - 18 * s
		var hat_points = PackedVector2Array([
			Vector2(cx - 16 * s, head_cy - 10 * s),
			Vector2(cx - 5 * s, hat_top - 8 * s),
			Vector2(cx, hat_top - 12 * s),
			Vector2(cx + 5 * s, hat_top - 8 * s),
			Vector2(cx + 16 * s, head_cy - 10 * s),
		])
		draw_polyline(hat_points, trim_color, 3.0)
		# Crown ornament
		draw_circle(Vector2(cx, hat_top - 12 * s), 3 * s, Color(0.9, 0.8, 0.2))
	
	# Weapon
	if has_weapon:
		_draw_weapon(cx, cy, s, flip)
	
	# Hit flash overlay
	if flash_alpha > 0:
		var flash_col = Color(1, 0.2, 0.2, flash_alpha)
		draw_circle(Vector2(cx, cy - 35 * s), 30 * s, flash_col)

func _draw_weapon(cx: float, cy: float, s: float, flip: float):
	var wx = cx + 24 * s * flip
	var wy = cy - 20 * s
	match weapon_type:
		0:  # Sword
			var blade_end = Vector2(wx + 5 * s * flip, wy - 45 * s)
			draw_line(Vector2(wx, wy), blade_end, weapon_color, 3.0 * s)
			draw_line(Vector2(wx - 5 * s, wy), Vector2(wx + 5 * s, wy), Color(0.6, 0.5, 0.2), 2.0 * s)  # Guard
			# Blade glow
			draw_line(Vector2(wx + 1 * flip, wy - 5 * s), Vector2(wx + 3 * s * flip, wy - 40 * s), Color(0.8, 0.9, 1.0, 0.4), 2.0)
		1:  # Staff
			draw_line(Vector2(wx, wy + 10 * s), Vector2(wx, wy - 50 * s), Color(0.5, 0.35, 0.2), 3.0 * s)
			# Staff gem
			draw_circle(Vector2(wx, wy - 52 * s), 5 * s, Color(0.8, 0.3, 0.2))
			draw_circle(Vector2(wx, wy - 52 * s), 3 * s, Color(1.0, 0.5, 0.3, 0.8))
		2:  # Fan
			for i in range(5):
				var angle = deg_to_rad(-60 + i * 20)
				var fan_end = Vector2(wx + cos(angle) * 25 * s, wy - 15 * s + sin(angle) * 25 * s)
				draw_line(Vector2(wx, wy - 15 * s), fan_end, Color(0.9, 0.85, 0.7), 1.5)

func _draw_attack_effect(s: float, flip: float):
	# Slash effect
	var slash_alpha = 1.0 - anim_progress
	var slash_x = flip * (40 + anim_progress * 60) * s
	for i in range(3):
		var sc = Color(1.0, 0.9, 0.5, slash_alpha * (1.0 - i * 0.3))
		var arc_offset = i * 8.0 * s
		draw_arc(Vector2(slash_x + arc_offset * flip, -35 * s), 30 * s, deg_to_rad(-45), deg_to_rad(45), 12, sc, 3.0 - i)

func _draw_shield(s: float):
	# Defensive aura shield
	var shield_pulse = sin(idle_time * 3.0) * 0.1 + 0.9
	var shield_col = Color(0.3, 0.7, 1.0, 0.25 * shield_pulse)
	draw_arc(Vector2(0, -35 * s), 40 * s, 0, TAU, 32, shield_col, 3.0)
	draw_arc(Vector2(0, -35 * s), 35 * s, 0, TAU, 32, Color(0.5, 0.8, 1.0, 0.15 * shield_pulse), 2.0)

func _draw_debuff_effect(s: float):
	# Purple poison fog
	for i in range(6):
		var px = sin(debuff_time * 1.5 + i * 1.2) * 20 * s
		var py = -20 * s - i * 10 * s + sin(debuff_time * 2.0 + i) * 5
		var ps = (4 + sin(debuff_time + i) * 2) * s
		draw_circle(Vector2(px, py), ps, Color(0.5, 0.1, 0.6, 0.3))

func _draw_defeated(s: float, flip: float):
	# Fallen character - tilted and fading
	var alpha = max(0.2, 1.0 - defeated_progress * 0.6)
	modulate.a = alpha
	# Draw character rotated (lying down)
	var cx = defeated_progress * 20 * flip
	var cy = defeated_progress * 15
	
	# Simplified fallen body
	var body_col = robe_color
	body_col.a = alpha
	draw_rect(Rect2(cx - 25 * s, cy - 5 * s, 50 * s, 15 * s), body_col)
	draw_circle(Vector2(cx - 25 * s * flip, cy), 10 * s, skin_color * Color(1, 1, 1, alpha))
	# X eyes
	var ex = cx - 25 * s * flip
	var ey = cy - 2 * s
	draw_line(Vector2(ex - 3 * s, ey - 3 * s), Vector2(ex + 3 * s, ey + 3 * s), Color(0.2, 0.2, 0.2, alpha), 2.0)
	draw_line(Vector2(ex + 3 * s, ey - 3 * s), Vector2(ex - 3 * s, ey + 3 * s), Color(0.2, 0.2, 0.2, alpha), 2.0)

func draw_ellipse(center: Vector2, size: Vector2, color: Color):
	var points = PackedVector2Array()
	for i in range(24):
		var angle = TAU * i / 24.0
		points.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y))
	draw_colored_polygon(points, color)

# --- Animation triggers ---

func play_attack():
	current_pose = Pose.ATTACK
	anim_progress = 0.0
	is_animating = true
	var tween = create_tween()
	tween.tween_property(self, "anim_progress", 1.0, 0.5)
	tween.tween_callback(func(): 
		current_pose = Pose.IDLE
		is_animating = false
	)

func play_hit():
	current_pose = Pose.HIT
	anim_progress = 0.0
	flash_alpha = 1.0
	is_animating = true
	var tween = create_tween()
	tween.tween_property(self, "anim_progress", 1.0, 0.4)
	tween.tween_callback(func():
		current_pose = Pose.IDLE
		is_animating = false
	)

func play_defend():
	current_pose = Pose.DEFEND
	is_animating = true
	# Stay in defend for 1 second
	await get_tree().create_timer(1.0).timeout
	current_pose = Pose.IDLE
	is_animating = false

func play_debuff():
	current_pose = Pose.DEBUFF
	debuff_time = 0.0

func clear_debuff():
	current_pose = Pose.IDLE
	debuff_time = 0.0

func play_defeated():
	current_pose = Pose.DEFEATED
	defeated_progress = 0.0
	is_animating = true
	var tween = create_tween()
	tween.tween_property(self, "defeated_progress", 1.0, 0.8).set_ease(Tween.EASE_OUT)
