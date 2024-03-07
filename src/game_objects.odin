package main

import rl "vendor:raylib"
import "core:math"
import "core:fmt"
import "core:mem"
import "core:math/linalg"
import "core:math/rand"

GameObject :: struct {
    size: rl.Vector2,
    color: rl.Color,

    position: rl.Vector2,
    velocity: rl.Vector2,
    acceleration: rl.Vector2,
}

Player :: struct {
    using go : GameObject,
    input: rl.Vector2,
    points: int,
    score_time: f64,
    particle_time: f64
}

Ball :: struct {
    using go : GameObject,
    particle_time: f64
}

Particle :: struct {
    using go : GameObject,
    lifetime : f32,
    life_remaining: f32,
}

Arena :: struct {
    aabb: AABB 
}

AABB :: struct {
    min: rl.Vector2,
    max: rl.Vector2,
}

get_aabb :: proc(go : ^GameObject) -> AABB {
    using go

    return {
        min = position - size * 0.5, 
        max = position + size * 0.5,
    }
}

do_emit_particles :: proc(go : ^GameObject) {
    using go
    particle := make_particle()
    particle.color = color //* rand.float32_range(0.6, 1, &random)
    particle.position = position + {rand.float32_range(-10, 10, &random), rand.float32_range(-10, 10, &random)}
    particle.size = particleStartSize + {rand.float32_range(-3, 3, &random), rand.float32_range(-3, 3, &random)}
    // do some randomness in movement and accel
    particle.velocity = rand.float32_range(0.2, 0.5, &random) * go.velocity + 
        rand.float32_range(0.1, 0.2, &random) * go.velocity.yx

    particle.lifetime = 1
    // particle.acceleration = 100 * {0, 0}
    particle.life_remaining = particle.lifetime
}

do_movement_player :: proc(player : ^Player, delta: f32) {
    movement := player.input
    movement.y *= -1

    playerAccelMagnitude :: 5000
    playerDampMagnitude :: 5

    player.acceleration = movement * playerAccelMagnitude
    player.velocity += player.acceleration * delta

    // damp player velocity
    damping := linalg.normalize0(-player.velocity) * linalg.abs(player.velocity) * playerDampMagnitude
    player.velocity += damping * delta

    player.position += player.velocity * delta

    if rl.GetTime() - player.particle_time > 0.1 {
        player.particle_time = rl.GetTime()
        do_emit_particles(player)
    }
}

do_movement_ball :: proc(ball : ^Ball, delta: f32) {
    ball.velocity += ball.acceleration * delta
    ball.position += ball.velocity * delta

    if rl.GetTime() - ball.particle_time > 0.1 {
        ball.particle_time = rl.GetTime()
        do_emit_particles(ball)
    }
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
        ball_aabb.min.y = 0

        player2.points += 1
        player2.score_time = rl.GetTime()
    }
    
    if ball_aabb.max.x > arena.aabb.max.x {
        ball.velocity.x *= -1
    }
    
    if ball_aabb.max.y > arena.aabb.max.y {
        ball.velocity.y *= -1
        ball_aabb.min.y = arena.aabb.max.y

        player1.points += 1
        player1.score_time = rl.GetTime()
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
        if ball.velocity.y > 0 {
            // colliding with player2
            ball.position.y = player.position.y - ball.size.y * 0.5 - player.size.y * 0.5
        } else {
            // colliding with player1
            ball.position.y = player.position.y + ball.size.y * 0.5 + player.size.y * 0.5
        }
        ball.velocity.y *= -1
        ball.velocity.x += math.clamp(0.1 * player.velocity.x, -300, 300)
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

particleStartSize :: rl.Vector2{10, 10}

particles : [4096]Particle
particle_index : int

make_particle :: proc() -> ^Particle {
    particle := &particles[particle_index]
    particle_index = (particle_index + 1) % len(particles)
    return particle
}

do_draw_particles :: proc() {
    for &p in particles {
        if p.life_remaining > 0 {
            do_draw(&p)
        }
    }
}

do_update_particles :: proc(delta: f32) {
    for &p in particles {
        if p.life_remaining > 0 {
            p.life_remaining -= delta
            life_ratio := math.remap(p.life_remaining, 0, p.lifetime, 0, 1)
    
            p.color.a = (u8)(255 * life_ratio)
            p.size = particleStartSize * life_ratio
            p.velocity += p.acceleration * delta
            p.position += p.velocity * delta
        }
    }
}