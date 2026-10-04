extends Node2D

# ==========================================
# BREAKOUT - GAME 3/20
# Made with Godot Engine
# ==========================================

# Screen
const SCREEN_WIDTH = 900
const SCREEN_HEIGHT = 650

# Paddle
const PADDLE_WIDTH = 120.0
const PADDLE_HEIGHT = 18.0
const PADDLE_SPEED = 650.0

# Ball
const BALL_RADIUS = 10.0
const INITIAL_BALL_SPEED = 400.0

# Bricks
const BRICK_ROWS = 5
const BRICK_COLUMNS = 10
const BRICK_WIDTH = 70.0
const BRICK_HEIGHT = 25.0
const BRICK_GAP = 8.0

# Game
const STARTING_LIVES = 3
const WINNING_BONUS = 100

var paddle_position = Vector2(
	SCREEN_WIDTH / 2.0,
	SCREEN_HEIGHT - 55.0
)

var ball_position = Vector2(
	SCREEN_WIDTH / 2.0,
	SCREEN_HEIGHT - 100.0
)

var ball_velocity = Vector2(300, -300)

var paddle_rect: Rect2
var bricks: Array[Rect2] = []

var score = 0
var lives = STARTING_LIVES

var ball_speed = INITIAL_BALL_SPEED

var game_over = false
var game_won = false

var waiting_to_start = true


func _ready():
	# Create bricks
	create_bricks()

	# Start the ball
	reset_ball()

	queue_redraw()


func create_bricks():
	bricks.clear()

	var total_width = (
		BRICK_COLUMNS * BRICK_WIDTH
		+ (BRICK_COLUMNS - 1) * BRICK_GAP
	)

	var start_x = (SCREEN_WIDTH - total_width) / 2.0
	var start_y = 80.0

	for row in range(BRICK_ROWS):
		for column in range(BRICK_COLUMNS):

			var x = start_x + column * (BRICK_WIDTH + BRICK_GAP)
			var y = start_y + row * (BRICK_HEIGHT + BRICK_GAP)

			var brick = Rect2(
				x,
				y,
				BRICK_WIDTH,
				BRICK_HEIGHT
			)

			bricks.append(brick)


func reset_ball():
	ball_position = Vector2(
		SCREEN_WIDTH / 2.0,
		SCREEN_HEIGHT - 100.0
	)

	ball_speed = INITIAL_BALL_SPEED

	# Ball starts moving upward
	var direction = Vector2(
		randf_range(-0.7, 0.7),
		-1
	).normalized()

	ball_velocity = direction * ball_speed

	waiting_to_start = false


func restart_game():
	score = 0
	lives = STARTING_LIVES

	game_over = false
	game_won = false

	paddle_position = Vector2(
		SCREEN_WIDTH / 2.0,
		SCREEN_HEIGHT - 55.0
	)

	create_bricks()
	reset_ball()

	queue_redraw()


func _process(delta):

	# Restart
	if Input.is_key_pressed(KEY_R):
		if game_over or game_won:
			restart_game()
			return

	# Don't update gameplay after game ends
	if game_over or game_won:
		queue_redraw()
		return

	# ==========================================
	# PADDLE MOVEMENT
	# ==========================================

	var paddle_direction = 0.0

	if Input.is_key_pressed(KEY_LEFT):
		paddle_direction -= 1.0

	if Input.is_key_pressed(KEY_RIGHT):
		paddle_direction += 1.0

	paddle_position.x += paddle_direction * PADDLE_SPEED * delta

	# Keep paddle inside screen
	paddle_position.x = clamp(
		paddle_position.x,
		PADDLE_WIDTH / 2.0,
		SCREEN_WIDTH - PADDLE_WIDTH / 2.0
	)

	paddle_rect = Rect2(
		paddle_position.x - PADDLE_WIDTH / 2.0,
		paddle_position.y - PADDLE_HEIGHT / 2.0,
		PADDLE_WIDTH,
		PADDLE_HEIGHT
	)

	# ==========================================
	# BALL MOVEMENT
	# ==========================================

	ball_position += ball_velocity * delta

	# ==========================================
	# LEFT WALL
	# ==========================================

	if ball_position.x - BALL_RADIUS <= 0:
		ball_position.x = BALL_RADIUS
		ball_velocity.x = abs(ball_velocity.x)

	# ==========================================
	# RIGHT WALL
	# ==========================================

	if ball_position.x + BALL_RADIUS >= SCREEN_WIDTH:
		ball_position.x = SCREEN_WIDTH - BALL_RADIUS
		ball_velocity.x = -abs(ball_velocity.x)

	# ==========================================
	# TOP WALL / CEILING
	# ==========================================

	if ball_position.y - BALL_RADIUS <= 0:
		ball_position.y = BALL_RADIUS
		ball_velocity.y = abs(ball_velocity.y)

	# ==========================================
	# PADDLE COLLISION
	# ==========================================

	if ball_velocity.y > 0:

		var ball_rect = Rect2(
			ball_position.x - BALL_RADIUS,
			ball_position.y - BALL_RADIUS,
			BALL_RADIUS * 2,
			BALL_RADIUS * 2
		)

		if ball_rect.intersects(paddle_rect):

			ball_position.y = paddle_rect.position.y - BALL_RADIUS

			# Calculate bounce angle depending on where
			# the ball hits the paddle
			var hit_position = (
				ball_position.x - paddle_position.x
			) / (PADDLE_WIDTH / 2.0)

			hit_position = clamp(hit_position, -1.0, 1.0)

			var new_direction = Vector2(
				hit_position,
				-1
			).normalized()

			ball_velocity = new_direction * ball_velocity.length()

	# ==========================================
	# BRICK COLLISIONS
	# ==========================================

	var ball_rect = Rect2(
		ball_position.x - BALL_RADIUS,
		ball_position.y - BALL_RADIUS,
		BALL_RADIUS * 2,
		BALL_RADIUS * 2
	)

	for i in range(bricks.size() - 1, -1, -1):

		var brick = bricks[i]

		if ball_rect.intersects(brick):

			# Remove brick
			bricks.remove_at(i)

			# Increase score
			score += 10

			# Increase ball speed
			ball_speed += 20

			var direction = ball_velocity.normalized()
			ball_velocity = direction * ball_speed

			# Determine bounce direction
			var brick_center = brick.position + brick.size / 2.0

			var dx = ball_position.x - brick_center.x
			var dy = ball_position.y - brick_center.y

			if abs(dx) > abs(dy):
				ball_velocity.x *= -1
			else:
				ball_velocity.y *= -1

			break

	# ==========================================
	# BALL FALLS BELOW SCREEN
	# ==========================================

	if ball_position.y - BALL_RADIUS > SCREEN_HEIGHT:

		lives -= 1

		if lives <= 0:

			game_over = true

		else:

			reset_ball()

	# ==========================================
	# WIN CONDITION
	# ==========================================

	if bricks.is_empty() and not game_over:

		game_won = true
		score += WINNING_BONUS

	queue_redraw()


func _draw():

	# ==========================================
	# BACKGROUND
	# ==========================================

	draw_rect(
		Rect2(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT),
		Color(0.03, 0.03, 0.08)
	)

	# ==========================================
	# BORDER
	# ==========================================

	var border_color = Color(0.9, 0.9, 0.9)

	draw_line(
		Vector2(0, 0),
		Vector2(SCREEN_WIDTH, 0),
		border_color,
		5
	)

	draw_line(
		Vector2(0, 0),
		Vector2(0, SCREEN_HEIGHT),
		border_color,
		5
	)

	draw_line(
		Vector2(SCREEN_WIDTH, 0),
		Vector2(SCREEN_WIDTH, SCREEN_HEIGHT),
		border_color,
		5
	)

	# ==========================================
	# BRICKS
	# ==========================================

	for i in range(bricks.size()):

		var brick = bricks[i]

		var row = i % BRICK_ROWS

		var brick_color = Color(
			0.2 + row * 0.12,
			0.55,
			0.9 - row * 0.08
		)

		draw_rect(
			brick,
			brick_color
		)

		# Brick outline
		draw_rect(
			brick,
			Color(1, 1, 1, 0.25),
			false,
			2
		)

	# ==========================================
	# PADDLE
	# ==========================================

	draw_rect(
		paddle_rect,
		Color(0.95, 0.95, 0.95)
	)

	# ==========================================
	# BALL
	# ==========================================

	draw_circle(
		ball_position,
		BALL_RADIUS,
		Color(1, 1, 1)
	)

	# ==========================================
	# SCORE
	# ==========================================

	var font = ThemeDB.fallback_font

	draw_string(
		font,
		Vector2(35, 40),
		"SCORE: " + str(score),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		26,
		Color(1, 1, 1)
	)

	# ==========================================
	# LIVES
	# ==========================================

	draw_string(
		font,
		Vector2(SCREEN_WIDTH - 190, 40),
		"LIVES: " + str(lives),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		26,
		Color(1, 1, 1)
	)

	# ==========================================
	# CONTROLS
	# ==========================================

	draw_string(
		font,
		Vector2(25, SCREEN_HEIGHT - 20),
		"← / →  MOVE PADDLE",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		Color(0.8, 0.8, 0.8)
	)

	# ==========================================
	# GAME OVER
	# ==========================================

	if game_over:

		draw_string(
			font,
			Vector2(
				SCREEN_WIDTH / 2.0 - 130,
				SCREEN_HEIGHT / 2.0 - 20
			),
			"GAME OVER!",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			42,
			Color(1, 0.4, 0.4)
		)

		draw_string(
			font,
			Vector2(
				SCREEN_WIDTH / 2.0 - 130,
				SCREEN_HEIGHT / 2.0 + 25
			),
			"PRESS R TO RESTART",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			22,
			Color(1, 1, 1)
		)

	# ==========================================
	# WIN SCREEN
	# ==========================================

	if game_won:

		draw_string(
			font,
			Vector2(
				SCREEN_WIDTH / 2.0 - 125,
				SCREEN_HEIGHT / 2.0 - 20
			),
			"YOU WIN!",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			42,
			Color(0.4, 1, 0.5)
		)

		draw_string(
			font,
			Vector2(
				SCREEN_WIDTH / 2.0 - 130,
				SCREEN_HEIGHT / 2.0 + 25
			),
			"PRESS R TO RESTART",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			22,
			Color(1, 1, 1)
		)
