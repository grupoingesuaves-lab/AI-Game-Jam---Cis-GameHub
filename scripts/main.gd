extends Node2D
## Controla turnos, estados y puntuaciones; los sistemas viven en scripts separados.

const Config = preload("res://scripts/game/config.gd")
const Stage = preload("res://scripts/game/stage.gd")
const Parkour = preload("res://scripts/game/parkour.gd")
const Puzzles = preload("res://scripts/game/puzzles.gd")

const MAX_ROUNDS = Config.MAX_ROUNDS
const MAX_HEARTS = Config.MAX_HEARTS
const PARKOUR_LIMIT = Config.PARKOUR_LIMIT
const PUZZLE_LIMIT = Config.PUZZLE_LIMIT
const ROUND_NAMES = Config.ROUND_NAMES

var mode: String = "menu"   # menu, playing, pause, eliminated, victory_transition, victory, end
# Eliminacion: 0 = mordisco sobre el vidrio roto, 1 = tentaculos, 2 = aviso negro.
var elimination_stage: int = 0
var elimination_elapsed: float = 0.0
var elimination_exit_seconds: float = 0.90
var elimination_close_seconds: float = 1.00
var elimination_black_seconds: float = 1.40
var menu_index: int = 0 # 0 = jugar, 1 = salir
# Menu de victoria: el monstruo se retira antes de mostrar el resultado.
const VICTORY_EXIT_SECONDS: float = 0.85
var victory_transition_elapsed: float = 0.0
var victory_menu_index: int = 0 # 0 = volver a jugar, 1 = salir
var victory_winner: int = -1 # -1 = empate; 0/1 = ganador
var phase: String = "parkour" # parkour, puzzle
var active_player: int = 0
# El primero de cada ronda fija la marca; el segundo debe igualarla o mejorarla.
# Ronda 1: J1 -> J2; ronda 2: J2 -> J1; y asi sucesivamente.
var round_leader: int = 0
var round_index: int = 0
var hearts: Array[int] = [MAX_HEARTS, MAX_HEARTS]
var points: Array[int] = [0, 0]
var victories: Array[int] = [0, 0]
var window_damage: Array[int] = [0, 0]
var round_success: Array[bool] = [false, false]
var parkour_remaining: float = PARKOUR_LIMIT
var parkour_limit: float = PARKOUR_LIMIT
var challenger_parkour_limit: float = PARKOUR_LIMIT
var leader_parkour_record: float = -1.0
var puzzle_remaining: float = PUZZLE_LIMIT
var elapsed: float = 0.0
var shake: float = 0.0
var flash: float = 0.0
var fear: float = 0.0
var message: String = ""
var message_left: float = 0.0
var attempts: int = 0


var stage
var parkour
var puzzle
var sound
var renderer

func _ready() -> void:
    randomize()
    stage = Stage.new(self)
    parkour = Parkour.new(self)
    puzzle = Puzzles.new(self)
    sound = get_node("Sound")
    renderer = get_node("Renderer")
    stage.build_level()
    set_process(true)
    set_process_input(true)

func _input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return
    var keyboard_event: InputEventKey = event as InputEventKey
    if not keyboard_event.pressed or keyboard_event.echo:
        return
    var key: int = keyboard_event.keycode
    if key == KEY_M:
        sound.sound_enabled = not sound.sound_enabled
    if mode == "menu":
        if key == KEY_UP or key == KEY_W:
            menu_index = maxi(0, menu_index - 1)
            return
        if key == KEY_DOWN or key == KEY_S:
            menu_index = mini(1, menu_index + 1)
            return
        if key == KEY_ESCAPE:
            get_tree().quit()
            return
        if key == KEY_ENTER or key == KEY_SPACE:
            if menu_index == 0:
                new_game()
            else:
                get_tree().quit()
            return
        return
    if mode == "pause":
        if key == KEY_ESCAPE or key == KEY_P or key == KEY_ENTER:
            mode = "playing"
        elif key == KEY_R:
            mode = "menu"
        return
    if mode == "victory":
        if key == KEY_UP or key == KEY_W:
            victory_menu_index = maxi(0, victory_menu_index - 1)
        elif key == KEY_DOWN or key == KEY_S:
            victory_menu_index = mini(1, victory_menu_index + 1)
        elif key == KEY_ESCAPE:
            get_tree().quit()
        elif key == KEY_ENTER or key == KEY_SPACE:
            if victory_menu_index == 0:
                new_game()
            else:
                get_tree().quit()
        return
    if mode == "end":
        if key == KEY_ENTER or key == KEY_SPACE:
            new_game()
        return
    if mode != "playing":
        return
    if key == KEY_ESCAPE or key == KEY_P:
        mode = "pause"
        return
    if phase == "parkour":
        if key == KEY_R:
            parkour.respawn_character()
            announce("REAPARECER NO REINICIA EL RELOJ")
        return
    if phase == "puzzle":
        if key == KEY_BACKSPACE and puzzle.puzzle_kind == "code":
            if puzzle.puzzle_entry.length() > 0:
                puzzle.puzzle_entry = puzzle.puzzle_entry.substr(0, puzzle.puzzle_entry.length() - 1)
            return
        if key == KEY_ENTER and puzzle.puzzle_kind == "code":
            puzzle.submit_code()
            return
        var digit: int = key_to_number(key)
        if digit >= 0:
            puzzle.puzzle_input(digit)

func key_to_number(key: int) -> int:
    if key >= KEY_0 and key <= KEY_9:
        return key - KEY_0
    if key >= KEY_KP_0 and key <= KEY_KP_9:
        return key - KEY_KP_0
    return -1

func new_game() -> void:
    menu_index = 0
    victory_menu_index = 0
    victory_winner = -1
    victory_transition_elapsed = 0.0
    elimination_stage = 0
    elimination_elapsed = 0.0
    hearts = [MAX_HEARTS, MAX_HEARTS]
    points = [0, 0]
    victories = [0, 0]
    window_damage = [0, 0]
    round_success = [false, false]
    round_index = 0
    round_leader = 0
    active_player = round_leader
    challenger_parkour_limit = PARKOUR_LIMIT
    leader_parkour_record = -1.0
    elapsed = 0.0
    fear = 0.0
    mode = "playing"
    stage.build_level()
    start_turn()
    announce("RONDA 1 / 10 - JUGADOR 1")

func start_turn() -> void:
    if hearts[active_player] <= 0:
        complete_turn(false)
        return
    attempts = 0
    phase = "parkour"
    # El primero de la ronda tiene 30 s; el rival recibe la marca fijada.
    parkour_limit = PARKOUR_LIMIT if active_player == round_leader else challenger_parkour_limit
    parkour_remaining = parkour_limit
    puzzle_remaining = PUZZLE_LIMIT
    puzzle.reset_puzzle()
    parkour.respawn_character()

func restart_round_after_loss() -> void:
    # El jugador continua en el MISMO nivel. Se reinician los dos relojes.
    if active_player == round_leader:
        # Una marca previa deja de ser valida al reiniciar el intento del lider.
        leader_parkour_record = -1.0
        challenger_parkour_limit = PARKOUR_LIMIT
    phase = "parkour"
    parkour_remaining = parkour_limit
    puzzle_remaining = PUZZLE_LIMIT
    puzzle.reset_puzzle()
    parkour.respawn_character()
    attempts += 1
    announce("REINTENTO DE RONDA - VIDA PERDIDA")

func announce(text: String) -> void:
    message = text
    message_left = 2.2

func damage_window(player: int, amount: int = 1) -> void:
    window_damage[player] = mini(3, window_damage[player] + amount)
    shake = 7.0
    flash = 0.60
    fear = 1.0

func lose_life(reason: String, restart_entire_round: bool, extra_damage: int = 0) -> void:
    if mode != "playing":
        return
    hearts[active_player] = maxi(0, hearts[active_player] - 1)
    damage_window(active_player, 1 + extra_damage)
    sound.play_tone(145.0, 0.23)
    if hearts[active_player] <= 0:
        # No cambiar turno hasta terminar mordisco, cierre y aviso negro.
        announce("SIN VIDAS - TURNO PERDIDO")
        elimination_stage = 0
        elimination_elapsed = 0.0
        mode = "eliminated"
    elif restart_entire_round:
        restart_round_after_loss()
    else:
        parkour.respawn_character()
        announce(reason + " - EL TIEMPO CONTINUA")

func parkour_timeout() -> void:
    parkour_remaining = 0.0
    lose_life("TIEMPO DEL PARKOUR AGOTADO", true, 1)

func puzzle_timeout() -> void:
    puzzle_remaining = 0.0
    # Regla solicitada: vuelve AL PRINCIPIO DEL PARKOUR y pierde una vida.
    lose_life("PUZZLE SIN RESOLVER", true, 1)

func reach_parkour_finish() -> void:
    if phase != "parkour" or mode != "playing":
        return
    if active_player == round_leader:
        # Esta marca solo corresponde al parkour; el puzzle conserva sus 60 s.
        leader_parkour_record = clampf(parkour_limit - parkour_remaining, 0.1, PARKOUR_LIMIT)
        challenger_parkour_limit = leader_parkour_record
    phase = "puzzle"
    puzzle_remaining = PUZZLE_LIMIT
    puzzle.configure_puzzle()
    sound.play_tone(675.0, 0.17)
    announce("PUZZLE DESBLOQUEADO - 60 SEGUNDOS")

func complete_puzzle() -> void:
    if phase != "puzzle" or mode != "playing":
        return
    victories[active_player] += 1
    round_success[active_player] = true
    points[active_player] += 500 + int(parkour_remaining * 5.0) + int(puzzle_remaining * 8.0)
    sound.play_tone(820.0, 0.34)
    complete_turn(true)

func complete_turn(success: bool) -> void:
    if mode != "playing":
        return
    round_success[active_player] = success
    if active_player == round_leader:
        # Si el lider no consiguio terminar el parkour, el rival tiene 30 s.
        if leader_parkour_record < 0.0:
            challenger_parkour_limit = PARKOUR_LIMIT
        active_player = 1 - round_leader
        if hearts[active_player] <= 0:
            finish_round()
        else:
            start_turn()
            announce("JUGADOR %d - %.2f S PARA EL PARKOUR" % [active_player + 1, parkour_limit])
        return
    finish_round()

func finish_round() -> void:
    if round_index + 1 >= MAX_ROUNDS:
        # Mantener round_index = 9 durante la transicion y el menu de victoria,
        # pues los dibujantes usan round_index para consultar el ultimo nivel.
        # Se llega aqui DESPUES del turno del segundo jugador de la ronda.
        # Con un jugador eliminado, su turno se omite; en ambos casos,
        # alguien debe haber superado el ultimo puzzle para ganar.
        if round_success[0] or round_success[1]:
            start_victory()
        else:
            mode = "end"  # Nadie supero el nivel final: no anunciar victoria.
        return
    round_index += 1
    if hearts[0] <= 0 and hearts[1] <= 0:
        mode = "end"
        return
    # Quien jugo segundo abre la siguiente ronda y establece la nueva marca.
    round_leader = 1 - round_leader
    # Si ese jugador ya fue eliminado, el superviviente abre la ronda.
    if hearts[round_leader] <= 0:
        round_leader = 1 - round_leader
    active_player = round_leader
    leader_parkour_record = -1.0
    challenger_parkour_limit = PARKOUR_LIMIT
    round_success = [false, false]
    stage.build_level()
    start_turn()
    announce("RONDA %d / %d - %s - JUGADOR %d FIJA EL TIEMPO" % [round_index + 1, MAX_ROUNDS, ROUND_NAMES[round_index], active_player + 1])

func start_victory() -> void:
    # El ganador se determina SOLO por las vidas restantes, no por puntos.
    if hearts[0] > hearts[1]:
        victory_winner = 0
    elif hearts[1] > hearts[0]:
        victory_winner = 1
    else:
        victory_winner = -1
    victory_menu_index = 0
    victory_transition_elapsed = 0.0
    mode = "victory_transition"

func _process(delta: float) -> void:
    var dt: float = minf(delta, 0.04)
    if mode == "victory_transition":
        # Congelar fisica, acertijos y cronometros mientras sale el monstruo.
        victory_transition_elapsed += dt
        if victory_transition_elapsed >= VICTORY_EXIT_SECONDS:
            victory_transition_elapsed = VICTORY_EXIT_SECONDS
            mode = "victory"
        renderer.queue_redraw()
        return
    if mode == "eliminated":
        # Los relojes, colisiones y puzzles quedan congelados durante el aviso.
        elimination_elapsed += dt
        if elimination_stage == 0 and elimination_elapsed >= elimination_exit_seconds:
            elimination_stage = 1  # El mordisco da paso al cierre de tentaculos.
            elimination_elapsed = 0.0
        elif elimination_stage == 1 and elimination_elapsed >= elimination_close_seconds:
            elimination_stage = 2  # Pantalla completamente negra + ELIMINADO.
            elimination_elapsed = 0.0
        elif elimination_stage == 2 and elimination_elapsed >= elimination_black_seconds:
            elimination_elapsed = 0.0
            elimination_stage = 0
            mode = "playing"
            # Conservar el flujo de turnos original, sin duplicarlo.
            complete_turn(false)
        renderer.queue_redraw()
        return
    elapsed += dt
    shake = maxf(0.0, shake - dt * 25.0)
    flash = maxf(0.0, flash - dt * 1.7)
    fear = maxf(0.0, fear - dt * 0.5)
    message_left = maxf(0.0, message_left - dt)
    puzzle.update(dt)
    sound.update_audio()
    if mode == "playing":
        if phase == "parkour":
            parkour_remaining = maxf(0.0, parkour_remaining - dt)
            if parkour_remaining <= 0.0:
                parkour_timeout()
            else:
                parkour.simulate_parkour(dt)
        elif phase == "puzzle":
            puzzle_remaining = maxf(0.0, puzzle_remaining - dt)
            if puzzle_remaining <= 0.0:
                puzzle_timeout()
    parkour.update_particles(dt)
    renderer.queue_redraw()
