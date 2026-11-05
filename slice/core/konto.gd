extends RefCounted
## AT-01 (S8, Felix): Konto = laufende Kosten, Fixkosten-Akkumulator, Ausgaben, Bankrott.
## Eine Regel, eine Datei (Retro S6 B-1): Jede Ausgabe läuft über charge(). Slice (main.gd) und Welt (ProtoSim) nutzen dieselbe Klasse.
## Reihenfolge in tick() = bisheriger Kostenblock aus main.sim_tick (S7): Fixkosten-Akkumulator, Zins (credit.interest_due), Prüfung Kasse < 0.
## Ganzzahlig in Cent. eco liefert cash_cent und periode_ticks (economy.gd).

var eco = null                       # economy.gd (Kasse)
var running_cost_per_period := 0     # Σ Fixkosten je Periode in Cent (Fahrzeuge + Lager + Gleis)
var cost_acc := 0                    # Akkumulator: running_cost_per_period je Tick, abgebucht in ganzen Cent
var expenses_total := 0              # Summe aller Ausgaben über charge()
var bankrupt := false


func _init(p_eco = null) -> void:
	eco = p_eco


## Ausgabe buchen (Cent).
func charge(cent: int) -> void:
	eco.cash_cent -= cent
	expenses_total += cent


## Laufende Kosten neu: Σ fix_cent der Fahrzeuge + Lager- und Gleisunterhalt (je Periode, Cent).
func fix_neu(liste_fix_cent: Array, lager_cent: int, gleis_cent: int) -> void:
	var c := 0
	for f in liste_fix_cent:
		c += int(f)
	c += lager_cent
	c += gleis_cent
	running_cost_per_period = c


## Ein Tick Kosten. Gibt true zurück, wenn die Kasse danach < 0 ist (dann bankrupt = true).
func tick(tick_nr: int, credit) -> bool:
	var per: int = eco.periode_ticks
	cost_acc += running_cost_per_period
	var c := cost_acc / per
	if c > 0:
		cost_acc -= c * per
		charge(c)
	var zi: int = credit.interest_due(tick_nr)     # F-19: Festzins am Periodenende
	if zi > 0:
		charge(zi)
		credit.interest_paid += zi
	if eco.cash_cent < 0:
		bankrupt = true
		return true
	return false
