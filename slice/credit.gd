extends RefCounted
## F-19: Kredit nach Genre-Standard (Transport Tycoon/OpenTTD: Bankkredit in festen Schritten aufnehmen und
## tilgen, eine Obergrenze, fester Zins auf den offenen Betrag). Keine Ratenpläne, keine Bonität, keine
## Zinsmodelle (Refinement S5). Werte aus economy_slice.json, Abschnitt "kredit":
##   credit_limit_cent (Obergrenze), credit_interest_promille_pro_periode (Festzins je Periode = 1 Spielminute),
##   credit_available_from_ticks, credit_active_in_slice_flag.
## ANNAHME (nicht im JSON, Schema ist additionalProperties:false -> Vorschlag an Tobias): Schrittweite
## STEP_CENT = 500 $ (Genre: feste Kreditschritte; 4 Schritte bis zum Rahmen von 2.000 $).
## Zins: am Ende jeder Periode rdiv(offen × Zins‰, 1000), Rundung halb auf wie economy.gd.
## Bankrott bleibt: Kasse < 0 $ (der Kredit muss vorher aufgenommen werden, Genre wie TTD).

const STEP_CENT := 50000

var active := false
var limit_cent := 0
var interest_pm := 0
var from_ticks := 0
var periode_ticks := 600
var loan_cent := 0
var interest_paid := 0
var borrowed_total := 0


func setup(eco) -> void:
	var k: Dictionary = eco.slice.get("kredit", {})
	active = bool(k.get("credit_active_in_slice_flag", false))
	limit_cent = int(k.get("credit_limit_cent", 0))
	interest_pm = int(k.get("credit_interest_promille_pro_periode", 0))
	from_ticks = int(k.get("credit_available_from_ticks", 0))
	periode_ticks = eco.periode_ticks


func borrow_amount(tick: int) -> int:
	if not active or tick < from_ticks:
		return 0
	return mini(STEP_CENT, limit_cent - loan_cent)


func repay_amount(cash_cent: int) -> int:
	var a := mini(STEP_CENT, loan_cent)
	return a if a <= cash_cent else 0


## Gibt den aufgenommenen Betrag zurück (0 = nicht möglich). Bucht auf die Kasse.
func borrow(eco, tick: int) -> int:
	var a := borrow_amount(tick)
	if a <= 0:
		return 0
	loan_cent += a
	borrowed_total += a
	eco.cash_cent += a
	return a


func repay(eco) -> int:
	var a := repay_amount(eco.cash_cent)
	if a <= 0:
		return 0
	loan_cent -= a
	eco.cash_cent -= a
	return a


## Zins dieser Periode (am Periodenende fällig), 0 sonst.
func interest_due(tick: int) -> int:
	if loan_cent <= 0 or tick % periode_ticks != 0:
		return 0
	return (loan_cent * interest_pm + 500) / 1000


func interest_per_period() -> int:
	return (loan_cent * interest_pm + 500) / 1000
