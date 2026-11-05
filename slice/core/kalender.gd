extends RefCounted
## FZ-02 (S8, Felix): Zwei Uhren. Die Wirtschaft rechnet in Ticks (Periode 600 Ticks = 1 Spielminute, Zins,
## Fix, Lizenzlaufzeit). Der Kalender liefert nur Datum, Fahrzeugalter in Jahren und Freischaltungen nach Jahr.
## Kein Wirtschaftswert liest den Kalender (Test: Wirtschafts-Prüfsumme bei jahr_ticks 1.800 und 7.200 gleich).
## PO 05.11.: Welt-Loop jahr_ticks = 1.800 (3 min/Jahr, Monat = 150 Ticks); Slice bleibt 7.200 (spielmonat_ticks 600 × 12).
## Quelle: data/economy_proto.json "kalender"; `--jahr_ticks=N` (z. B. 450 für Zeitsprung-Tests) überschreibt.

const MONATE := ["Jan", "Feb", "Mär", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"]
const PROTO_JSON := "res://data/economy_proto.json"
const JAHR_TICKS_STANDARD := 1800

var startjahr := 1820
var jahr_ticks := JAHR_TICKS_STANDARD


func _init(p_startjahr := 1820, p_jahr_ticks := JAHR_TICKS_STANDARD) -> void:
	startjahr = p_startjahr
	jahr_ticks = maxi(12, p_jahr_ticks)


## Welt-Kalender: jahr_ticks aus economy_proto.json (kalender.jahr_ticks), Nutzerargument --jahr_ticks= gewinnt.
static func fuer_welt(p_startjahr: int):
	var jt := JAHR_TICKS_STANDARD
	if FileAccess.file_exists(PROTO_JSON):
		var d = JSON.parse_string(FileAccess.get_file_as_string(PROTO_JSON))
		if d is Dictionary and d.get("kalender", {}) is Dictionary:
			jt = int(d.get("kalender", {}).get("jahr_ticks", jt))
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--jahr_ticks=") and a.substr(13).is_valid_int():
			jt = int(a.substr(13))
	return load("res://core/kalender.gd").new(p_startjahr, jt)


func monat_ticks() -> int:
	return jahr_ticks / 12


func jahr(tick: int) -> int:
	return startjahr + maxi(0, tick) / jahr_ticks


## Monat 0–11 im laufenden Jahr.
func monat(tick: int) -> int:
	return (maxi(0, tick) % jahr_ticks) / monat_ticks()


func datum_text(tick: int) -> String:
	return "%s %d" % [MONATE[mini(monat(tick), 11)], jahr(tick)]


## Jahreswechsel genau in diesem Tick (Tick > 0).
func jahreswechsel(tick: int) -> bool:
	return tick > 0 and tick % jahr_ticks == 0


## Alter in ganzen Kalenderjahren (Alterung FZ-03).
func alter_jahre(alter_ticks: int) -> int:
	return maxi(0, alter_ticks) / jahr_ticks
