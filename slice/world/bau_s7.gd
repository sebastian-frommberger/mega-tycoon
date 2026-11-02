extends RefCounted
## W-04 (S7, Mira): Hang-Preis und Steigungssperre für den Streckenbau – nur bei --welt=s7 (main.world_s7 != null).
## Der Slice ruft nichts davon auf (bitgleich).
##
## Schnittstelle zu Felix (W-02, world/s7_world.gd). Alle drei Hooks sind optional; fehlen sie, gilt der Platzhalter:
##   hoehe_at(cell: Vector2i, grid: int) -> float     Höhe in Metern je Feld (gibt es seit Block A, heute 0 = flach)
##   steigung_faktor(pct: float) -> float             Baukostenfaktor bei pct % Steigung (1.0 = flach).  Platzhalter 1.0
##   steigung_max_pct() -> float                      Sperre "zu steil" ab diesem Wert (%).               Platzhalter: keine Sperre
## Steigung eines Feldes = größte Steigung zu seinen Nachbarn im Pfad (|Δh| / m_pro_feld × 100). Die Sim bleibt in Feldern,
## es gibt kein Steigungstempo (Refinement S7, Streitprotokoll "Höhe in der Sim").

const PLATZHALTER_PM := 1000
const FT := preload("res://ui/fehlertexte.gd")


static func aktiv(m) -> bool:
	return m.world_s7 != null


static func hoehe_m(m, c: Vector2i) -> float:
	if m.world_s7 == null or not m.world_s7.has_method("hoehe_at") or not m._in_grid(c):
		return 0.0
	return float(m.world_s7.hoehe_at(c, m.GRID))


## Steigung in % zwischen zwei benachbarten Feldern.
static func steigung_pct(m, a: Vector2i, b: Vector2i) -> float:
	var d := maxf(1.0, float(absi(a.x - b.x) + absi(a.y - b.y)))
	return absf(hoehe_m(m, b) - hoehe_m(m, a)) / (m.m_pro_feld * d) * 100.0


## Steigung je Pfadfeld (größte zum Vorgänger/Nachfolger).
static func steigungen(m, cells: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(cells.size())
	for i in cells.size():
		var s := 0.0
		if i > 0:
			s = maxf(s, steigung_pct(m, cells[i - 1], cells[i]))
		if i < cells.size() - 1:
			s = maxf(s, steigung_pct(m, cells[i], cells[i + 1]))
		out[i] = s
	return out


## Baukostenfaktor in Promille (1000 = flach).
static func faktor_pm(m, pct: float) -> int:
	if m.world_s7 != null and m.world_s7.has_method("steigung_faktor"):
		return maxi(1000, int(round(float(m.world_s7.steigung_faktor(pct)) * 1000.0)))
	return PLATZHALTER_PM


## Höchste erlaubte Steigung in %, INF = keine Sperre (Platzhalter).
static func max_pct(m) -> float:
	if m.world_s7 != null and m.world_s7.has_method("steigung_max_pct"):
		return float(m.world_s7.steigung_max_pct())
	return INF


## Auf eine Planung (main._plan_cells) anwenden: Preis neuer Felder × Hangfaktor, Felder über der Sperre rot (B11).
## Gibt {"faktor_pm": größter Faktor eines neuen Feldes, "extra": Aufschlag in Cent, "max_pct": steilstes Feld} zurück.
static func apply(m, cells: Array, items: Array) -> Dictionary:
	var st := steigungen(m, cells)
	var lim := max_pct(m)
	var fmax := 1000
	var extra := 0
	var smax := 0.0
	for i in items.size():
		var it: Dictionary = items[i]
		if it["state"] != "new":
			continue
		smax = maxf(smax, st[i])
		if st[i] > lim:
			it["state"] = "bad"
			it["reason"] = FT.b11_zu_steil(st[i], lim)
			continue
		var f := faktor_pm(m, st[i])
		if f > 1000:
			var c2: int = int(it["cost"]) * f / 1000
			extra += c2 - int(it["cost"])
			it["cost"] = c2
			fmax = maxi(fmax, f)
	return {"faktor_pm": fmax, "extra": extra, "max_pct": smax}
