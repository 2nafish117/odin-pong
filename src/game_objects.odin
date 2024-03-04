package main

import rl "vendor:raylib"
import "core:math"
import "core:fmt"

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

Arena :: struct {
    aabb: AABB 
}

get_aabb :: proc(go : ^GameObject) -> AABB {
    using go

    return {
        min = position - size * 0.5, 
        max = position + size * 0.5,
    }
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

do_movement_ball :: proc(ball : ^Ball, delta: f32) {
    ball.velocity += ball.acceleration * delta
    ball.position += ball.velocity * delta
}

do_collision_player_arena :: proc(player : ^Player, arena : ^Arena, delta : f32) {
    player.position.x = math.clamp(player.position.x, 45, arena.aabb.max.x - 45)
}

do_collision_ball_arena :: proc(ball : ^Ball, arena : ^Arena, delta : f32) {
    ball_aabb := get_aabb(ball)

    if ball_aabb.min.x < 0 {
        ball.velocity.x *= -1
    }
    
    if ball_aabb.min.y < 0 {
        ball.velocity.y *= -1
    }
    
    if ball_aabb.max.x > arena.aabb.max.x {
        ball.velocity.x *= -1
    }
    
    if ball_aabb.max.y > arena.aabb.max.y {
        ball.velocity.y *= -1
    }
}

is_aabb_intersecting :: proc(a, b: AABB) -> bool {
    return a.min.x <= b.max.x &&
        a.max.x >= b.min.x &&
        a.min.y <= b.max.y &&
        a.max.y >= b.min.y
}

do_collision_player_ball :: proc(player : ^Player, ball : ^Ball, delta: f32) {
    player_aabb := get_aabb(player)
    ball_aabb := get_aabb(ball)

    ret := is_aabb_intersecting(player_aabb, ball_aabb)
    if ret {
        ball.velocity.y *= -1
        ball.velocity.x += 0.1 * player.velocity.x
    }
}

do_draw :: proc(go: ^GameObject) {
    using go

    rl.DrawRectangle(
        i32(position.x - go.size.x * 0.5), 
        i32(position.y - go.size.y * 0.5), 
        i32(size.x),
        i32(size.y), 
        color,
    )
}