package main

import rl "vendor:raylib"

GameObject :: struct {
    size: rl.Vector2,
    color: rl.Color,

    position: rl.Vector2,
    velocity: rl.Vector2,
    acceleration: rl.Vector2,
}

Player :: struct {
    using _ : GameObject,
    input: rl.Vector2,
}

Ball :: struct {
    using _ : GameObject,
}

do_movement_player :: proc(player : ^Player, delta: f32) {
    movement := player.input
    movement.y *= -1

    playerAccelMagnitude :: 5000
    playerDampMagnitude :: 5

    player.acceleration = movement * playerAccelMagnitude
    player.velocity += player.acceleration * delta

    // damp player velocity
    damping := direction(-player.velocity) * magnitude(player.velocity) * playerDampMagnitude
    player.velocity += damping * delta

    player.position += player.velocity * delta
}

do_draw :: proc(go: ^GameObject) {
    using go

    rl.DrawRectangle(
        i32(position.x), 
        i32(position.y), 
        i32(size.x),
        i32(size.y), 
        color,
    )
}

do_collision_player :: proc(player : ^Player, delta : f32) {

}

do_movement_ball :: proc(ball : ^Ball, delta: f32) {

}

do_collision_ball :: proc(ball : ^Ball, delta : f32) {

}