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
        // if rl.IsKeyDown(rl.KeyboardKey.W) {
        //     player1.input.y += 1
        // }
        if rl.IsKeyDown(rl.KeyboardKey.A) {
            player1.input.x -= 1
        }
        // if rl.IsKeyDown(rl.KeyboardKey.S) {
        //     player1.input.y -= 1
        // }
        if rl.IsKeyDown(rl.KeyboardKey.D) {
            player1.input.x += 1
        }
    }
    // fmt.print(player1)

    // player 2 input
    player2.input = {0, 0}
    {
        // if rl.IsKeyDown(rl.KeyboardKey.UP) {
        //     player2.input.y += 1
        // }
        if rl.IsKeyDown(rl.KeyboardKey.LEFT) {
            player2.input.x -= 1
        }
        // if rl.IsKeyDown(rl.KeyboardKey.DOWN) {
        //     player2.input.y -= 1
        // }
        if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
            player2.input.x += 1
        }
    }
}

tick :: proc(delta: f32) {
    do_movement_player(&player1, delta)
    do_movement_player(&player2, delta)
    do_movement_ball(&ball, delta)
    
    do_collision_player_arena(&player1, &arena, delta)
    do_collision_player_arena(&player2, &arena, delta)
    
    do_collision_player_ball(&player1, &ball, delta)
    do_collision_player_ball(&player2, &ball, delta)
    
    do_collision_ball_arena(&ball, &arena, delta)
    
    do_update_particles(delta)
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

draw :: proc() {
    do_draw(&player1)
    do_draw(&player2)
    do_draw(&ball)

    for &p in particles {
        // fmt.print("yello\n")
        do_draw(&p)
    }

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
}

// constants
windowWidth :: 1280
windowHeight :: 720

scoreAnimDuration :: 0.4

// game objects
player1: Player = {size={125, 15}, color={255, 0, 0, 255}}
player2: Player = {size={125, 15}, color={0, 0, 255, 255}}
ball : Ball = {size={10, 10}, color={255, 255, 255, 255}}
arena : Arena = {
    aabb={{0, 0}, {windowWidth, windowHeight}},
}

// globals
random : rand.Rand
player1_score_builder : strings.Builder
player2_score_builder : strings.Builder

round_start :: proc() {
    player1.position = {windowWidth/2, windowHeight * 0.1}
    player2.position = {windowWidth/2, windowHeight * 0.9}
    player1.score_time = -100
    player2.score_time = -100
    
    ball.position = {windowWidth/2, windowHeight/2}
    
    ball.velocity = {
        rand.float32_uniform(-0.05, 0.05, &random),
        rand.float32_uniform(-1, 1, &random),
    }

    ball.velocity = 500 * linalg.normalize0(ball.velocity)
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
        input()

        tick(rl.GetFrameTime())

        rl.ClearBackground({0, 0, 0, 255})
        rl.BeginDrawing()
        draw()
        rl.EndDrawing()
    }

    rl.CloseWindow()
}