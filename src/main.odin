package main

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:/math/linalg"
import "core:strings"
import "core:/mem/virtual"


// constants
WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

SCORE_ANIM_DURATION :: 0.4

POINTS_TO_WIN :: 11

RED_COLOR :: rl.Color{255, 50, 0, 255}
BLUE_COLOR :: rl.Color{0, 50, 255, 255}

RED_SUBDUED_COLOR :: rl.Color{255, 50, 0, 180}
BLUE_SUBDUED_COLOR :: rl.Color{0, 50, 255, 180}

// game objects
player1: Player = {size={125, 15}, color=RED_COLOR}
player2: Player = {size={125, 15}, color=BLUE_COLOR}
ball : Ball = {size={15, 15}, color={255, 255, 255, 255}}

//game map, not an allocator :/
arena : Arena = {
	aabb={{0, 0}, {WINDOW_WIDTH, WINDOW_HEIGHT}},
}

gameplay_particle_system: ParticleSystem = {
	lifetime=1,
	particle_start_size={10, 10},
	emitting=false,
}

win_particle_system: ParticleSystem = {
	lifetime=4,
	particle_start_size={20, 20},
	emitting=false,
}

// globals
random : rand.Generator
player1_score_builder : strings.Builder
player2_score_builder : strings.Builder

paused := false

GameState :: enum {
	Intro,
	Playing,
	WinScreen,
}

game_state: GameState = .Intro

win_player: int = 0

win_particle_time: f64
intro_particle_time: f64

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "odin pong")
	rl.SetTargetFPS(60)

	random_state := rand.create(355)
	random = rand.default_random_generator(&random_state)

	// init_particles()
	player1_score_builder = strings.builder_make()
	player2_score_builder = strings.builder_make()

	restart()

	for !rl.WindowShouldClose() {
		delta := rl.GetFrameTime()

		input()
		tick(delta)

		rl.ClearBackground({0, 0, 0, 255})
		rl.BeginDrawing()
		draw(delta)
		rl.EndDrawing()
	}

	rl.CloseWindow()
}

input :: proc() {
	// player 1 input
	player1.input = {0, 0}
	{
		if rl.IsKeyDown(rl.KeyboardKey.A) {
			player1.input.x -= 1
		}
		if rl.IsKeyDown(rl.KeyboardKey.D) {
			player1.input.x += 1
		}
	}

	// player 2 input
	player2.input = {0, 0}
	{
		if rl.IsKeyDown(rl.KeyboardKey.LEFT) {
			player2.input.x -= 1
		}
		if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
			player2.input.x += 1
		}
	}

	switch game_state {
		case .Intro:
			key := rl.GetKeyPressed()
			if key != .KEY_NULL {
				game_state = .Playing
				gameplay_particle_system.emitting = true
			}
		case .Playing:
			if rl.IsKeyPressed(rl.KeyboardKey.P) {
				paused = !paused
			}
		case .WinScreen:
			if rl.IsKeyPressed(rl.KeyboardKey.R) {
				// need to restart stuff
				game_state = .Intro
				restart()
			}
	}
}

tick :: proc(delta: f32) {
	switch game_state {
		case .Intro:
			if rl.GetTime() - intro_particle_time > 0.1 {
				intro_particle_time = rl.GetTime()
	
				make_intro_particle :: proc(position: rl.Vector2) {
					if !win_particle_system.emitting {
						return
					}
					particle := make_particle(&win_particle_system)
					particle.color = {
						u8(255*rand.float32_range(0, 1)), 
						u8(255*rand.float32_range(0, 1)), 
						u8(255*rand.float32_range(0, 1)), 
						u8(255*rand.float32_range(0, 1)),
					}
					
					particle.position = position
					particle.size = win_particle_system.particle_start_size + 
						{rand.float32_range(-10, 10, random), rand.float32_range(-10, 10, random)}
	
					// do some randomness in movement and accel
					particle.velocity = {rand.float32_range(-200, 200, random), rand.float32_range(-20, 50, random)}
				
					particle.acceleration = {-10, 800}
					particle.life_remaining = win_particle_system.lifetime * rand.float32_range(0.9, 1.2, random)
				}
	
				make_intro_particle({
					rand.float32_range(0, WINDOW_WIDTH, random), 
					-WINDOW_HEIGHT * 0.1 + rand.float32_range(-10, 0, random),
				})
	
				make_intro_particle({
					rand.float32_range(0, WINDOW_WIDTH, random), 
					-WINDOW_HEIGHT * 0.1 + rand.float32_range(-10, 0, random),
				})
			}

		case .Playing:
			if paused {
				break
			}

			do_movement_player(&player1, delta)
			do_movement_player(&player2, delta)
			do_movement_ball(&ball, delta)
			
			do_collision_player_arena(&player1, &arena, delta)
			do_collision_player_arena(&player2, &arena, delta)
			
			do_collision_player_ball(&player1, &ball, delta)
			do_collision_player_ball(&player2, &ball, delta)
			
			do_collision_ball_arena(&ball, &arena, delta)
		
			if player1.points >= POINTS_TO_WIN {
				// player 1 wins
				paused = true
				win_player = 1
				gameplay_particle_system.emitting = false
				game_state = .WinScreen
			}
			if player2.points >= POINTS_TO_WIN {
				// player 2 wins
				paused = true
				win_player = 2
				gameplay_particle_system.emitting = false
				game_state = .WinScreen
			}
		case .WinScreen:
			if rl.GetTime() - win_particle_time > 0.01 {
				win_particle_time = rl.GetTime()
	
				make_win_particle :: proc(position: rl.Vector2) {
					if !win_particle_system.emitting {
						return
					}
					particle := make_particle(&win_particle_system)
					particle.color = {
						u8(255*rand.float32_range(0, 1)), 
						u8(255*rand.float32_range(0, 1)), 
						u8(255*rand.float32_range(0, 1)), 
						u8(255*rand.float32_range(0, 1)),
					}
					
					particle.position = position
					particle.size = win_particle_system.particle_start_size + 
						{rand.float32_range(-10, 10, random), rand.float32_range(-10, 10, random)}
	
					// do some randomness in movement and accel
					particle.velocity = {rand.float32_range(-200, 200, random), rand.float32_range(-900, -500, random)}
				
					particle.acceleration = {-10, 800}
					particle.life_remaining = win_particle_system.lifetime * rand.float32_range(0.9, 1.2, random)
				}
	
				make_win_particle({
					WINDOW_WIDTH * 0.2 + rand.float32_range(-10, 10, random), 
					WINDOW_HEIGHT * 0.8 + rand.float32_range(-10, 10, random),
				})
	
				make_win_particle({
					WINDOW_WIDTH * 0.8 + rand.float32_range(-10, 10, random), 
					WINDOW_HEIGHT * 0.8 + rand.float32_range(-10, 10, random),
				})
			}
	}

	do_update_particles(&gameplay_particle_system, delta)
	do_update_particles(&win_particle_system, delta)
}

format_score :: proc(score: int, builder: ^strings.Builder) -> string{
	strings.builder_reset(builder)
	if score < 10 {
		strings.write_string(builder, "00")
	} else if score < 100 {
		strings.write_string(builder, "0")
	}

	strings.write_int(builder, score)
	return strings.to_string(builder^)
}

draw :: proc(delta: f32) {
	do_draw(&player1)
	do_draw(&player2)
	do_draw(&ball)

	DEFAULT_OPACITY :: 64
	DEFAULT_SIZE :: 50

	time := rl.GetTime()
	
	size1 : i32 = DEFAULT_SIZE
	opacity1 : u8 = DEFAULT_OPACITY
	size2 : i32 = DEFAULT_SIZE
	opacity2 : u8 = DEFAULT_OPACITY

	if time - player1.score_time < SCORE_ANIM_DURATION {
		fraction := (time - player1.score_time) / SCORE_ANIM_DURATION
		fraction = math.sqrt(fraction)
		sine_transform := 1 + math.sin(fraction * math.PI)

		size1 = i32(sine_transform * DEFAULT_SIZE)
		opacity1 = u8(sine_transform * DEFAULT_OPACITY)
	}

	if time - player2.score_time < SCORE_ANIM_DURATION {
		fraction := (time - player2.score_time) / SCORE_ANIM_DURATION
		fraction = math.sqrt(fraction)
		sine_transform := 1 + math.sin(fraction * math.PI)
		
		size2 = i32(sine_transform * DEFAULT_SIZE)
		opacity2 = u8(sine_transform * DEFAULT_OPACITY)
	}

	// draw scores
	{
		player1_cstr : cstring = strings.unsafe_string_to_cstring(format_score(player1.points, &player1_score_builder))
		player1_color := RED_SUBDUED_COLOR
		player1_color.a = opacity1

		rl.DrawText(
			player1_cstr, 
			WINDOW_WIDTH * 0.5 - size1 * 2, 
			WINDOW_HEIGHT * 0.5 - size1 / 2, 
			size1, 
			player1_color,
		)	
	}

	rl.DrawText(
		"|", WINDOW_WIDTH * 0.5, 
		WINDOW_HEIGHT * 0.5 - 25, 
		50, 
		{255, 255, 255, 64},
	)

	{
		player2_cstr : cstring = strings.unsafe_string_to_cstring(format_score(player2.points, &player2_score_builder))
		player2_color := BLUE_SUBDUED_COLOR
		player2_color.a = opacity2

		rl.DrawText(
			player2_cstr, 
			WINDOW_WIDTH * 0.5 + size2 * 4 / 10, 
			WINDOW_HEIGHT * 0.5 - size2 / 2, 
			size2, 
			player2_color,
		)
	}

	if game_state == .Intro {
		// draw bg 
		rl.DrawRectangle(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, {25, 25, 25, 200})
		
		time := rl.GetTime()
		animation := math.abs(math.sin(5 * time))

		{
			AMPLITUDE :: 32
			rl.DrawText(
				strings.unsafe_string_to_cstring("Odin Pong!"), 
				WINDOW_WIDTH * 0.5 - 350 - i32(AMPLITUDE * animation * 0.5), 
				WINDOW_HEIGHT * 0.5 - 150 - i32(AMPLITUDE * animation * 0.5), 
				128 + i32(AMPLITUDE * animation), 
				{255, 255, 255, 255},
			)
		}

		{
			AMPLITUDE :: 0
			rl.DrawText(
				strings.unsafe_string_to_cstring("Press ANY key to start."), 
				WINDOW_WIDTH * 0.5 - 250 - i32(AMPLITUDE * animation * 0.5), 
				WINDOW_HEIGHT * 0.5 - 0 - i32(AMPLITUDE * animation * 0.5), 
				42 + i32(AMPLITUDE * animation), 
				{255, 255, 255, 200},
			)
		}

		rl.DrawText(
			strings.unsafe_string_to_cstring("Controls:\n\n\nA/D keys     - player 1\n\nArrow <-/->  - player 2"), 
			WINDOW_WIDTH * 0.5 - 250, 
			WINDOW_HEIGHT * 0.5 + 100, 
			22,
			{255, 255, 255, 200},
		)
	}

	if game_state == .Playing {
		if paused {
			rl.DrawText(
				strings.unsafe_string_to_cstring("Paused."), 
				WINDOW_WIDTH * 0.5 - 150, 
				WINDOW_HEIGHT * 0.5 - 150, 
				78, 
				{255, 255, 255, 255},
			)

			rl.DrawText(
				strings.unsafe_string_to_cstring("press P to unpause"), 
				WINDOW_WIDTH * 0.5 - 200, 
				WINDOW_HEIGHT * 0.5 + 60, 
				42, 
				{255, 255, 255, 255},
			)
		}
	}

	if game_state == .WinScreen {
		if win_player == 1 {
			rl.DrawRectangle(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, {255, 24, 24, 24})
			rl.DrawText(
				strings.unsafe_string_to_cstring("Ey yo, Red wins"), 
				WINDOW_WIDTH * 0.5 - 250, 
				WINDOW_HEIGHT * 0.5 - 150, 
				70, 
				RED_COLOR,
			)
		} else if win_player == 2 {
			rl.DrawRectangle(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, {24, 24, 255, 24})
			rl.DrawText(
				strings.unsafe_string_to_cstring("Ey yo, Blue wins"), 
				WINDOW_WIDTH * 0.5 - 250, 
				WINDOW_HEIGHT * 0.5 - 150, 
				70, 
				BLUE_COLOR,
			)
		}

		rl.DrawText(
			strings.unsafe_string_to_cstring("press R to restart"), 
			WINDOW_WIDTH * 0.5 - 150, 
			WINDOW_HEIGHT * 0.5 + 60, 
			32, 
			RED_SUBDUED_COLOR,
		)
	}

	do_draw_particles(&gameplay_particle_system)
	do_draw_particles(&win_particle_system)
}

restart :: proc() {
	player1.position = {WINDOW_WIDTH/2, WINDOW_HEIGHT * 0.1}
	player2.position = {WINDOW_WIDTH/2, WINDOW_HEIGHT * 0.9}
	player1.score_time = -100
	player1.points = 0
	player2.score_time = -100
	player2.points = 0
	win_particle_system.emitting = true

	ball.position = {WINDOW_WIDTH/2, WINDOW_HEIGHT/2}
	
	ball.velocity = {
		rand.float32_uniform(-0.05, 0.05, random),
		rand.float32_uniform(-1, 1, random),
	}

	ball.velocity = 500 * linalg.normalize0(ball.velocity)

	win_player = 0
	paused = false
}
