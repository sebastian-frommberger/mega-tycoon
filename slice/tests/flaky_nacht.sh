#!/bin/bash
# QT-02 (S8, Daniel): Flaky-Rate. Volle Regression N-mal hintereinander (nachts), Tabelle "Rot je Suite und Lauf".
# Aufruf (aus slice/ oder von überall):
#   tests/flaky_nacht.sh [--n=5] [--stufe=voll|schnell|beide] [--out=<ordner>] [--godot=<pfad>] [--spikes=<pfad>] [--nur-auswerten=<ordner>]
#   Nachts im Hintergrund:  setsid nohup tests/flaky_nacht.sh --n=5 --out=/tmp/claude-0/flaky_$(date +%F) > /tmp/claude-0/flaky.log 2>&1 &
# Stufen:
#   voll     (Default) je Lauf d07_regression.sh = die volle Regression (nach QT-01b: Bestand, d07_abnahme, d08 n=100, s7_*, perf_s7, Spikes,
#            Statik UND die 11 Proto-Suiten; 35 Zeilen in QT-01b; QT-03c: gemessen 40 Zeilen inkl. s8_bot_smoke und s8_exploit_smoke, 734 s bei Loadavg ca. 2). Messung QT-01: 524 s (24 Zeilen, ohne Last) bzw. 720 s (35 Zeilen, Loadavg bis 3,6) je Lauf,
#            5 Läufe also ca. 45-60 min (Sandbox).
#   schnell  je Lauf nur regress_fast.sh (QT-01b, ca. 70-115 s je Lauf; Test des Werkzeugs und Zwischenstufe).
#   beide    je Lauf d07_regression.sh UND regress_fast.sh (fast hat zusätzlich die statischen Kassen-/Tempo-Checks und Namen je Block; doppelt
#            gerechnete Suiten erscheinen mit Präfix d07:/fast: getrennt, das erhöht die Zellenzahl, nicht die Aussagekraft).
# Ausgabe in <out> (Default /tmp/claude-0/flaky_<Datum>):
#   lauf<i>/d07_regression_summary.md, lauf<i>/fast_summary.md, lauf<i>/info.txt (Exit-Codes, Dauer, Loadavg vor/nach), bei Rot zusätzlich lauf<i>/logs/
#   flaky_tabelle.md   Tabelle Rot je Suite und Lauf, Flake-Rate, Ticketliste
# Wiederaufsetzbar: ein Lauf mit lauf<i>/fertig wird übersprungen (Container-Neustart mitten in der Nacht). Keine Parallelläufe, keine Wanduhr-Grenzen.
# Rot = FAIL in der Summary der jeweiligen Stufe (inkl. TIMEOUT). Ein Lauf, der gar keine Summary erzeugt, zählt als "KEIN ERGEBNIS" für alle Suiten.
# Einordnung (mt-qa): erst Ursache, dann Etikett. Eine Suite, die in ALLEN Läufen rot ist, ist kaputt, nicht flaky. Schuld bei Rot per Vorher-Lauf
# auf gleicher Kopie klären. Quarantäne nur mit Frist, nie löschen. Flake-Rate Richtwert: Google ca. 0,15 %, ab ca. 1 % verlieren Tests Wert.
N=5; STUFE=voll; OUT=""; G=${GODOT:-/tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64}; SPIKES=/home/claude/mega-tycoon/spikes; ONLY=""
for a in "$@"; do
  case "$a" in
    --n=*) N="${a#--n=}" ;;
    --stufe=*) STUFE="${a#--stufe=}" ;;
    --out=*) OUT="${a#--out=}" ;;
    --godot=*) G="${a#--godot=}" ;;
    --spikes=*) SPIKES="${a#--spikes=}" ;;
    --nur-auswerten=*) ONLY="${a#--nur-auswerten=}" ;;
    *) echo "unbekannte Option $a"; exit 2 ;;
  esac
done
HERE="$(cd "$(dirname "$0")/.." && pwd)"
[ -n "$ONLY" ] && OUT="$ONLY"
[ -z "$OUT" ] && OUT=/tmp/claude-0/flaky_$(date +%F)
mkdir -p "$OUT" || exit 2
OUT=$(cd "$OUT" && pwd)

auswerten() {
python3 -I - "$OUT" "$STUFE" > "$OUT/flaky_tabelle.md" <<'PY'
import sys, os, re, glob
out, stufe = sys.argv[1], sys.argv[2]
laeufe = sorted(glob.glob(os.path.join(out, "lauf*")), key=lambda p: int(re.sub(r"\D", "", os.path.basename(p)) or 0))
def parse(pfad, quelle):
    """Summary lesen -> {suite: (status, detail)}; d07: | Suite | Ergebnis | Detail |, fast: | Schritt | Ergebnis | Sekunden | Detail |"""
    res = {}
    if not os.path.exists(pfad):
        return None
    for l in open(pfad, encoding="utf-8"):
        if not l.startswith("|") or l.startswith("|---") or l.startswith("| Suite") or l.startswith("| Schritt"):
            continue
        c = [x.strip() for x in l.strip().strip("|").split("|")]
        if len(c) < 3 or c[1] not in ("OK", "FAIL"):
            continue
        detail = c[-1]
        res[f"{quelle}: {c[0]}"] = (c[1], detail)
    return res
tab, namen, kopf = {}, [], []
for lp in laeufe:
    nr = int(re.sub(r"\D", "", os.path.basename(lp)))
    kopf.append(nr)
    erg = {}
    for quelle, datei in (("d07", "d07_regression_summary.md"), ("fast", "fast_summary.md")):
        if (stufe == "schnell" and quelle == "d07") or (stufe == "voll" and quelle == "fast"):
            continue
        r = parse(os.path.join(lp, datei), quelle)
        if r is None:
            erg[f"{quelle}: (Summary fehlt)"] = ("KEIN", "Summary nicht erzeugt")
        else:
            erg.update(r)
    for s, v in erg.items():
        if s not in namen:
            namen.append(s)
    tab[nr] = erg
n = len(kopf)
print(f"# Flaky-Rate ({n} Läufe, Stufe {stufe})\n")
if n == 0:
    print("Keine Läufe gefunden.")
    sys.exit(0)
print("| Suite | " + " | ".join(f"Lauf {k}" for k in kopf) + " | Rot | Einordnung |")
print("|---|" + "---|" * n + "---|---|")
rot_zellen, zellen, melden, kaputt = 0, 0, [], []
for s in namen:
    zeile, rot, da = [], 0, 0
    for k in kopf:
        v = tab[k].get(s)
        if v is None:
            zeile.append("–")
            continue
        da += 1
        if v[0] == "OK":
            zeile.append("ok")
        else:
            rot += 1
            zeile.append("**ROT (T)**" if "TIMEOUT" in v[1] else "**ROT**")
    zellen += da
    rot_zellen += rot
    if rot == 0:
        ein = ""
    elif rot == da:
        ein = "in allen Läufen rot: kaputt, nicht flaky"
        kaputt.append(s)
    else:
        ein = f"flaky ({rot}/{da}): Ticket"
        melden.append((s, rot, da))
    print(f"| {s} | " + " | ".join(zeile) + f" | {rot}/{da} | {ein} |")
print()
rate = 100.0 * rot_zellen / zellen if zellen else 0.0
print(f"Zellen (Suite x Lauf): {zellen}, davon rot: {rot_zellen}, Rot-Rate {rate:.2f} %. Richtwert: Google ca. 0,15 %, ab ca. 1 % verlieren Tests Wert (mt-qa).")
print(f"Suiten mit mindestens 1 Rot: {len(melden) + len(kaputt)} → Ticket je Suite (flaky: {len(melden)}, durchgehend rot: {len(kaputt)}).")
for s, r, d in melden:
    print(f"- flaky: {s} ({r}/{d})")
for s in kaputt:
    print(f"- durchgehend rot: {s}")
print("\n## Läufe\n")
for lp in laeufe:
    info = os.path.join(lp, "info.txt")
    print(f"### {os.path.basename(lp)}")
    print(open(info, encoding="utf-8").read().strip() if os.path.exists(info) else "(keine info.txt)")
    print()
print("Messart: Wanduhr, Sandbox (2 vCPU), Suiten nacheinander, andere Agenten können parallel Last erzeugen (Loadavg je Lauf in info.txt). Keine FPS-/Zielrechner-Aussage.")
PY
cat "$OUT/flaky_tabelle.md"
}

if [ -n "$ONLY" ]; then auswerten; exit 0; fi

echo "flaky_nacht: n=$N stufe=$STUFE out=$OUT godot=$G ($(date '+%F %T'))"
cd "$HERE" || exit 2
[ -d .godot ] || "$G" --headless --path . --import >/dev/null 2>&1
for i in $(seq 1 "$N"); do
  D="$OUT/lauf$i"
  if [ -f "$D/fertig" ]; then echo "Lauf $i bereits fertig, übersprungen"; continue; fi
  rm -rf "$D"; mkdir -p "$D"
  T0=$(date +%s); LOAD0=$(cut -d' ' -f1-3 /proc/loadavg)
  r1=0; r2=0
  rm -f tests/d07_regression_summary.md tests/fast_summary.md
  if [ "$STUFE" = voll ] || [ "$STUFE" = beide ]; then
    bash tests/d07_regression.sh "$G" "$SPIKES" > "$D/d07_stdout.txt" 2>&1; r1=$?
    cp -f tests/d07_regression_summary.md "$D/" 2>/dev/null
  fi
  if [ "$STUFE" = schnell ] || [ "$STUFE" = beide ]; then
    bash tests/regress_fast.sh "$G" > "$D/fast_stdout.txt" 2>&1; r2=$?
    cp -f tests/fast_summary.md "$D/" 2>/dev/null
  fi
  if [ "$r1" != 0 ] || [ "$r2" != 0 ]; then
    mkdir -p "$D/logs"; cp -r tests/d07_logs "$D/logs/" 2>/dev/null; cp -r tests/fast_logs "$D/logs/" 2>/dev/null
  fi
  T1=$(date +%s)
  { echo "- Start $(date -d @"$T0" '+%F %T'), Dauer $((T1-T0)) s, Loadavg vor/nach: $LOAD0 / $(cut -d' ' -f1-3 /proc/loadavg)"
    echo "- Stufe $STUFE, Exit d07_regression.sh: $r1, regress_fast.sh: $r2 (0 = grün oder nicht gelaufen)"
    echo "- Git: $(git -C "$HERE" rev-parse --short HEAD 2>/dev/null), Godot: $("$G" --version 2>/dev/null | head -1)"; } > "$D/info.txt"
  date +%s > "$D/fertig"
  echo "Lauf $i/$N fertig: Dauer $((T1-T0)) s, Exit d07=$r1 fast=$r2"
done
auswerten
