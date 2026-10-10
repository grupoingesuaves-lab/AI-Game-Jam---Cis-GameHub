extends RefCounted
## Reglas y colores compartidos: evita números repetidos en el código.

const SCREEN_W: float = 1536.0
const SCREEN_H: float = 1024.0
const PANEL_W: float = 768.0
const STAGE_TOP: float = 450.0
const MAX_ROUNDS: int = 10
const MAX_HEARTS: int = 3
const PARKOUR_LIMIT: float = 120.0
const PUZZLE_LIMIT: float = 60.0
const GRAVITY: float = 1050.0
const SPEED: float = 275.0
const JUMP: float = -500.0

const ROUND_NAMES: Array[String] = [
    "LA GRUA", "BOSQUE EMBRUJADO", "CATACUMBAS", "FABRICA ABANDONADA",
    "CIUDAD NEON", "CUEVA DE CRISTALES", "PUERTO FANTASMA",
    "VOLCAN", "CASTILLO DE HIELO", "TEMPLO DEL DESIERTO"
]
const STAGE_COLORS: Array[Color] = [
    Color("d6b249"), Color("70c58c"), Color("b68c75"), Color("d9a44c"),
    Color("ed59bc"), Color("58e4de"), Color("7db6a0"),
    Color("ff9a40"), Color("9ed6f8"), Color("f1bb75")
]
