"""Zählt die Zeichen der ausgefüllten Kettenzeilen aus textvorlagen_testfehler_v1.md, Abschnitt 4."""
import re, sys, pathlib

src = pathlib.Path(__file__).with_name("textvorlagen_testfehler_v1.md").read_text(encoding="utf-8")
sec = src.split("## 4.")[1].split("## 5.")[0]
rows = []
for line in sec.splitlines():
    m = re.match(r"\|\s*(\d+(?: \(Wurzel\))?|darunter)\s*\|\s*(.+?)\s*\|$", line)
    if m:
        rows.append(m.group(2))
rows = [r for r in rows if r]
longest = max(rows, key=len)
for r in rows:
    print(f"{len(r):3d}  {r}")
print(f"\n{len(rows)} Zeilen, längste {len(longest)} Zeichen, über 60: {sum(len(r) > 60 for r in rows)}")
sys.exit(1 if any(len(r) > 60 for r in rows) else 0)
