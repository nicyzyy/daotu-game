class_name BattleBackground
extends Node2D

## Procedural xianxia battle background - mountains, mist, spiritual energy

var time: float = 0.0
var particles: Array = []  # Floating spiritual particles

func _ready():
	# Generate floating particles
	for i in range(30):
		particles.append({
			"x": randf_range(0, 1280),
			"y": randf_range(100, 600),
			"speed": randf_range(10, 30),
			"size": randf_range(1.5, 4.0),
			"phase": randf() * TAU,
			"color_idx": randi() % 3,
		})

func _process(delta):
	time += delta
	queue_redraw()

func _draw():
	# Sky gradient (dark mystical)
	_draw_sky()
	# Far mountains
	_draw_mountains(350, Color(0.12, 0.15, 0.25, 0.6), 0.3, 80)
	_draw_mountains(400, Color(0.1, 0.18, 0.22, 0.7), 0.5, 100)
	# Mist layer
	_draw_mist(380, 0.15)
	# Near mountains
	_draw_mountains(480, Color(0.08, 0.12, 0.15, 0.85), 0.8, 120)
	# Battle platform
	_draw_platform()
	# Floating particles (spiritual energy)
	_draw_particles()
	# Bottom mist
	_draw_mist(620, 0.2)

func _draw_sky():
	# Top: deep navy → middle: dark teal → bottom: misty
	var h = 720
	var steps = 20
	for i in range(steps):
		var t = float(i) / steps
		var c: Color
		if t < 0.5:
			c = Color(0.04, 0.05, 0.15).lerp(Color(0.06, 0.1, 0.2), t * 2)
		else:
			c = Color(0.06, 0.1, 0.2).lerp(Color(0.1, 0.15, 0.2), (t - 0.5) * 2)
		var y = h * t
		var sh = h / steps + 1
		draw_rect(Rect2(0, y, 1280, sh), c)
	
	# Moon
	draw_circle(Vector2(200, 100), 35, Color(0.9, 0.9, 0.8, 0.3))
	draw_circle(Vector2(200, 100), 30, Color(0.95, 0.95, 0.85, 0.15))
	
	# Stars
	for i in range(15):
		var sx = hash(i * 7) % 1280
		var sy = hash(i * 13) % 300
		var sa = sin(time * 1.5 + i) * 0.3 + 0.5
		draw_circle(Vector2(sx, sy), 1.5, Color(1, 1, 0.9, sa))

func _draw_mountains(base_y: float, color: Color, scale: float, height: float):
	var points = PackedVector2Array()
	points.append(Vector2(0, 720))
	
	for x in range(0, 1300, 20):
		var y = base_y - abs(sin(x * 0.005 * scale + scale * 3)) * height
		y -= abs(sin(x * 0.012 * scale + 1.5)) * height * 0.5
		y += sin(x * 0.003 + time * 0.1 * scale) * 5  # Slight wind movement
		points.append(Vector2(x, y))
	
	points.append(Vector2(1280, 720))
	draw_colored_polygon(points, color)

func _draw_platform():
	# Stone battle platform
	var platform_color = Color(0.18, 0.16, 0.14)
	var highlight = Color(0.25, 0.22, 0.2)
	
	# Main platform surface
	var platform = PackedVector2Array([
		Vector2(150, 550),
		Vector2(200, 520),
		Vector2(1080, 520),
		Vector2(1130, 550),
		Vector2(1130, 590),
		Vector2(1080, 610),
		Vector2(200, 610),
		Vector2(150, 590),
	])
	draw_colored_polygon(platform, platform_color)
	
	# Platform top edge highlight
	draw_line(Vector2(200, 520), Vector2(1080, 520), highlight, 2.0)
	draw_line(Vector2(150, 550), Vector2(200, 520), highlight, 2.0)
	draw_line(Vector2(1080, 520), Vector2(1130, 550), highlight, 2.0)
	
	# Rune circle on platform
	var cx = 640.0
	var cy = 560.0
	var rune_alpha = sin(time * 0.8) * 0.15 + 0.2
	draw_arc(Vector2(cx, cy), 180, 0, TAU, 48, Color(0.3, 0.6, 0.9, rune_alpha), 1.5)
	draw_arc(Vector2(cx, cy), 150, 0, TAU, 48, Color(0.4, 0.7, 1.0, rune_alpha * 0.7), 1.0)
	
	# Rune symbols (simple geometric)
	for i in range(8):
		var angle = TAU * i / 8.0 + time * 0.1
		var rx = cx + cos(angle) * 165
		var ry = cy + sin(angle) * 25  # Perspective squash
		draw_circle(Vector2(rx, ry), 3, Color(0.5, 0.8, 1.0, rune_alpha))

func _draw_mist(base_y: float, alpha: float):
	for i in range(8):
		var mx = sin(time * 0.3 + i * 1.5) * 100 + i * 180
		var my = base_y + sin(time * 0.5 + i) * 10
		var ms = 80 + sin(time * 0.2 + i * 0.7) * 20
		draw_circle(Vector2(mx, my), ms, Color(0.6, 0.7, 0.8, alpha * 0.3))

func _draw_particles():
	var colors = [
		Color(0.4, 0.7, 1.0),  # Blue spiritual
		Color(0.3, 0.9, 0.5),  # Green life
		Color(0.9, 0.7, 0.3),  # Golden
	]
	
	for p in particles:
		p["x"] += p["speed"] * get_process_delta_time() * 0.5
		p["y"] += sin(time * 1.5 + p["phase"]) * 0.3
		
		if p["x"] > 1300:
			p["x"] = -20
		
		var c = colors[p["color_idx"]]
		var a = sin(time * 2.0 + p["phase"]) * 0.3 + 0.5
		c.a = a
		draw_circle(Vector2(p["x"], p["y"]), p["size"], c)
		# Glow
		c.a = a * 0.3
		draw_circle(Vector2(p["x"], p["y"]), p["size"] * 2.5, c)
