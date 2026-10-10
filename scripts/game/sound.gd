extends Node
## Sonidos sintetizados: no se necesitan archivos WAV externos.
var sound_enabled: bool = true
var audio_player: AudioStreamPlayer
var audio_playback: AudioStreamGeneratorPlayback
var tone_hz: float = 0.0
var tone_samples_left: int = 0
var tone_phase: float = 0.0


func _ready() -> void:
    audio_player = AudioStreamPlayer.new()
    var generator: AudioStreamGenerator = AudioStreamGenerator.new()
    generator.mix_rate = 22050.0
    generator.buffer_length = 0.25
    audio_player.stream = generator
    audio_player.volume_db = -22.0
    add_child(audio_player)
    audio_player.play()
    audio_playback = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback

func play_tone(hz: float, duration: float) -> void:
    tone_hz = hz
    tone_samples_left = int(duration * 22050.0)
    tone_phase = 0.0

func update_audio() -> void:
    if audio_playback == null or not audio_playback.can_push_buffer(256):
        return
    var frames: PackedVector2Array = PackedVector2Array()
    for i in range(256):
        var volume: float = 0.0
        if sound_enabled and tone_samples_left > 0:
            volume = sin(tone_phase) * 0.16 * minf(float(tone_samples_left)/500.0, 1.0)
            tone_phase += tone_hz * TAU / 22050.0
            tone_samples_left -= 1
        frames.append(Vector2(volume,volume))
    audio_playback.push_buffer(frames)

# ---------------------------- DIBUJO ----------------------------
