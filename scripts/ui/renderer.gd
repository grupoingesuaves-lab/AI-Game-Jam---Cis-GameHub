extends Node2D
## Interfaz, paisajes, ventanas agrietadas y visuales de los puzzles.
const Config = preload("res://scripts/game/config.gd")

var game
var font: Font
# Carga de las imagenes sin depender de los preloads del importador.
# No cambia las imagenes, sus posiciones ni el aspecto del juego.
var horror_left: Texture2D
var horror_right: Texture2D
var crack_left: Array[Texture2D] = []
var crack_right: Array[Texture2D] = []
var first_stage: Texture2D
var level_backgrounds: Array[Texture2D] = []

# Dimensiones exactas de los sprites originales: NO SE MODIFICAN.
const HERO_FRAME_WIDTH: float = 40.0
const HERO_FRAME_HEIGHT: float = 56.0
const HERO_FRAME_COUNT: int = 9
var hero_blue: Texture2D
var hero_red: Texture2D
var menu_background: Texture2D

func _read_png(path: String) -> Texture2D:
    # Prefiere la textura importada: tambien funciona en una exportacion.
    if ResourceLoader.exists(path, "Texture2D"):
        var resource: Resource = ResourceLoader.load(path, "Texture2D")
        if resource is Texture2D:
            return resource as Texture2D
    # Respaldo sin advertencias si la primera importacion sigue pendiente.
    if FileAccess.file_exists(path):
        var image: Image = Image.new()
        var error: int = image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
        if error == OK and not image.is_empty():
            return ImageTexture.create_from_image(image)
    push_error("UMBRAL: no se pudo cargar la imagen: " + path)
    return null

func _ready() -> void:
    game = get_parent()
    font = ThemeDB.fallback_font
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

    horror_left = _read_png("res://assets/windows/horror_left_intact.png")
    horror_right = _read_png("res://assets/windows/horror_right_intact.png")
    for n in range(1, 4):
        crack_left.append(_read_png("res://assets/windows/cracks_left_%d.png" % n))
        crack_right.append(_read_png("res://assets/windows/cracks_right_%d.png" % n))
    first_stage = _read_png("res://assets/backgrounds/platform_clean.png")
    for n in range(2, 11):
        level_backgrounds.append(_read_png("res://assets/backgrounds/level_%02d.png" % n))
    hero_blue = _read_png("res://assets/characters/personaje_azul.png")
    hero_red = _read_png("res://assets/characters/personaje_rojo.png")
    menu_background = _read_png("res://assets/ui/menu_inicio.png")
    queue_redraw()

func box_fill(x: float,y: float,w: float,h: float,color: Color) -> void:
    draw_rect(Rect2(x,y,w,h),color)

func text_at(value: String,x: float,y: float,size: int = 21,color: Color = Color("bbccdd"),center: bool = false) -> void:
    var px: float = x
    if center:
        px -= font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2.0
    draw_string(font,Vector2(px,y),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func panel_line(x: float,y: float,w: float,h: float,color: Color,weight: float = 2.0) -> void:
    draw_rect(Rect2(x,y,w,h),color,false,weight)

func draw_heart(x: float,y: float,alive: bool) -> void:
    var bitmap: Array[String] = ["01100110","11111111","11111111","01111110","00111100","00011000"]
    var tone: Color = Color("ed4059") if alive else Color("526179")
    for iy in range(bitmap.size()):
        for ix in range(8):
            if bitmap[iy][ix] == "1":
                box_fill(x+float(ix*3),y+float(iy*3),3.0,3.0,tone)
    if not alive:
        box_fill(x+6.0,y+6.0,12.0,5.0,Color("0b1018"))

func draw_window(player: int) -> void:
    # Las ventanas limpias ya estan dibujadas como fondo. Solo renderizar las
    # grietas que correspondan al dano actual; 0 significa vidrio intacto.
    var damage: int = clampi(game.window_damage[player], 0, 3)
    if damage == 0:
        return
    var texture: Texture2D = crack_left[damage - 1] if player == 0 else crack_right[damage - 1]
    draw_texture(texture, Vector2(float(player) * Config.PANEL_W, 0.0))

func _draw() -> void:
    draw_texture_rect(horror_left,Rect2(0.0,0.0,768.0,450.0),false)
    draw_texture_rect(horror_right,Rect2(768.0,0.0,768.0,450.0),false)
    for player in range(2):
        draw_window(player)
        draw_player_header(player)
    var game_side: int = game.active_player if game.mode != "menu" else 0
    for side in range(2):
        if side == game_side:
            if game.phase == "puzzle" and game.mode != "menu":
                draw_puzzle(float(side)*Config.PANEL_W)
            else:
                draw_game(float(side)*Config.PANEL_W)
        else:
            draw_waiting(float(side)*Config.PANEL_W,side)
    box_fill(0.0,446.0,Config.SCREEN_W,11.0,Color("060b14"))
    for xx in [0.0,768.0,1530.0]:
        box_fill(xx,0.0,6.0,Config.SCREEN_H,Color("08101c"))
    for xx in [7.0,773.0]:
        panel_line(xx,7.0,755.0,439.0,Color("2b4059"),2.0)
        panel_line(xx,459.0,755.0,548.0,Color("2b4059"),2.0)
    if game.flash > 0.0:
        box_fill(0.0,0.0,Config.SCREEN_W,Config.SCREEN_H,Color(0.8,0.04,0.08,game.flash*0.17))
    if game.mode == "menu":
        draw_start_menu()
    elif game.mode == "pause":
        draw_modal("PAUSA","CRONOMETROS DETENIDOS","ENTER / ESC - CONTINUAR","R - VOLVER AL MENU")
    elif game.mode == "victory":
        draw_victory_menu()
    elif game.mode == "end":
        var winner: String = "EMPATE"
        if game.points[0] > game.points[1]:
            winner = "JUGADOR 1"
        elif game.points[1] > game.points[0]:
            winner = "JUGADOR 2"
        draw_modal("FIN DE PARTIDA","GANADOR: " + winner,"ENTER - JUGAR OTRA VEZ","PUNTOS: %d - %d   /   RONDAS %d - %d" % [game.points[0],game.points[1],game.victories[0],game.victories[1]])

    elif game.mode == "eliminated" and game.elimination_stage == 2:
        # El aviso final cubre la vista superior COMPLETA del eliminado,
        # igual que los tentaculos. El otro jugador y la zona inferior no se tapan.
        var player: int = clampi(game.active_player, 0, 1)
        var panel: Rect2 = Rect2(float(player) * Config.PANEL_W,
                0.0, Config.PANEL_W, Config.STAGE_TOP)
        draw_rect(panel, Color.BLACK)
        text_at("ELIMINADO", panel.position.x + panel.size.x * 0.5,
                panel.position.y + panel.size.y * 0.52, 43, Color("dbe9f6"), true)
        text_at("JUGADOR %d" % (player + 1), panel.position.x + panel.size.x * 0.5,
                panel.position.y + panel.size.y * 0.69, 24, Color("8095ab"), true)

func draw_start_menu() -> void:
    if menu_background != null:
        draw_texture_rect(menu_background, Rect2(0.0, 0.0, Config.SCREEN_W, Config.SCREEN_H), false)
    else:
        draw_modal("UMBRAL", "", "ENTER - JUGAR", "ESC - SALIR")
        return
    var selected: int = int(game.menu_index)
    var play_rect: Rect2 = Rect2(585.0, 464.0, 365.0, 84.0)
    var quit_rect: Rect2 = Rect2(644.0, 588.0, 250.0, 58.0)
    var current: Rect2 = play_rect if selected == 0 else quit_rect
    # Se elimina el cuadro extra para que no se vea corrido sobre JUGAR.
    # La seleccion se indica solo con marcadores laterales, respetando el arte base del menu.
    var cy: float = current.position.y + current.size.y * 0.5
    draw_colored_polygon(PackedVector2Array([
        Vector2(current.position.x - 24.0, cy),
        Vector2(current.position.x - 10.0, cy - 10.0),
        Vector2(current.position.x - 10.0, cy + 10.0)
    ]), Color(0.49, 0.90, 1.0, 0.95))
    draw_colored_polygon(PackedVector2Array([
        Vector2(current.position.x + current.size.x + 24.0, cy),
        Vector2(current.position.x + current.size.x + 10.0, cy - 10.0),
        Vector2(current.position.x + current.size.x + 10.0, cy + 10.0)
    ]), Color(0.49, 0.90, 1.0, 0.95))
    # Ayuda compacta en la parte inferior, sin invadir la composicion.
    box_fill(488.0, 915.0, 560.0, 42.0, Color(0.02, 0.05, 0.10, 0.52))
    panel_line(488.0, 915.0, 560.0, 42.0, Color(0.24, 0.40, 0.55, 0.45), 1.0)
    text_at("↑ ↓ MOVER   ENTER ELEGIR   ESC SALIR", Config.SCREEN_W * 0.5, 943.0, 16, Color("c8def3"), true)

func draw_player_header(player: int) -> void:
    var ox: float = float(player)*Config.PANEL_W
    box_fill(ox+17.0,14.0,354.0,59.0,Color(0.015,0.019,0.027,0.96))
    text_at("JUGADOR %d" % (player+1),ox+34.0,52.0,27,Color("c1d4e6"))
    for i in range(Config.MAX_HEARTS):
        draw_heart(ox+234.0+float(i)*40.0,29.0,i < game.hearts[player])
    if game.mode == "playing" and player == game.active_player:
        box_fill(ox+12.0,9.0,6.0,6.0,Color("ed4356"))
    var status: String = "INTACTA" if game.window_damage[player] == 0 else ("ROTA" if game.window_damage[player] >= 3 else "GRIETAS %d/3" % game.window_damage[player])
    text_at(status,ox+24.0,425.0,15,Color("91a4ba"))
    text_at("%d PTS" % game.points[player],ox+650.0,425.0,16,Color("a8bdd5"))
    if game.fear > 0.0 and player == game.active_player:
        box_fill(ox+145.0,78.0,536.0,265.0,Color(0.7,0.025,0.05,game.fear*0.08))

func draw_stage_background(ox: float) -> void:
    if game.round_index == 0:
        draw_texture_rect(first_stage,Rect2(ox,Config.STAGE_TOP,768.0,574.0),false)
        return
    var texture: Texture2D = level_backgrounds[game.round_index-1]
    box_fill(ox,Config.STAGE_TOP,768.0,574.0,Color("07111a"))
    # Parallax horizontal: la fuente se desplaza lentamente, pero el jugador no.
    var src_w: float = 940.0
    var src_x: float = (1440.0-src_w)*0.5 + sin(game.elapsed*(0.20+float(game.round_index)*0.025))*65.0
    src_x = clampf(src_x,0.0,1440.0-src_w)
    draw_texture_rect_region(texture,Rect2(ox+9.0,Config.STAGE_TOP+12.0,750.0,430.0),Rect2(src_x,0.0,src_w,396.0))
    box_fill(ox+9.0,Config.STAGE_TOP+425.0,750.0,149.0,Color("101620"))
    for ix in range(26):
        var dx: float = ox+float(ix)*30.0
        box_fill(dx,Config.STAGE_TOP+441.0,29.0,2.0,Color("34404d"))
        box_fill(dx+1.0,Config.STAGE_TOP+471.0,26.0,2.0,Color("2b394b"))
    # Niebla dinamica muy suave, pintada sin shaders para exportacion web.
    for i in range(5):
        var fog_x: float = ox + float(i)*185.0 - 45.0 + sin(game.elapsed*0.28+float(i))*12.0
        box_fill(fog_x,Config.STAGE_TOP+394.0+float(i%2)*17.0,168.0,27.0,Color(0.60,0.77,0.86,0.035))

func draw_platform(rectangle: Rect2,ox: float,moving: bool) -> void:
    var x: float = ox + rectangle.position.x
    var y: float = Config.STAGE_TOP + rectangle.position.y
    var tint: Color = Config.STAGE_COLORS[game.round_index]
    box_fill(x,y,rectangle.size.x,rectangle.size.y,Color("1b2634"))
    box_fill(x,y,rectangle.size.x,5.0,tint)
    for stripe in range(int(rectangle.size.x/19.0)):
        var sx: float = x+float(stripe)*19.0
        draw_line(Vector2(sx+2.0,y+4.0),Vector2(sx+11.0,y+11.0),Color("0e141e"),5.0)
    box_fill(x,y+rectangle.size.y-4.0,rectangle.size.x,4.0,Color("0a1019"))
    if moving:
        text_at("<>" ,x+rectangle.size.x*0.5,y-11.0,15,tint,true)

func draw_game(ox: float) -> void:
    draw_stage_background(ox)
    # La imagen de la primera ronda incorpora plataformas y trampas del escenario.
    if game.round_index > 0:
        for pl in game.stage.fixed_platforms:
            draw_platform(pl,ox,false)
        for entry in game.stage.moving_platforms:
            var base: Rect2 = entry["rect"]
            var amount: float = sin(game.elapsed*float(entry["speed"]))*float(entry["amp"])
            var offset: Vector2 = Vector2(0.0,amount) if bool(entry["vertical"]) else Vector2(amount,0.0)
            draw_platform(Rect2(base.position+offset,base.size),ox,true)
        for spikes in game.stage.spike_zones:
            draw_spikes(ox,spikes)
        for saw in game.stage.saws:
            draw_saw(ox,game.stage.saw_center(saw))
    if game.round_index > 0:
        var last: Rect2 = game.stage.fixed_platforms[game.stage.fixed_platforms.size()-1]
        var door_x: float = ox+714.0
        var door_y: float = Config.STAGE_TOP+last.position.y-60.0
        box_fill(door_x,door_y,34.0,60.0,Color("090f1a"))
        panel_line(door_x,door_y,34.0,60.0,Config.STAGE_COLORS[game.round_index],3.0)
        box_fill(door_x+26.0,door_y+27.0,3.0,7.0,Config.STAGE_COLORS[game.round_index])
    # Sprites originales del ZIP: azul para J1, rojo para J2 (no se recolorean).
    var sprite: Texture2D = hero_blue if game.active_player == 0 else hero_red
    var walking: bool = absf(game.parkour.character_vel.x) > 2.0 and game.parkour.grounded
    var frame: int = (1 + int(game.parkour.anim_clock) % (HERO_FRAME_COUNT - 1)) if walking else 0
    if not game.parkour.grounded:
        frame = 4
    var source: Rect2 = Rect2(float(frame) * HERO_FRAME_WIDTH, 0.0, HERO_FRAME_WIDTH, HERO_FRAME_HEIGHT)
    var actor: Vector2 = Vector2(ox + game.parkour.character_pos.x - HERO_FRAME_WIDTH * 0.5,
            Config.STAGE_TOP + game.parkour.character_pos.y + 16.0 - HERO_FRAME_HEIGHT)
    if game.parkour.facing < 0:
        draw_set_transform(actor + Vector2(HERO_FRAME_WIDTH, 0.0), 0.0, Vector2(-1.0, 1.0))
        draw_texture_rect_region(sprite, Rect2(Vector2.ZERO, Vector2(HERO_FRAME_WIDTH, HERO_FRAME_HEIGHT)), source)
        draw_set_transform(Vector2.ZERO)
    else:
        draw_texture_rect_region(sprite, Rect2(actor, Vector2(HERO_FRAME_WIDTH, HERO_FRAME_HEIGHT)), source)
    for particle in game.parkour.particles:
        var p: Vector2 = particle["pos"]
        box_fill(ox+p.x,Config.STAGE_TOP+p.y,3.0,3.0,Color(0.82,0.86,0.92,clampf(float(particle["life"])*2.0,0.0,1.0)))
    draw_stage_hud(ox)

func draw_spikes(ox: float,area: Rect2) -> void:
    var count: int = maxi(1,int(area.size.x/15.0))
    for j in range(count):
        var x: float = ox+area.position.x+float(j)*15.0
        var y: float = Config.STAGE_TOP+area.position.y
        draw_colored_polygon(PackedVector2Array([Vector2(x,y+area.size.y),Vector2(x+8.0,y),Vector2(x+15.0,y+area.size.y)]),Color("bdc8d2"))

func draw_saw(ox: float,center: Vector2) -> void:
    var c: Vector2 = Vector2(ox+center.x,Config.STAGE_TOP+center.y)
    draw_circle(c,20.0,Color("243344"))
    for i in range(8):
        var angle: float = float(i)*TAU/8.0 + game.elapsed*3.0
        draw_line(c+Vector2.from_angle(angle)*13.0,c+Vector2.from_angle(angle)*24.0,Color("bacbd5"),5.0)
    draw_circle(c,7.0,Color("d85159"))
    draw_circle(c,3.0,Color("271218"))

func draw_stage_hud(ox: float) -> void:
    box_fill(ox+18.0,469.0,312.0,49.0,Color(0.025,0.044,0.067,0.96))
    text_at("RONDA %02d/10  |  PARKOUR" % (game.round_index+1),ox+30.0,502.0,21,Color("c2d8ee"))
    box_fill(ox+545.0,465.0,209.0,70.0,Color(0.02,0.04,0.063,0.97))
    var clock_color: Color = Color("ee5767") if game.parkour_remaining < 12.0 else Color("c9dcef")
    text_at("%06.2f s" % game.parkour_remaining,ox+644.0,497.0,29,clock_color,true)
    text_at("LIMITE %.2f s" % game.parkour_limit,ox+648.0,522.0,16,Color("d8b973"),true)
    box_fill(ox+20.0,Config.STAGE_TOP+521.0,490.0,30.0,Color(0.025,0.04,0.064,0.84))
    text_at(Config.ROUND_NAMES[game.round_index],ox+29.0,Config.STAGE_TOP+543.0,18,Config.STAGE_COLORS[game.round_index])
    text_at("A/D MOVER   ESPACIO SALTAR   SHIFT CORRER",ox+19.0,Config.STAGE_TOP+569.0,15,Color("b2c0ce"))
    if game.message_left > 0.0:
        box_fill(ox+172.0,535.0,425.0,41.0,Color(0.025,0.04,0.065,0.93))
        text_at(game.message,ox+384.0,563.0,17,Color("f4d6a3"),true)

func draw_puzzle(ox: float) -> void:
    draw_stage_background(ox)
    box_fill(ox+13.0,463.0,741.0,532.0,Color(0.025,0.039,0.064,0.94))
    panel_line(ox+22.0,472.0,724.0,515.0,Config.STAGE_COLORS[game.round_index],3.0)
    box_fill(ox+28.0,482.0,706.0,48.0,Color("101928"))
    text_at("PUZZLE  |  %s" % game.puzzle.puzzle_title,ox+384.0,515.0,23,Color("d7e5f0"),true)
    var clock_color: Color = Color("ef5e67") if game.puzzle_remaining < 12.0 else Color("f1c976")
    text_at("%05.2f s" % game.puzzle_remaining,ox+384.0,574.0,35,clock_color,true)
    text_at("TIENES 60 SEGUNDOS PARA RESOLVERLO",ox+384.0,607.0,18,Color("acbdd0"),true)
    text_at(game.puzzle.puzzle_hint,ox+384.0,661.0,19,Config.STAGE_COLORS[game.round_index],true)
    if game.puzzle.puzzle_kind == "sequence" or game.puzzle.puzzle_kind == "memory":
        draw_sequence_puzzle(ox)
    elif game.puzzle.puzzle_kind == "code":
        draw_code_puzzle(ox)
    elif game.puzzle.puzzle_kind == "switch":
        draw_switch_puzzle(ox)
    if game.puzzle.puzzle_wrong > 0.0:
        text_at("ERROR - PRUEBA DE NUEVO",ox+384.0,918.0,22,Color("ef6774"),true)
    text_at("ESC PAUSA   /   M SONIDO",ox+384.0,978.0,17,Color("788ca4"),true)

func draw_sequence_puzzle(ox: float) -> void:
    var showing: bool = game.puzzle.puzzle_kind == "sequence" or game.puzzle.puzzle_show_for > 0.0
    if game.puzzle.puzzle_kind == "memory":
        if showing:
            text_at("MEMORIZA: %.1f s" % game.puzzle.puzzle_show_for,ox+384.0,700.0,19,Color("dce0e7"),true)
        else:
            text_at("AHORA REPITE LA SECUENCIA",ox+384.0,700.0,19,Color("dce0e7"),true)
    var count: int = game.puzzle.puzzle_sequence.size()
    var cell_w: float = minf(78.0,570.0/float(count))
    var left: float = ox+384.0-float(count)*cell_w*0.5
    for i in range(count):
        var x: float = left+float(i)*cell_w+4.0
        var correct: bool = i < game.puzzle.puzzle_step
        var tile_color: Color = Color("2c5e62") if correct else Color("192639")
        box_fill(x,727.0,cell_w-8.0,91.0,tile_color)
        panel_line(x,727.0,cell_w-8.0,91.0,Color("66c9bd") if correct else Color("56687d"),2.0)
        var label: String = str(game.puzzle.puzzle_sequence[i]) if showing else "?"
        text_at(label,x+(cell_w-8.0)*0.5,786.0,39,Color("e5ecf5"),true)
    text_at("TECLAS 1, 2, 3, 4",ox+384.0,863.0,23,Color("b6c9dc"),true)
    text_at("PROGRESO %d / %d" % [game.puzzle.puzzle_step,count],ox+384.0,894.0,17,Color("8ba4bd"),true)

func draw_code_puzzle(ox: float) -> void:
    box_fill(ox+194.0,710.0,380.0,109.0,Color("0c1623"))
    panel_line(ox+194.0,710.0,380.0,109.0,Color("7799a7"),2.0)
    text_at(game.puzzle.puzzle_entry+"_",ox+384.0,789.0,58,Color("e2eaf4"),true)
    text_at("TECLEA EL NUMERO  |  ENTER CONFIRMAR",ox+384.0,870.0,20,Color("b3c7d8"),true)
    text_at("RETROCESO PARA BORRAR",ox+384.0,901.0,17,Color("899caf"),true)

func draw_switch_puzzle(ox: float) -> void:
    var count: int = game.puzzle.puzzle_switches.size()
    var cell: float = 100.0
    var start_x: float = ox+384.0-float(count)*cell*0.5
    for i in range(count):
        var x: float = start_x+float(i)*cell+7.0
        var lit: bool = game.puzzle.puzzle_switches[i] == 1
        box_fill(x,720.0,86.0,115.0,Color("255850") if lit else Color("181f2f"))
        panel_line(x,720.0,86.0,115.0,Color("68e9cc") if lit else Color("62728e"),2.0)
        text_at(str(i+1),x+43.0,760.0,23,Color("d6e2ed"),true)
        draw_circle(Vector2(x+43.0,798.0),13.0,Color("76f5c7") if lit else Color("38465c"))
        text_at("OBJETIVO %d" % game.puzzle.puzzle_target[i],x+43.0,855.0,14,Color("c4d4e3"),true)
    text_at("PULSA 1-%d HASTA IGUALAR LOS OBJETIVOS" % count,ox+384.0,900.0,18,Color("a0bad0"),true)

func draw_waiting(ox: float,side: int) -> void:
    box_fill(ox,455.0,768.0,569.0,Color("05070c"))
    box_fill(ox+9.0,463.0,750.0,535.0,Color("090d14"))
    var pulse: float = 0.78+0.15*sin(game.elapsed*2.0)
    text_at("ESPERANDO",ox+384.0,690.0,28,Color(0.51,0.65,0.86,pulse),true)
    text_at("TURNO DEL JUGADOR %d" % (game.active_player+1),ox+384.0,732.0,26,Color(0.51,0.65,0.86,pulse),true)
    text_at("RONDA %d DE 10" % (game.round_index+1),ox+384.0,782.0,19,Color("7b8da9"),true)
    text_at("VIDAS %d  -  PUNTOS %d" % [game.hearts[side],game.points[side]],ox+384.0,832.0,18,Color("6f829a"),true)
    if game.mode == "playing" and game.active_player == game.round_leader and game.hearts[side] > 0:
        text_at("HEREDARAS EL TIEMPO USADO EN EL PARKOUR",ox+384.0,869.0,16,Color("8ba1bf"),true)

func draw_victory_menu() -> void:
    # Cubre la partida solo al terminar el nivel 10; el monstruo ya se fue.
    box_fill(0.0, 0.0, Config.SCREEN_W, Config.SCREEN_H, Color(0.005, 0.015, 0.038, 0.96))
    box_fill(311.0, 151.0, 914.0, 745.0, Color("07111f"))
    panel_line(311.0, 151.0, 914.0, 745.0, Color("3e90bd"), 4.0)
    panel_line(327.0, 167.0, 882.0, 713.0, Color("193b5b"), 2.0)
    box_fill(348.0, 192.0, 840.0, 5.0, Color("45b5e1"))
    text_at("UMBRAL", 768.0, 300.0, 67, Color("67cef8"), true)
    text_at("NIVEL 10 COMPLETADO", 768.0, 355.0, 27, Color("a4c3da"), true)
    var result: String = "EMPATE"
    if int(game.victory_winner) >= 0:
        result = "GANADOR: JUGADOR %d" % (int(game.victory_winner) + 1)
    text_at(result, 768.0, 452.0, 46, Color("f3d18a"), true)
    text_at("VIDAS RESTANTES", 768.0, 514.0, 23, Color("9eb4cd"), true)
    text_at("JUGADOR 1: %d" % game.hearts[0], 593.0, 567.0, 26, Color("d4e9f8"), true)
    text_at("JUGADOR 2: %d" % game.hearts[1], 943.0, 567.0, 26, Color("d4e9f8"), true)
    var labels: Array[String] = ["VOLVER A JUGAR", "SALIR"]
    for i in range(2):
        var rect: Rect2 = Rect2(494.0, 628.0 + float(i) * 91.0, 548.0, 70.0)
        var selected: bool = game.victory_menu_index == i
        if selected:
            box_fill(rect.position.x, rect.position.y, rect.size.x, rect.size.y, Color("10304a"))
            panel_line(rect.position.x, rect.position.y, rect.size.x, rect.size.y, Color("63cfff"), 3.0)
        else:
            panel_line(rect.position.x, rect.position.y, rect.size.x, rect.size.y, Color("2b485d"), 2.0)
        text_at(labels[i], 768.0, rect.position.y + 45.0, 30,
                Color("e7f7ff") if selected else Color("91a8bb"), true)
    text_at("FLECHAS / W S: ELEGIR   -   ENTER: CONFIRMAR", 768.0, 841.0,
            18, Color("8ca6bb"), true)

func draw_modal(title: String,subtitle: String,action: String,detail: String) -> void:
    box_fill(0.0,0.0,Config.SCREEN_W,Config.SCREEN_H,Color(0.0,0.0,0.0,0.76))
    box_fill(350.0,258.0,836.0,503.0,Color("050a13"))
    panel_line(350.0,258.0,836.0,503.0,Color("425772"),4.0)
    box_fill(367.0,276.0,802.0,8.0,Color("b83f57"))
    text_at(title,768.0,388.0,59,Color("e0e7ed"),true)
    text_at(subtitle,768.0,458.0,26,Color("aabdd2"),true)
    text_at(action,768.0,576.0,28,Color("e9c077"),true)
    text_at(detail,768.0,637.0,22,Color("abbcd0"),true)
    text_at("A/D MOVER - ESPACIO SALTAR - SHIFT CORRER",768.0,700.0,17,Color("8294b0"),true)
    text_at("ESC PAUSA - M SONIDO",768.0,727.0,16,Color("8294b0"),true)
