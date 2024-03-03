package main

import rl "vendor:raylib"
import "core:math"

magnitude :: proc(vec: rl.Vector2) -> f32 {
    cvec := vec.xy * vec.xy
    return math.sqrt(cvec.x + cvec.y)
}

direction :: proc(vec: rl.Vector2) -> rl.Vector2 {
    mag := magnitude(vec)
    if mag == 0 {
        return 0
    }
    return vec / mag
}
