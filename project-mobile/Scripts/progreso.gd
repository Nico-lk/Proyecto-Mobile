extends Node

const RUTA := "user://progreso.cfg"

var niveles := {}
var partes := {"ala": 0, "colmillo": 0, "nucleo": 0}

const NOMBRES_PARTES := {
	"ala": "Alas", "colmillo": "Colmillos", "nucleo": "Núcleos",
}

const MEJORAS := {
	# Personaje
	"vida":      {"nombre": "Casco reforzado",     "max": 5, "parte": "colmillo", "base": 3},
	"armadura":  {"nombre": "Armadura",            "max": 5, "parte": "colmillo", "base": 3},
	"velocidad": {"nombre": "Botas propulsoras",   "max": 5, "parte": "ala",      "base": 4},
	"salto":     {"nombre": "Piernas hidráulicas", "max": 5, "parte": "ala",      "base": 4},
	"sacudida":  {"nombre": "Anti-sanguijuelas",   "max": 2, "parte": "colmillo", "base": 5},
	# Dron
	"dron_cadencia": {"nombre": "Cadencia",        "max": 5, "parte": "ala",      "base": 5},
	"dron_dano":     {"nombre": "Daño",            "max": 5, "parte": "colmillo", "base": 4},
	"dron_crit":     {"nombre": "Prob. crítico",   "max": 5, "parte": "nucleo",   "base": 1},
	"dron_doble":    {"nombre": "Disparo doble",   "max": 3, "parte": "nucleo",   "base": 2},
}

func _init() -> void:
	for id in MEJORAS:
		niveles[id] = 0

func _ready() -> void:
	cargar()
	for p in partes: partes[p] = 99

func costo(id: String) -> int:
	return MEJORAS[id].base * (niveles[id] + 1)

func parte_de(id: String) -> String:
	return MEJORAS[id].parte

func es_maximo(id: String) -> bool:
	return niveles[id] >= MEJORAS[id].max

func comprar(id: String) -> bool:
	var p := parte_de(id)
	if es_maximo(id) or partes[p] < costo(id):
		return false
	partes[p] -= costo(id)
	niveles[id] += 1
	guardar()
	return true

func agregar_parte(p: String, n: int = 1) -> void:
	if partes.has(p):
		partes[p] += n

# --- Personaje ---
func bonus_vida() -> int: return niveles.vida * 20
func reduccion_dano() -> float: return minf(niveles.armadura * 0.08, 0.6)
func mult_velocidad() -> float: return 1.0 + niveles.velocidad * 0.06
func mult_salto() -> float: return 1.0 + niveles.salto * 0.04
func reduccion_sacudidas() -> int: return niveles.sacudida

# --- Dron ---
func mult_cadencia() -> float: return 1.0 + niveles.dron_cadencia * 0.12
func mult_dano_dron() -> float: return 1.0 + niveles.dron_dano * 0.15
func prob_critico() -> float: return niveles.dron_crit * 0.05
func mult_critico() -> float: return 2.0
func prob_doble() -> float: return niveles.dron_doble * 0.25

func guardar() -> void:
	var c := ConfigFile.new()
	c.set_value("p", "partes", partes)
	c.set_value("p", "niveles", niveles)
	c.save(RUTA)

func cargar() -> void:
	var c := ConfigFile.new()
	if c.load(RUTA) != OK:
		return
	var gp: Dictionary = c.get_value("p", "partes", {})
	for p in partes:
		partes[p] = gp.get(p, 0)
	var gn: Dictionary = c.get_value("p", "niveles", {})
	for id in niveles:
		niveles[id] = gn.get(id, 0)
