extends RefCounted
## Movimiento, colisiones, riesgos y partículas del personaje.
const Config = preload("res://scripts/game/config.gd")
const GRAVITY = Config.GRAVITY
const SPEED = Config.SPEED
const JUMP = Config.JUMP

var game
var character_pos: Vector2 = Vector2.ZERO
var character_vel: Vector2 = Vector2.ZERO
var grounded: bool = false
var jump_held: bool = false
var facing: int = 1
var anim_clock: float = 0.0
var particles: Array[Dictionary] = []

func _init(host) -> void:
    game = host

func respawn_character() -> void:
    var spawn: Rect2 = game.stage.fixed_platforms[0]
    character_pos = Vector2(spawn.position.x + 72.0, spawn.position.y - 16.0)
    character_vel = Vector2.ZERO
    grounded = true
    jump_held = false
    particles.clear()

func simulate_parkour(dt: float) -> void:
    var axis: float = 0.0
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        axis -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        axis += 1.0
    if axis != 0.0:
        facing = int(sign(axis))
    var run_speed: float = SPEED * (1.30 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
    character_vel.x = axis * run_speed
    var jump_now: bool = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
    if grounded and jump_now and not jump_held:
        character_vel.y = JUMP
        grounded = false
        game.sound.play_tone(440.0, 0.06)
    jump_held = jump_now
    character_vel.y += GRAVITY * dt
    var feet_before: float = character_pos.y + 16.0
    character_pos.x = clampf(character_pos.x + character_vel.x*dt, 12.0, 755.0)
    character_pos.y += character_vel.y*dt
    grounded = false
    if character_vel.y >= 0.0:
        for platform in game.stage.platforms_now():
            if character_pos.x + 11.0 > platform.position.x and character_pos.x - 11.0 < platform.end.x and feet_before <= platform.position.y + 9.0 and character_pos.y + 16.0 >= platform.position.y:
                character_pos.y = platform.position.y - 16.0
                character_vel.y = 0.0
                grounded = true
                break
    if character_pos.y > 585.0:
        game.lose_life("CAIDA", false)
        return
    var foot: Vector2 = character_pos + Vector2(0.0,14.0)
    for spikes in game.stage.spike_zones:
        if Rect2(spikes.position - Vector2(4.0,7.0),spikes.size+Vector2(8.0,8.0)).has_point(foot):
            game.lose_life("PINCHOS", false)
            return
    for saw in game.stage.saws:
        if character_pos.distance_to(game.stage.saw_center(saw)) < 24.0:
            game.lose_life("SIERRA", false)
            return
    # Puerta al final de la ultima plataforma: al llegar se activa el puzzle.
    var finish_platform: Rect2 = game.stage.fixed_platforms[game.stage.fixed_platforms.size()-1]
    if character_pos.x > 708.0 and grounded and character_pos.y + 16.0 <= finish_platform.position.y + 5.0:
        game.reach_parkour_finish()
        return
    if absf(character_vel.x) > 2.0 and grounded and randf() < 0.22:
        particles.append({"pos":character_pos + Vector2(-float(facing)*8.0,12.0),"velocity":Vector2(randf_range(-16.0,16.0),randf_range(-42.0,-14.0)),"life":0.37})
    anim_clock += dt * (12.0 if absf(character_vel.x)>2.0 else 2.0)

func update_particles(dt: float) -> void:
    for i in range(particles.size() - 1, -1, -1):
        var part: Dictionary = particles[i]
        part["life"] = float(part["life"]) - dt
        part["pos"] = Vector2(part["pos"]) + Vector2(part["velocity"]) * dt
        if float(part["life"]) <= 0.0:
            particles.remove_at(i)
        else:
            particles[i] = part
