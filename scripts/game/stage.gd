extends RefCounted
## Geometría y trampas de las diez rondas; las coordenadas son locales a cada lado.
var game

var fixed_platforms: Array[Rect2] = []
var moving_platforms: Array[Dictionary] = []
var spike_zones: Array[Rect2] = []
var saws: Array[Dictionary] = []

func _init(host) -> void:
    game = host

func build_level() -> void:
    fixed_platforms.clear()
    moving_platforms.clear()
    spike_zones.clear()
    saws.clear()
    # Las plataformas de la primera ronda mantienen el trazado original.
    match game.round_index:
        0:
            fixed_platforms = [Rect2(10,356,176,21), Rect2(268,325,130,20), Rect2(585,254,183,24)]
            spike_zones = [Rect2(499,381,117,20)]
        1:
            fixed_platforms = [Rect2(10,402,170,20), Rect2(213,351,115,18), Rect2(391,297,110,18), Rect2(602,244,166,22)]
            spike_zones = [Rect2(295,337,24,14)]
        2:
            fixed_platforms = [Rect2(10,404,166,20), Rect2(220,350,110,18), Rect2(393,294,110,18), Rect2(605,239,163,22)]
            saws = [{"x":348.0,"y":294.0,"amp":23.0,"speed":1.15}]
        3:
            fixed_platforms = [Rect2(10,406,160,20), Rect2(207,355,118,18), Rect2(405,300,106,18), Rect2(599,247,169,22)]
            spike_zones = [Rect2(300,341,22,14), Rect2(469,286,23,14)]
        4:
            fixed_platforms = [Rect2(10,404,156,20), Rect2(209,355,102,18), Rect2(389,299,103,18), Rect2(606,239,162,22)]
            moving_platforms = [{"rect":Rect2(510,269,85,14),"amp":22.0,"speed":1.0,"vertical":false}]
            saws = [{"x":364.0,"y":301.0,"amp":20.0,"speed":1.3}]
        5:
            fixed_platforms = [Rect2(10,409,159,20), Rect2(214,352,98,18), Rect2(392,292,101,18), Rect2(609,232,159,22)]
            moving_platforms = [{"rect":Rect2(521,270,78,14),"amp":27.0,"speed":1.5,"vertical":false}]
            spike_zones = [Rect2(274,338,28,14), Rect2(443,278,29,14)]
        6:
            fixed_platforms = [Rect2(10,408,163,20), Rect2(219,353,109,18), Rect2(398,299,102,18), Rect2(607,239,161,22)]
            saws = [{"x":363.0,"y":297.0,"amp":25.0,"speed":1.7}, {"x":542.0,"y":249.0,"amp":19.0,"speed":1.4}]
        7:
            fixed_platforms = [Rect2(10,411,160,20), Rect2(215,354,103,18), Rect2(390,298,103,18), Rect2(609,236,159,22)]
            moving_platforms = [{"rect":Rect2(512,269,79,14),"amp":30.0,"speed":1.8,"vertical":false}]
            spike_zones = [Rect2(274,340,31,14), Rect2(446,284,30,14)]
            saws = [{"x":361.0,"y":308.0,"amp":29.0,"speed":1.9}]
        8:
            fixed_platforms = [Rect2(10,411,164,20), Rect2(219,352,102,18), Rect2(393,292,103,18), Rect2(611,235,157,22)]
            moving_platforms = [{"rect":Rect2(511,269,83,14),"amp":32.0,"speed":1.9,"vertical":false}]
            spike_zones = [Rect2(283,338,27,14)]
            saws = [{"x":355.0,"y":294.0,"amp":21.0,"speed":2.15}, {"x":555.0,"y":238.0,"amp":20.0,"speed":1.7}]
        _:
            fixed_platforms = [Rect2(10,411,163,20), Rect2(215,353,106,18), Rect2(395,294,101,18), Rect2(610,235,158,22)]
            moving_platforms = [{"rect":Rect2(514,266,78,14),"amp":31.0,"speed":2.2,"vertical":false}]
            spike_zones = [Rect2(281,339,28,14), Rect2(461,280,24,14)]
            saws = [{"x":365.0,"y":304.0,"amp":27.0,"speed":2.4}, {"x":548.0,"y":242.0,"amp":21.0,"speed":2.05}]

func platforms_now() -> Array[Rect2]:
    var result: Array[Rect2] = fixed_platforms.duplicate()
    for entry in moving_platforms:
        var base: Rect2 = entry["rect"]
        var amount: float = sin(game.elapsed * float(entry["speed"])) * float(entry["amp"])
        var offset: Vector2 = Vector2(0.0,amount) if bool(entry["vertical"]) else Vector2(amount,0.0)
        result.append(Rect2(base.position + offset,base.size))
    return result

func saw_center(saw: Dictionary) -> Vector2:
    return Vector2(float(saw["x"]) + sin(game.elapsed * float(saw["speed"])) * float(saw["amp"]),float(saw["y"]))
