#!/bin/bash
# QT-03c (S8, Daniel): Rauchtest für Loop-Bot (s8_loop_bot.gd) und Exploit-Sweep (s8_exploit.gd). Aufruf: tests/s8_bot_smoke.sh <bot|exploit> [godot] [logdir]
# Ausgabe: Zeilen "  OK ..." / "  FAIL ..." und am Ende "Prüfungen OK: n/m" (regress_fast/d07 lesen das). Exit 0 nur, wenn alles OK.
# bot:     n=2 alle Strategien (6 Läufe), k=1. Prüft: Exit 0; keine Zeile "ERROR" im Log (ein GDScript-Formatfehler beendet den Bot NICHT mit Exit 1,
#          er schreibt dann eine kaputte CSV: gesehen beim Umbau QT-03c); Determinismus "OK" (Seed 1 doppelt, Zeile + Prüfsumme); CSV hat 6 Zeilen
#          und in jeder Zeile gleich viele Felder wie die Kopfzeile; Abgleich Kasse/Lieferungen ohne Meldung (der Bot setzt sonst "Abgleich" in die Ausgabe).
#          Misst keine Bänder (n=2 ist dafür zu klein): Drift der Zahlen zeigt QT-03c/n=300, nicht dieser Test.
# exploit: X1 mit 2 Strecken, Getreide, einmal a=1000 (2x, md5 gleich = deterministisch) und einmal --a=2000 (echter Haken in ProtoSim):
#          Ertrag je Zelle = 2 x Ertrag(1000) (Rundung: höchstens 1 Cent je Lieferung), gleiche Liefermenge E.
G=${2:-/tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64}
LOG=${3:-/tmp/claude-0/s8_smoke_$$}
HERE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$HERE" || exit 2
mkdir -p "$LOG"
ok=0; bad=0
chk() { if [ "$1" = 1 ]; then ok=$((ok+1)); echo "  OK   $2"; else bad=$((bad+1)); echo "  FAIL $2"; fi; }
case "$1" in
bot)
  timeout -k 5 300 "$G" --headless --path . -s res://tests/s8_loop_bot.gd -- --n=2 --strategie=alle --tempo_k=1 --csv="$LOG/bot.csv" > "$LOG/bot.txt" 2>&1; r=$?
  chk $([ $r -eq 0 ] && echo 1 || echo 0) "Bot Exit 0 (Exit $r)"
  chk $([ "$(grep -c '^ERROR\|SCRIPT ERROR' "$LOG/bot.txt")" = 0 ] && echo 1 || echo 0) "keine ERROR-Zeile im Log"
  chk $(grep -q "Determinismus: OK" "$LOG/bot.txt" && echo 1 || echo 0) "Determinismus OK (Seed 1 je Strategie doppelt)"
  chk $([ "$(grep -c 'Abgleich' "$LOG/bot.txt")" = 0 ] && echo 1 || echo 0) "Abgleich Kasse/Lieferungen ohne Meldung"
  python3 -I - "$LOG/bot.csv" > "$LOG/bot_csv.txt" 2>&1 <<'PY'
import csv, sys
try:
    rows = list(csv.reader(open(sys.argv[1], newline="", encoding="utf-8")))
    kopf = rows[0]
    print("ZEILEN", len(rows) - 1, "OK" if len(rows) - 1 == 6 else "FALSCH")
    print("FELDER", "OK" if all(len(r) == len(kopf) for r in rows) else "UNGLEICH")
except Exception as e:
    print("ZEILEN", 0, "FALSCH", e); print("FELDER UNGLEICH")
PY
  chk $(grep -q "^ZEILEN 6 OK" "$LOG/bot_csv.txt" && echo 1 || echo 0) "CSV hat 6 Läufe (2 Seeds x 3 Strategien)"
  chk $(grep -q "^FELDER OK" "$LOG/bot_csv.txt" && echo 1 || echo 0) "CSV: jede Zeile so viele Felder wie die Kopfzeile"
  ;;
exploit)
  A="--modus=x1 --strecken=20,60 --gueter=getreide --minuten=20 --warm=5 --tempo_k=1"
  for v in a b; do
    timeout -k 5 300 "$G" --headless --path . -s res://tests/s8_exploit.gd -- $A --csv="$LOG/x_$v.csv" > "$LOG/x_$v.txt" 2>&1; r=$?
    chk $([ $r -eq 0 ] && [ "$(grep -c '^ERROR\|SCRIPT ERROR' "$LOG/x_$v.txt")" = 0 ] && echo 1 || echo 0) "Exploit Lauf $v: Exit 0, keine ERROR-Zeile (Exit $r)"
  done
  chk $([ "$(md5sum < "$LOG/x_a.csv")" = "$(md5sum < "$LOG/x_b.csv")" ] && echo 1 || echo 0) "Exploit deterministisch (zwei Läufe, gleiche CSV)"
  timeout -k 5 300 "$G" --headless --path . -s res://tests/s8_exploit.gd -- $A --a=2000 --csv="$LOG/x_a2000.csv" > "$LOG/x_a2000.txt" 2>&1; r=$?
  chk $([ $r -eq 0 ] && echo 1 || echo 0) "Exploit mit --a=2000: Exit 0 (Exit $r)"
  python3 -I - "$LOG/x_a.csv" "$LOG/x_a2000.csv" > "$LOG/x_a_vgl.txt" 2>&1 <<'PY'
import csv, sys
try:
    a = list(csv.DictReader(open(sys.argv[1], newline="", encoding="utf-8")))
    b = list(csv.DictReader(open(sys.argv[2], newline="", encoding="utf-8")))
    ok_e = len(a) == len(b) and len(a) > 0 and all(x["e"] == y["e"] for x, y in zip(a, b))
    # Rundung: yield_cent rundet einmal mehr (a != 1000); je Lieferung höchstens 1 Cent -> Toleranz 0,2 % bzw. 50 Cent
    ok_x = len(a) == len(b) and len(a) > 0 and all(abs(int(y["ertrag_cent"]) - 2 * int(x["ertrag_cent"])) <= max(50, 0.002 * 2 * int(x["ertrag_cent"])) for x, y in zip(a, b))
    print("E_GLEICH", "OK" if ok_e else "FALSCH"); print("ERTRAG_X2", "OK" if ok_x else "FALSCH", [(x["n_fz"], x["ertrag_cent"], y["ertrag_cent"]) for x, y in zip(a, b)][:3])
except Exception as e:
    print("E_GLEICH FALSCH", e); print("ERTRAG_X2 FALSCH")
PY
  chk $(grep -q "^E_GLEICH OK" "$LOG/x_a_vgl.txt" && echo 1 || echo 0) "--a=2000: gleiche Liefermenge E wie a=1000 (a wirkt nur auf Geld)"
  chk $(grep -q "^ERTRAG_X2 OK" "$LOG/x_a_vgl.txt" && echo 1 || echo 0) "--a=2000: Ertrag = 2 x Ertrag(a=1000) (Haken in der Welt, Rundung <= 0,2 %)"
  ;;
*) echo "Aufruf: $0 <bot|exploit> [godot] [logdir]"; exit 2 ;;
esac
echo "Prüfungen OK: $ok/$((ok+bad))"
[ $bad -eq 0 ]
