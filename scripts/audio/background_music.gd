extends AudioStreamPlayer
## Reproductor aislado del juego; musica audible solo durante el parkour.
## La pista WAV fue normalizada y su importacion es compatible con Godot 4.

const MUSIC_PATH: String = "res://assets/audio/BackSong.wav"
var previous_music_state: bool = false

func _ready() -> void:
    # Escena ya asigna el audio. Si Godot lo dejo vacio, intentamos cargarlo.
    if stream == null:
        stream = load(MUSIC_PATH) as AudioStream
    if stream == null:
        push_error("UMBRAL MUSICA: no se pudo cargar " + MUSIC_PATH)
        return
    if stream is AudioStreamWAV:
        var wav: AudioStreamWAV = stream as AudioStreamWAV
        wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
    # Sin atenuacion artificial: el propio WAV ya tiene nivel ajustado.
    volume_db = 0.0
    bus = "Master"
    set_process(true)
    print("UMBRAL MUSICA: audio WAV cargado. Esperando inicio del parkour.")

func _process(_delta: float) -> void:
    if stream == null:
        return
    var game: Node = get_parent()
    if game == null:
        return
    var sound: Node = get_node_or_null("../Sound")
    var audio_enabled: bool = true
    if sound != null:
        audio_enabled = bool(sound.get("sound_enabled"))

    var in_game: bool = game.get("mode") == "playing"
    var in_parkour: bool = game.get("phase") == "parkour"
    var should_play: bool = in_game and in_parkour and audio_enabled

    if should_play and not playing:
        play()
        print("UMBRAL MUSICA: INICIADA en parkour. playing=", playing)
    elif not should_play and playing:
        stop()
        print("UMBRAL MUSICA: DETENIDA (menu, acertijo, pausa, eliminado o sonido M).")

    previous_music_state = should_play
