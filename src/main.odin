package main

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:math/rand"


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
}

draw :: proc() {
    do_draw(&player1)
    do_draw(&player2)
    do_draw(&ball)
}

// constants
windowWidth :: 1280
windowHeight :: 720

// game objects
player1: Player = {size={75, 10}, color={255, 0, 0, 255}}
player2: Player = {size={75, 10}, color={0, 0, 255, 255}}
ball : Ball = {size={10, 10}, color={255, 255, 255, 255}}
arena : Arena = {
    aabb={{0, 0}, {windowWidth, windowHeight}},
}
random : rand.Rand


round_start :: proc() {
    player1.position = {windowWidth/2, windowHeight * 0.1}
    player2.position = {windowWidth/2, windowHeight * 0.9}
    ball.position = {windowWidth/2, windowHeight/2}
    
    ball.velocity = {
        rand.float32_uniform(-0.05, 0.05, &random),
        rand.float32_uniform(-1, 1, &random),
    }

    ball.velocity = 100 * direction(ball.velocity)
}

main :: proc() {
    rl.InitWindow(windowWidth, windowHeight, "odin pong")
    rl.SetTargetFPS(60)
    random = rand.create(355)

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