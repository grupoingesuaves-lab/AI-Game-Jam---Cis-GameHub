extends RefCounted
## Secuencias, memoria, claves y interruptores; independiente del render.
var game
var puzzle_kind: String = "sequence"
var puzzle_title: String = ""
var puzzle_hint: String = ""
var puzzle_sequence: Array[int] = []
var puzzle_step: int = 0
var puzzle_show_for: float = 0.0
var puzzle_answer: String = ""
var puzzle_entry: String = ""
var puzzle_switches: Array[int] = []
var puzzle_target: Array[int] = []
var puzzle_wrong: float = 0.0


func _init(host) -> void:
    game = host

func reset_puzzle() -> void:
    puzzle_step = 0
    puzzle_show_for = 0.0
    puzzle_sequence.clear()
    puzzle_answer = ""
    puzzle_entry = ""
    puzzle_switches.clear()
    puzzle_target.clear()
    puzzle_wrong = 0.0

func configure_puzzle() -> void:
    reset_puzzle()
    match game.round_index:
        0:
            set_sequence("SELLOS DE LA GRUA",[1,3,2],false)
        1:
            set_sequence("RUNAS DEL BOSQUE",[2,4,1,3],false)
        2:
            set_sequence("ECOS DE LA CRIPTA",[3,1,4,2],true,5.5)
        3:
            set_code("GENERADOR DE LA FABRICA","9 + 8 = ?","17")
        4:
            set_switches("RED DE LA CIUDAD",4,[0,2,3])
        5:
            set_sequence("CRISTALES QUE SUSURRAN",[4,2,1,3,4],true,4.8)
        6:
            set_code("FARO DEL PUERTO","7 x 4 + 3 = ?","31")
        7:
            set_switches("NODOS DEL VOLCAN",5,[0,1,3,4])
        8:
            set_sequence("RECUERDO DEL HIELO",[2,4,1,3,2,1],true,4.2)
        _:
            set_sequence("TRONO DEL DESIERTO",[4,1,3,2,4,2,1],true,3.8)

func set_sequence(title: String, sequence: Array, hidden: bool, seconds: float = 0.0) -> void:
    puzzle_title = title
    puzzle_kind = "memory" if hidden else "sequence"
    for number in sequence:
        puzzle_sequence.append(int(number))
    puzzle_show_for = seconds
    puzzle_hint = "MEMORIZA Y REPITE CON 1-4" if hidden else "PULSA LOS SELLOS EN EL ORDEN INDICADO"

func set_code(title: String, clue: String, answer: String) -> void:
    puzzle_title = title
    puzzle_kind = "code"
    puzzle_hint = clue
    puzzle_answer = answer

func set_switches(title: String, count: int, presses: Array) -> void:
    puzzle_title = title
    puzzle_kind = "switch"
    puzzle_hint = "CADA TECLA ACTIVA SU NODO Y EL VECINO DERECHO"
    puzzle_switches.resize(count)
    puzzle_target.resize(count)
    for i in range(count):
        puzzle_switches[i] = 0
        puzzle_target[i] = 0
    for raw_press in presses:
        var press: int = int(raw_press)
        puzzle_target[press] = 1 - puzzle_target[press]
        puzzle_target[(press+1)%count] = 1 - puzzle_target[(press+1)%count]

func puzzle_input(digit: int) -> void:
    if game.phase != "puzzle" or game.mode != "playing":
        return
    if puzzle_kind == "sequence" or puzzle_kind == "memory":
        if digit < 1 or digit > 4 or puzzle_show_for > 0.0:
            return
        if digit == puzzle_sequence[puzzle_step]:
            puzzle_step += 1
            game.sound.play_tone(460.0 + float(puzzle_step)*60.0,0.07)
            if puzzle_step >= puzzle_sequence.size():
                game.complete_puzzle()
        else:
            puzzle_step = 0
            puzzle_wrong = 0.75
            game.sound.play_tone(160.0,0.12)
        return
    if puzzle_kind == "code":
        if digit >= 0 and digit <= 9 and puzzle_entry.length() < 5:
            puzzle_entry += str(digit)
            game.sound.play_tone(420.0,0.035)
            if puzzle_entry.length() >= puzzle_answer.length():
                submit_code()
        return
    if puzzle_kind == "switch":
        if digit < 1 or digit > puzzle_switches.size():
            return
        var index: int = digit-1
        puzzle_switches[index] = 1 - puzzle_switches[index]
        var next_index: int = (index+1)%puzzle_switches.size()
        puzzle_switches[next_index] = 1 - puzzle_switches[next_index]
        game.sound.play_tone(360.0 + float(index)*75.0,0.07)
        if puzzle_switches == puzzle_target:
            game.complete_puzzle()

func submit_code() -> void:
    if puzzle_entry == puzzle_answer:
        game.complete_puzzle()
    else:
        puzzle_wrong = 0.75
        puzzle_entry = ""
        game.sound.play_tone(165.0,0.14)

func update(dt: float) -> void:
    puzzle_wrong = maxf(0.0, puzzle_wrong - dt)
    if game.mode == "playing" and game.phase == "puzzle":
        puzzle_show_for = maxf(0.0, puzzle_show_for - dt)
