extends RefCounted
## F-19: Kredit nach Genre-Standard (Transport Tycoon/OpenTTD: Bankkredit in festen Schritten aufnehmen und
## tilgen, eine Obergrenze, fester Zins auf den offenen Betrag). Keine Ratenpläne, keine Bonität, keine
## Zinsmodelle (Refinement S5). Werte aus economy_slice.json, Abschnitt "kredit":
##   credit_limit_cent (Obergrenze), credit_interest_promille_pro_periode (Festzins je Periode = 1 Spielminute),
##   credit_available_from_ticks, credit_active_in_slice_flag.
## Schrittweite aus kredit.credit_step_cent (S6, wie S5-Freeze bei Tobias: 500 $, 4 Schritte bis 2.000 $);
## fehlt der Key (z. B. Test-JSON), gilt STEP_CENT = 500 $ als Rückfall.
## Zins: am Ende jeder Periode rdiv(offen × Zins‰, 1000), Rundung halb auf wie economy.gd.
## BUG-8 (S5): „offen“ ist zeitgewichtet, d. h. der Durchschnitt des offenen Betrags über die Ticks der
## Periode: rdiv(Σ offen×Ticks × Zins‰, 1000 × periode_ticks). Integriert wird nur bei Aufnahme, Tilgung
## und Periodenende (kein Aufwand je Tick). Volle Periode offen = unveränderter Festzins.
## Bankrott bleibt: Kasse < 0 $ (der Kredit muss vorher aufgenommen werden, Genre wie TTD).

const STEP_CENT := 50000

var step_cent := STEP_CENT     # S6: aus dem JSON
var active := false
var limit_cent := 0
var interest_pm := 0
var from_ticks := 0
var periode_ticks := 600
var loan_cent := 0
var interest_paid := 0
var borrowed_total := 0
var _acc := 0                  # BUG-8: Σ offen × Ticks (Cent·Ticks) seit Periodenbeginn
var _acc_tick := 0             # bis zu diesem Tick integriert
var _due_tick := -1            # letzte Fälligkeit (interest_due mehrfach im selben Tick = gleicher Wert)
var _due_val := 0


func setup(eco) -> void:
	var k: Dictionary = eco.slice.get("kredit", {})
	active = bool(k.get("credit_active_in_slice_flag", false))
	limit_cent = int(k.get("credit_limit_cent", 0))
	interest_pm = int(k.get("credit_interest_promille_pro_periode", 0))
	from_ticks = int(k.get("credit_available_from_ticks", 0))
	step_cent = int(k.get("credit_step_cent", STEP_CENT))
	periode_ticks = eco.periode_ticks


func borrow_amount(tick: int) -> int:
	if not active or tick < from_ticks:
		return 0
	return mini(step_cent, limit_cent - loan_cent)


func repay_amount(cash_cent: int) -> int:
	var a := mini(step_cent, loan_cent)
	return a if a <= cash_cent else 0


## Gibt den aufgenommenen Betrag zurück (0 = nicht möglich). Bucht auf die Kasse.
func borrow(eco, tick: int) -> int:
	var a := borrow_amount(tick)
	if a <= 0:
		return 0
	_accrue(tick)
	loan_cent += a
	borrowed_total += a
	eco.cash_cent += a
	return a


func repay(eco, tick: int) -> int:
	var a := repay_amount(eco.cash_cent)
	if a <= 0:
		return 0
	_accrue(tick)
	loan_cent -= a
	eco.cash_cent -= a
	return a


func _accrue(tick: int) -> void:
	_acc += loan_cent * maxi(0, tick - _acc_tick)
	_acc_tick = tick


## Zins dieser Periode (am Periodenende fällig, zeitgewichtet), 0 sonst. Schließt die Periode ab.
func interest_due(tick: int) -> int:
	if tick % periode_ticks != 0:
		return 0
	if tick == _due_tick:
		return _due_val
	_accrue(tick)
	var den := 1000 * periode_ticks
	_due_val = (_acc * interest_pm + den / 2) / den
	_due_tick = tick
	_acc = 0
	return _due_val


func interest_per_period() -> int:
	return (loan_cent * interest_pm + 500) / 1000
