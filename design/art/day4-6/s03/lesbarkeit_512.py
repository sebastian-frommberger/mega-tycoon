# S-03: Geometrie-Rechnung Kamerahoehe vs. Sichtfeld und Pixelmass fuer 512-Karte (5.120 m).
# Reine Rechnung, keine Messung. FOV 40 Grad vertikal, 16:9, Neigung 70 Grad (Kartenstufe).
import math
VFOV=40.0; ASPECT=16/9
def width_at(h, pitch_deg):
    d_center = h/math.sin(math.radians(pitch_deg))
    return 2*d_center*math.tan(math.radians(VFOV/2))*ASPECT
def depth_at(h, pitch_deg):
    near = pitch_deg+VFOV/2; far = pitch_deg-VFOV/2
    gn = 0.0 if near>=90 else h/math.tan(math.radians(near))
    gf = h/math.tan(math.radians(far))
    return gf-gn
MAP=5120.0
print("Hoehe  Breite  Tiefe  m/px(720p,Mitte)  m/px(1080p)")
for h in (1000,2000,3000,3700,4000,5000,6100,7400):
    w=width_at(h,70); d=depth_at(h,70)
    print(f"{h:5d}  {w:6.0f}  {d:6.0f}  {w/1280:6.2f}  {w/1920:6.2f}")
print("Hoehe fuer volle Kartenbreite (70 Grad):", MAP/ (width_at(1,70)))
print("Hoehe fuer volle Kartentiefe  (70 Grad):", MAP/ (depth_at(1,70)))
print("Hoehe fuer volle Karte senkrecht (90 Grad, Tiefe begrenzt):", MAP/(2*math.tan(math.radians(VFOV/2))))
print()
print("Objektgroessen in px bei 4000 m / 70 Grad (720p | 1080p):")
mpp=width_at(4000,70)/1280; mpp2=width_at(4000,70)/1920
for name,m in (("Dorf 15 Felder",150),("Kleinstadt 30",300),("Stadt 50",500),("Fabrik St.1 8 Felder",80),("Fabrik St.4 15",150),("Farmfeld 30",300),("Gleis 0,5 Feld",5),("Strasse 1 Feld",10),("Zug 20 Felder",200),("Lkw 1 Feld",10)):
    print(f"  {name:22s} {m/mpp:6.1f} px | {m/mpp2:6.1f} px")
