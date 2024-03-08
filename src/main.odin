package main

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:/math/linalg"
import "core:strings"
import "core:/mem/virtual"

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

    if rl.IsKeyPressed(rl.KeyboardKey.P) && win_player == 0 {
        paused = !paused
    }
    
    if rl.IsKeyPressed(rl.KeyboardKey.R) && win_player != 0 {
        // need to restart stuff
        round_start()
    }
}

tick :: proc(delta: f32) {
    if !paused {
        do_movement_player(&player1, delta)
        do_movement_player(&player2, delta)
        do_movement_ball(&ball, delta)
        
        do_collision_player_arena(&player1, &arena, delta)
        do_collision_player_arena(&player2, &arena, delta)
        
        do_collision_player_ball(&player1, &ball, delta)
        do_collision_player_ball(&player2, &ball, delta)
        
        do_collision_ball_arena(&ball, &arena, delta)
    
        do_update_particles(&gameplay_particle_system, delta)
    
        if player1.points >= pointsToWin {
            // player 1 wins
            paused = true
            win_player = 1
        }
        if player2.points >= pointsToWin {
            // player 2 wins
            paused = true
            win_player = 2
        }
    } else if win_player != 0{
        if rl.GetTime() - win_particle_time > 0.01 {
            win_particle_time = rl.GetTime()

            make_win_particle :: proc(position: rl.Vector2) {
                particle := make_particle(&win_particle_system)
                particle.color = {
                    u8(255*rand.float32_range(0, 1)), 
                    u8(255*rand.float32_range(0, 1)), 
                    u8(255*rand.float32_range(0, 1)), 
                    u8(255*rand.float32_range(0, 1)),
                }
                
                particle.position = position
                particle.size = win_particle_system.particle_start_size + 
                    {rand.float32_range(-10, 10, &random), rand.float32_range(-10, 10, &random)}

                // do some randomness in movement and accel
                particle.velocity = {rand.float32_range(-200, 200, &random), rand.float32_range(-900, -500, &random)}
            
                particle.acceleration = {-10, 800}
                particle.life_remaining = win_particle_system.lifetime * rand.float32_range(0.9, 1.2, &random)
            }

            make_win_particle({
                windowWidth * 0.2 + rand.float32_range(-10, 10, &random), 
                windowHeight * 0.8 + rand.float32_range(-10, 10, &random),
            })

            make_win_particle({
                windowWidth * 0.8 + rand.float32_range(-10, 10, &random), 
                windowHeight * 0.8 + rand.float32_range(-10, 10, &random),
            })
        }

        do_update_particles(&win_particle_system, delta)
    }
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

    do_draw_particles(&gameplay_particle_system)
    do_draw_particles(&win_particle_system)

    defaultOpacity :: 64
    defaultSize :: 50

    time := rl.GetTime()
    
    size1 : i32 = defaultSize
    opacity1 : u8 = defaultOpacity
    size2 : i32 = defaultSize
    opacity2 : u8 = defaultOpacity

    if time - player1.score_time < scoreAnimDuration {
        fraction := (time - player1.score_time) / scoreAnimDuration
        fraction = math.sqrt(fraction)
        sine_transform := 1 + math.sin(fraction * math.PI)

        size1 = i32(sine_transform * defaultSize)
        opacity1 = u8(sine_transform * defaultOpacity)
    }

    if time - player2.score_time < scoreAnimDuration {
        fraction := (time - player2.score_time) / scoreAnimDuration
        fraction = math.sqrt(fraction)
        sine_transform := 1 + math.sin(fraction * math.PI)
        
        size2 = i32(sine_transform * defaultSize)
        opacity2 = u8(sine_transform * defaultOpacity)
    }

    // draw scores
    player1_cstr : cstring = strings.unsafe_string_to_cstring(format_score(player1.points, &player1_score_builder))
    rl.DrawText(
        player1_cstr, 
        windowWidth * 0.5 - size1 * 2, 
        windowHeight * 0.5 - size1 / 2, 
        size1, 
        {255, 0, 0, opacity1},
    )
    
    rl.DrawText(
        "|", windowWidth * 0.5, 
        windowHeight * 0.5 - 25, 
        50, 
        {255, 255, 255, 64},
    )

    player2_cstr : cstring = strings.unsafe_string_to_cstring(format_score(player2.points, &player2_score_builder))
    rl.DrawText(
        player2_cstr, 
        windowWidth * 0.5 + size2 * 4 / 10, 
        windowHeight * 0.5 - size2 / 2, 
        size2, 
        {0, 0, 255, opacity2},
    )

    if paused {
        if win_player == 1 {
            rl.DrawRectangle(0, 0, windowWidth, windowHeight, {255, 24, 24, 24})
            do_draw_particles(&win_particle_system)
            rl.DrawText(
                strings.unsafe_string_to_cstring("Ey yo, Red wins"), 
                windowWidth * 0.5 - 250, 
                windowHeight * 0.5 - 150, 
                70, 
                {255, 0, 0, 255},
            )
        } else if win_player == 2 {
            rl.DrawRectangle(0, 0, windowWidth, windowHeight, {24, 24, 255, 24})
            do_draw_particles(&win_particle_system)
            rl.DrawText(
                strings.unsafe_string_to_cstring("Ey yo, Blue wins"), 
                windowWidth * 0.5 - 250, 
                windowHeight * 0.5 - 150, 
                70, 
                {0, 0, 255, 255},
            )
        }
    }
}

// constants
windowWidth :: 1280
windowHeight :: 720

scoreAnimDuration :: 0.4

pointsToWin :: 11

// game objects
player1: Player = {size={125, 15}, color={255, 0, 0, 255}}
player2: Player = {size={125, 15}, color={0, 0, 255, 255}}
ball : Ball = {size={15, 15}, color={255, 255, 255, 255}}
arena : Arena = {
    aabb={{0, 0}, {windowWidth, windowHeight}},
}
gameplay_particle_system: ParticleSystem = {
    lifetime=1,
    particle_start_size={10, 10},
}
win_particle_system: ParticleSystem = {
    lifetime=4,
    particle_start_size={20, 20},
}

// globals
random : rand.Rand
player1_score_builder : strings.Builder
player2_score_builder : strings.Builder
paused := false
win_player: int = 0
win_particle_time: f64

round_start :: proc() {
    player1.position = {windowWidth/2, windowHeight * 0.1}
    player2.position = {windowWidth/2, windowHeight * 0.9}
    player1.score_time = -100
    player1.points = 0
    player2.score_time = -100
    player2.points = 0

    ball.position = {windowWidth/2, windowHeight/2}
    
    ball.velocity = {
        rand.float32_uniform(-0.05, 0.05, &random),
        rand.float32_uniform(-1, 1, &random),
    }

    ball.velocity = 500 * linalg.normalize0(ball.velocity)

    win_player = 0
    paused = false

    gameplay_particle_system = {
        lifetime=1,
        particle_start_size={10, 10},
    }
    win_particle_system = {
        lifetime=4,
        particle_start_size={20, 20},
    }
}

main :: proc() {
    rl.InitWindow(windowWidth, windowHeight, "odin pong")
    rl.SetTargetFPS(60)
    random = rand.create(355)
    
    // init_particles()
    player1_score_builder = strings.builder_make()
    player2_score_builder = strings.builder_make()

    round_start()

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