extends RefCounted
## U-03 (S7, Mira): Fehler- und Hinweistexte nach Aylins Liste (sprints/s7/block-a/fehlertexte.md, D21).
## Regel: Ursache + Lösung, max. 90 Zeichen (nach Einsetzen typischer Werte), Du-Form, kein Rohcode.
## Kennungen B/S/L/K/U = Zeilen der Liste. Zahlen kommen immer aus dem Spielwert (Aufrufer übergibt Cent/Felder),
## Distanzen über main.dist_str (Slice "N Felder", S7 m/km). Tests: tests/s7_u03_test.gd.

const MAX_LEN := 90


## Kredit-Hinweis nur, solange der Rahmen frei ist (Aylin: sonst „warte auf Einnahmen“).
static func kredit_frei(m) -> bool:
	return m.credit.active and not kredit_gesperrt(m) and m.credit.loan_cent < m.credit.limit_cent


## T-15 (Tobias): Kredit erst ab kredit.credit_available_from_ticks (JSON), vorher grau.
static func kredit_gesperrt(m) -> bool:
	return m.credit.active and m.shim.tick_count < m.credit.from_ticks


## „Kredit ab Minute 12 verfügbar (noch 3:20)“ – Minute und Rest aus credit.from_ticks und der Spielzeit.
static func kredit_ab(m) -> String:
	return "Kredit ab Minute %s verfügbar (noch %s)" % [kredit_minute(m), m.time_str(maxi(0, m.credit.from_ticks - m.shim.tick_count))]


static func kredit_minute(m) -> String:
	var mins: float = m.credit.from_ticks * m.tick_ms / 60000.0
	return str(int(mins)) if is_equal_approx(mins, roundf(mins)) else String.num(mins, 1).replace(".", ",")


# ---------------------------------------------------------------- 1 Bau

static func b1_bruecke_diagonal() -> String:
	return "Brücke geht nur geradeaus. Baue bis zum Ufer, dann gerade hinüber."


static func b2_bruecke_zu_lang(m, n: int) -> String:
	return "Der Fluss ist hier %s breit, Brücken schaffen %s. Such eine schmalere Stelle." % [m.dist_str(n), m.dist_str(m.BRIDGE_MAX)]


static func b3_brueckenkopf() -> String:
	return "Die Brücke braucht festen Boden an beiden Ufern. Ziehe bis ans Land drüben."


static func b4_gebaeude(name: String) -> String:
	return "%s steht im Weg. Führe die Strecke außen herum." % name


## Z-01: Stadt mitten im Weg (nicht in Aylins Liste, gleiche Form wie B4).
static func b4_stadt(name: String) -> String:
	return "%s liegt im Weg. Führe die Strecke außen herum oder ende am Stadtrand." % name


static func b6_gleis_stadt() -> String:
	return "Gleise dürfen nicht durch die Stadt. Ziehe zum Bahnhof am Stadtrand."


static func b7_aussen() -> String:
	return "Hier endet die Karte. Ziehe die Strecke zurück ins Spielfeld."


static func b8_geld(m, need: int) -> String:
	var d: int = need - m.eco.cash_cent
	if kredit_frei(m):
		return "Es fehlen %s. Nimm Kredit (Knopf neben der Kasse) oder baue kürzer." % m.money_str(d)
	if kredit_gesperrt(m):
		return "Es fehlen %s. Baue kürzer, Kredit gibt es ab Minute %s." % [m.money_str(d), kredit_minute(m)]
	return "Es fehlen %s. Warte auf Einnahmen oder baue kürzer." % m.money_str(d)


static func b9_vorhanden() -> String:
	return "Hier liegt schon eine Strecke. Ziehe zu einem Ziel, das noch nicht verbunden ist."


static func b10_kein_ziel() -> String:
	return "Ziehe die Maus bis zum Ziel und lass dort los. Esc bricht ab."


## B11 (S7): Steigung in Prozent (ganzzahlig gerundet) aus dem Spielwert.
static func b11_zu_steil(pct: float, max_pct: float) -> String:
	return "Zu steil: %d %% Steigung, erlaubt %d %%. Führe die Strecke am Hang entlang." % [int(round(pct)), int(round(max_pct))]


## B12 (S7, Hinweis): Hang-Faktor in Promille (1000 = flach) und Gesamtpreis.
static func b12_hang(m, faktor_pm: int, total: int) -> String:
	return "Hang: Bau ×%s teurer. Gesamt %s." % [faktor_str(faktor_pm), m.money_str(total)]


static func faktor_str(pm: int) -> String:
	return ("%.2f" % (pm / 1000.0)).replace(".", ",")


static func b14_abriss_fremd() -> String:
	return "Stadtstraßen und Gebäude bleiben stehen. Markiere nur eigene Strecken."


static func b15_lager_platz() -> String:
	return "Lager braucht 2×2 freie Wiese: nicht auf Wasser, Berg, Straße, Gebäude."


static func b16_lager_geld(m, price: int) -> String:
	return "Lager kostet %s, es fehlen %s. %s" % [m.money_str(price), m.money_str(price - m.eco.cash_cent), _kredit_oder_warten(m)]


static func b17_lager_hinweis() -> String:
	return "Lager bringt allein kein Geld: Bezahlt wird erst beim Endabnehmer."


# ---------------------------------------------------------------- 2 Stadtanschluss

static func s1_anschluss(city: String) -> String:
	return "Anschluss an %s: Die Strecke endet am Stadtrand (Punkt ▼)." % city


static func s2_nicht_anschliessbar(city: String) -> String:
	return "%s ist von hier nicht anschließbar. Wähle eine andere Seite der Stadt." % city


# ---------------------------------------------------------------- 3 Linien, Fahrzeuge, Lizenz, Kredit

## L1/S3: keine Verbindung. Ist das Ziel eine Stadt, nennt der Text den Stadtrand (S3).
static func l1_keine_verbindung(a: String, b: String, rail: bool, b_is_city: bool) -> String:
	var weg := "das Gleis" if rail else "die Straße"
	if b_is_city:
		return "Zwischen %s und %s fehlt %s. Baue %s bis zum Stadtrand von %s." % [a, b, weg, "es" if rail else "sie", b]
	return "Zwischen %s und %s fehlt %s. Baue %s mit [%s] und setz die Linie neu." % [a, b, weg, "es" if rail else "sie", "2" if rail else "1"]


static func l2_liefert_nichts(name: String) -> String:
	return "%s liefert nichts. Starte die Linie bei Farm, Mine, Mühle oder Lager." % name


static func l3_keine_lizenz(name: String) -> String:
	return "%s hat keine Lizenz. Kaufe sie im Panel (Klick auf das Gebäude)." % name


static func l4_nimmt_nicht(ziel: String, ware: String) -> String:
	return "%s nimmt %s nicht an. Wähle einen Abnehmer, der sie braucht (Panel)." % [ziel, ware]


static func l5_leeres_feld() -> String:
	return "Klicke ein Gebäude an: erst die Quelle, dann das Ziel."


static func l6_fahrzeug_geld(m, kind: String, price: int) -> String:
	return "%s kostet %s, es fehlen %s. %s" % [kind, m.money_str(price), m.money_str(price - m.eco.cash_cent), _kredit_oder_warten(m)]


static func l7_schon(name: String) -> String:
	return "%s ist schon lizenziert." % name


static func l8_lizenz_geld(m, price: int) -> String:
	return "Lizenz kostet %s, es fehlen %s. %s" % [m.money_str(price), m.money_str(price - m.eco.cash_cent), _kredit_oder_warten(m)]


static func l9_lizenz_sonst(code: String) -> String:
	return "Lizenz gerade nicht möglich. Bitte erneut klicken (Meldung an uns: %s)." % code


static func l10_keine_lizenz_noetig() -> String:
	return "Dieses Gebäude braucht keine Lizenz."


static func l11_verlaengert(m, name: String, cent: int) -> String:
	return "%s: Lizenz verlängert für %s." % [name, m.money_str(cent)]


## L11b: Verlängerung scheitert an der Kasse (nicht in Aylins Liste, B-xx S7).
static func l11_abgelaufen(m, name: String, cent: int) -> String:
	return "%s: Lizenz abgelaufen, Verlängerung kostet %s. Neu kaufen im Panel." % [name, m.money_str(cent)]


static func l12_kredit_voll(m) -> String:
	return "Kreditrahmen %s ist voll. Tilge Schulden oder warte auf Einnahmen." % m.money_str(m.credit.limit_cent)


static func l13_tilgen(m, cent: int) -> String:
	return "Zum Tilgen fehlen %s in der Kasse. Warte auf Einnahmen." % m.money_str(cent)


static func l14_tempo8(n: int) -> String:
	return "8× geht nur bis %d Fahrzeuge. Tempo bleibt bei 4×." % n


static func l15_gratis_rueckkauf() -> String:
	return "Gratis-Lkw: Rückkauf 0 $, der Gratis-Platz ist verbraucht."


# ---------------------------------------------------------------- 4 Kasse und Bankrott

## K1: t_sec = Spielsekunden bis 0 $, posten = Name des größten Verlustpostens, cent_min = Verlust je Spielminute.
static func k1_vorwarnung(m, t_sec: int, posten: String, cent_min: int) -> String:
	var hilfe := "Kredit nehmen oder Linie auflösen." if kredit_frei(m) else (
		"Linie auflösen, Kredit erst ab Minute %s." % kredit_minute(m) if kredit_gesperrt(m) else "Linie auflösen oder Fahrzeuge verkaufen.")
	return "Kasse reicht noch ~%s. Größter Verlust: %s (−%s/min). %s" % [zeit_kurz(t_sec), posten, m.money_str(cent_min), hilfe]


static func k2_bankrott(m, posten: String, cent_min: int) -> String:
	return "Bankrott: %s kostete %s/min, die Kasse war leer. Beim nächsten Mal früher Kredit." % [posten, m.money_str(cent_min)]


static func zeit_kurz(sec: int) -> String:
	if sec < 60:
		return "%d s" % maxi(sec, 0)
	return "%d:%02d min" % [sec / 60, sec % 60]


# ---------------------------------------------------------------- 5 Begriffe

static func u1_ertrag(m, cent: int) -> String:
	return "Ertrag ca. %s je Spielminute" % m.money_str(cent)


static func u4_skillpunkt() -> String:
	return "Skillpunkt verdient. Er wartet, bis der Skilltree kommt."


static func u6_ring(mss: String) -> String:
	return "HQ noch %s min kostenlos verschiebbar (Ring anklicken)" % mss


static func u10_kasse_tip() -> String:
	return "Unter 0 $ bist du bankrott. Ein Kredit (Knopf rechts daneben) verschafft dir Zeit."


## Lizenz-Panel: Knopf grau mit Fehlbetrag (L8).
static func l8_panel(m, miss: int) -> String:
	return "Dir fehlen %s. %s" % [m.money_str(miss), "Nimm im Kopfbereich einen Kredit auf [+]." if kredit_frei(m) else _kredit_oder_warten(m)]


static func _kredit_oder_warten(m) -> String:
	if kredit_frei(m):
		return "Nimm Kredit oder warte auf Einnahmen."
	if kredit_gesperrt(m):
		return "Warte auf Einnahmen (Kredit ab Minute %s)." % kredit_minute(m)
	return "Warte auf Einnahmen."
