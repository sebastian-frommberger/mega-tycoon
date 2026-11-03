#!/usr/bin/env python3
"""Draufsicht-Bilder (2D, matplotlib) fuer Stadt-Rolle: Uebersicht, Dorf Monat 0 / Monat 12, Markt-Ausschnitt."""
import math
import os

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.collections import PatchCollection, LineCollection
from matplotlib.patches import Polygon, Circle, Rectangle

from stadt_geo import (BACH_PUNKTE, MUEHLTEICH_MITTE, MUEHLTEICH_R, SEE_MITTE, SEE_R, X_MIN, Z_MIN, NX, NZ, M_FELD,
                       obb_ecken, BILD_DIR)

FARBEN = {
    "kate": "#c9a27a", "bauernhof": "#b5704a", "grosshof": "#8f4a2e", "handwerkerhaus": "#d1b25f", "buergerhaus": "#c08a8a",
    "kirche_dorf": "#6b6bd1", "kirche_stadt": "#4a4ab8", "gasthaus": "#d97a2b", "schmiede": "#444444", "rathaus": "#b04a7a",
    "speicher": "#8a7a5a", "stadttor": "#222222", "gutshof": "#8a3b1e", "wassermuehle": "#2b7bd9", "fischerhuette": "#2fa39a",
}
FLAECHEN = {"flaeche_garten": "#7fb069", "flaeche_hof": "#d9c9a0", "flaeche_obstwiese": "#9fd07a", "flaeche_kirchhof": "#b9c9a0",
            "flaeche_marktplatz": "#e6dcc0", "flaeche_schlag": "#e3cf8e", "flaeche_anger": "#a9d68c"}
WEGE_FARBE = {"chaussee": ("#7a3b12", 2.6), "dorfstrasse": ("#555555", 1.8), "gasse": ("#777777", 1.3), "feldweg": ("#9a8a60", 1.0)}


def _hintergrund(ax, geo, xl, zl, hoehenlinien=True, aue=True):
    H = geo.H
    ext = (X_MIN, X_MIN + NX * M_FELD, Z_MIN + NZ * M_FELD, Z_MIN)
    ax.imshow(np.clip(H, 35, 80), extent=ext, cmap="Greens_r", alpha=0.35, vmin=35, vmax=80, zorder=0)
    if aue:
        a = np.ma.masked_where(~geo.aue, np.ones(geo.aue.shape))
        ax.imshow(a, extent=ext, cmap="Blues", alpha=0.18, vmin=0, vmax=1.5, zorder=1, interpolation="nearest")
    r = np.ma.masked_where(~geo.rinne, np.ones(geo.rinne.shape))
    ax.imshow(r, extent=ext, cmap="winter", alpha=0.95, vmin=0, vmax=1, zorder=2, interpolation="nearest")
    if hoehenlinien:
        xs = np.linspace(X_MIN, X_MIN + NX * M_FELD, NX + 1)
        zs = np.linspace(Z_MIN, Z_MIN + NZ * M_FELD, NZ + 1)
        ax.contour(xs, zs, H, levels=np.arange(36, 120, 2), colors="#555555", linewidths=0.25, alpha=0.5, zorder=3)
    b = np.array(BACH_PUNKTE)
    ax.plot(b[:, 0], b[:, 1], color="#2f8fd9", lw=1.6, zorder=4)
    ax.add_patch(Circle(SEE_MITTE, SEE_R, fc="#6fb0e0", ec="#2f6fa0", lw=0.8, alpha=0.9, zorder=4))
    ax.add_patch(Circle(MUEHLTEICH_MITTE, MUEHLTEICH_R, fc="#6fb0e0", ec="#2f6fa0", lw=0.6, alpha=0.9, zorder=4))
    ax.set_xlim(*xl)
    ax.set_ylim(zl[1], zl[0])
    ax.set_aspect("equal")


def zeichne(ax, geo, szene, xl, zl, wege=True, instanzen=True, parzellen=None, beschriftung=True, linienbreite=1.0,
            markiere=None, hoehenlinien=True, aue=True, kern_rahmen=True):
    _hintergrund(ax, geo, xl, zl, hoehenlinien, aue)
    if kern_rahmen:
        ax.add_patch(Rectangle((0, 0), 2000, 1600, fill=False, ec="#aa0000", lw=0.8, ls="--", zorder=9))
    if instanzen:
        patches = {}
        for d in szene.inst:
            t = d["typ"]
            if not (xl[0] - 30 <= d["x"] <= xl[1] + 30 and zl[0] - 30 <= d["z"] <= zl[1] + 30):
                continue
            if t in FLAECHEN:
                ec = obb_ecken(d["x"], d["z"], d["b"], d["t"], d["rot_deg"])
                ax.add_patch(Polygon(ec, closed=True, fc=FLAECHEN[t], ec="none", alpha=0.75, zorder=5))
        for d in szene.inst:
            t = d["typ"]
            if not (xl[0] - 30 <= d["x"] <= xl[1] + 30 and zl[0] - 30 <= d["z"] <= zl[1] + 30):
                continue
            if t in FARBEN and "b" in d:
                ec = obb_ecken(d["x"], d["z"], d["b"], d["t"], d["rot_deg"])
                fc = FARBEN[t]
                ax.add_patch(Polygon(ec, closed=True, fc=fc, ec="#222222", lw=0.4, zorder=7))
            elif t == "nebengebaeude":
                ec = obb_ecken(d["x"], d["z"], d["b"], d["t"], d["rot_deg"])
                ax.add_patch(Polygon(ec, closed=True, fc="#e8e0d0", ec="#555555", lw=0.3, zorder=6))
            elif t in ("obstbaum", "laubbaum", "eiche"):
                ax.add_patch(Circle((d["x"], d["z"]), 2.2 if t == "obstbaum" else 5.0, fc="#3f8f3f" if t != "obstbaum" else "#5faa3f",
                                    ec="none", alpha=0.85, zorder=8))
            elif t in ("zaun_latte", "trockenmauer"):
                r = math.radians(d["rot_deg"])
                ex = (math.cos(r), -math.sin(r))
                ax.plot([d["x"] - 1.5 * ex[0], d["x"] + 1.5 * ex[0]], [d["z"] - 1.5 * ex[1], d["z"] + 1.5 * ex[1]], color="#6b4a2b",
                        lw=0.6, zorder=6)
            elif t in ("heuhaufen", "holzstapel", "fass", "amboss", "brunnen", "passant"):
                ax.plot(d["x"], d["z"], marker="o", ms=1.6, color="#aa6600" if t != "passant" else "#cc0000", zorder=8)
            elif t == "steg":
                ec = obb_ecken(d["x"], d["z"], d["b"], d["t"], d["rot_deg"])
                ax.add_patch(Polygon(ec, closed=True, fc="#8b5a2b", ec="#222", lw=0.3, zorder=7))
            elif t == "ruderboot":
                ax.plot(d["x"], d["z"], marker="D", ms=2.5, color="#ffffff", mec="#333", mew=0.3, zorder=8)
    if wege:
        for w in szene.wege:
            f, lw = WEGE_FARBE[w["typ"]]
            pts = np.array([(p[0], p[1]) for p in w["punkte"]])
            ax.plot(pts[:, 0], pts[:, 1], color=f, lw=lw * linienbreite, solid_capstyle="round", zorder=6)
            for br in w.get("bruecken", []):
                ax.plot([br["von"][0], br["bis"][0]], [br["von"][1], br["bis"][1]], color="#ffffff", lw=lw * linienbreite * 1.6, zorder=6.5)
                ax.plot([br["von"][0], br["bis"][0]], [br["von"][1], br["bis"][1]], color="#000000", lw=lw * linienbreite * 0.6, zorder=6.6)
    for st in getattr(szene, "mauer", []):
        pts = np.array(st)
        ax.plot(pts[:, 0], pts[:, 1], color="#3a3a3a", lw=2.2 * linienbreite, solid_capstyle="butt", zorder=6.8)
    if beschriftung:
        for o in szene.orte:
            if xl[0] <= o["x"] <= xl[1] and zl[0] <= o["z"] <= zl[1]:
                ax.annotate("%s\n%s, EW %d" % (o["name"], o["klasse"], o["ew"]), (o["x"], o["z"]), fontsize=7, ha="center", va="bottom",
                            xytext=(0, 18 if False else 6), textcoords="offset points", zorder=12,
                            bbox=dict(boxstyle="round,pad=0.15", fc="white", ec="none", alpha=0.7))
    if markiere:
        for (kind, x, z) in markiere:
            col = {"neu": "#00aa00", "upgrade": "#ff8800", "leerstand": "#888888"}[kind]
            ax.add_patch(Circle((x, z), 7.5, fc="none", ec=col, lw=1.4, zorder=11))
    ax.grid(True, lw=0.2, alpha=0.5)


def speichern(fig, name):
    os.makedirs(BILD_DIR, exist_ok=True)
    pfad = os.path.join(BILD_DIR, name)
    fig.savefig(pfad, dpi=110, bbox_inches="tight")
    plt.close(fig)
    return pfad


# ---------------------------------------------------------------- Bildsatz der Stadt-Rolle
def _wege_dicts(wo, bruecken):
    out = []
    for k, w in wo.items():
        d = {"typ": w.typ, "punkte": w.punkte}
        if k == "chaussee":
            d["bruecken"] = [{"von": b["von"], "bis": b["bis"]} for b in bruecken]
        out.append(d)
    return out


def _orte_label(orte, industrie):
    lab = [{"name": o["name"], "klasse": o["klasse"], "ew": o["ew"], "x": o["x"], "z": o["z"]} for o in orte]
    return lab


def _ausschnitt(ol, rand=45.0):
    xs = [p["cx"] for p in ol.parz]
    zs = [p["cz"] for p in ol.parz]
    return (min(xs) - rand, max(xs) + rand), (min(zs) - rand, max(zs) + rand)


def bilder_erzeugen(geo, szene, wo, bruecken, orte, industrie, wach, ol_d, ol_m, TOR):
    wd = _wege_dicts(wo, bruecken)
    s0 = szene
    s0.wege = wd
    s0.orte = _orte_label(orte, industrie)
    ol12, s12, r12 = wach["mit_versorgung"]
    s12.wege = wd
    s12.orte = []
    xl, zl = _ausschnitt(ol12)
    luecken0 = [("leerstand", p["cx"], p["cz"]) for p in ol_d.parz if p["status"] == "luecke"]
    akt = []
    for a in r12["aktionen"]:
        akt.append(("upgrade" if a["regel"] == "upgrade" else "neu", a["x"], a["z"]))
    # Dorf Monat 0 / Monat 12
    def dorf_panel(ax, sz, mark, titel):
        zeichne(ax, geo, sz, xl, zl, beschriftung=False, markiere=mark, hoehenlinien=False, linienbreite=1.4, kern_rahmen=False)
        ax.set_title(titel, fontsize=10)
    fig, axs = plt.subplots(1, 2, figsize=(17, 7.2))
    ew0 = orte[0]["ew"]
    from stadt_wachstum import ort_ew
    ew12 = ort_ew(ol12, s12)
    dorf_panel(axs[0], s0, luecken0, "Erlenbach Monat 0: EW %d, %d Luecken (grau)" % (ew0, len(luecken0)))
    dorf_panel(axs[1], s12, akt, "Erlenbach Monat 12 (mit Versorgung): EW %d, %d Aktionen (gruen neu, orange Upgrade)" % (ew12, len(akt)))
    fig.tight_layout()
    speichern(fig, "bild_dorf_vorher_nachher.png")
    for nm, sz, mark, titel in (("bild_dorf_monat0.png", s0, luecken0, "Erlenbach Monat 0"), ("bild_dorf_monat12.png", s12, akt, "Erlenbach Monat 12 (mit Versorgung)")):
        fig, ax = plt.subplots(figsize=(11, 7.8))
        zeichne(ax, geo, sz, xl, zl, beschriftung=False, markiere=mark, hoehenlinien=False, linienbreite=1.4, kern_rahmen=False)
        ax.set_title(titel)
        speichern(fig, nm)
    # ohne Versorgung (stabil) als Kontrolle
    olx, sx, rx = wach["ohne_versorgung"]
    sx.wege = wd
    sx.orte = []
    fig, ax = plt.subplots(figsize=(11, 7.8))
    zeichne(ax, geo, sx, xl, zl, beschriftung=False, hoehenlinien=False, linienbreite=1.4, kern_rahmen=False)
    ax.set_title("Erlenbach Monat 12 ohne Versorgung: stabil, EW %d" % ort_ew(olx, sx))
    speichern(fig, "bild_dorf_monat12_ohne_versorgung.png")
    # Gesamtuebersicht
    def gesamt(ax):
        zeichne(ax, geo, s0, (-120, 2120), (-60, 1700), beschriftung=True, hoehenlinien=False, linienbreite=1.2)
        for o in orte:
            ax.add_patch(Circle((o["x"], o["z"]), o["r_m"], fill=False, ec="#cc0066", lw=1.0, ls=":", zorder=10))
        for ind in industrie:
            ax.plot(ind["x"], ind["z"], marker="*", ms=11, color="#ffcc00", mec="#222", mew=0.7, zorder=12)
            ax.annotate(ind["name"] + "\n" + ("Getreidefarm" if ind["typ"] == "getreidefarm" else "Wassermuehle"), (ind["x"], ind["z"]), fontsize=7,
                        xytext=(8, -16), textcoords="offset points", zorder=13, bbox=dict(boxstyle="round,pad=0.15", fc="white", ec="none", alpha=0.75))
        ax.plot(TOR[0], TOR[1], marker="s", ms=6, color="#222222", zorder=12)
        ax.set_title("Gesamtuebersicht Kern 2000 x 1600 m (rot gestrichelt): Orte, Wege, Industrie. Chaussee braun, Bruecken weiss/schwarz")
    fig, ax = plt.subplots(figsize=(17, 11))
    gesamt(ax)
    speichern(fig, "bild_gesamt.png")
    # Markt-Ausschnitt
    fig, ax = plt.subplots(figsize=(13, 9))
    zeichne(ax, geo, s0, (-60, 340), (10, 340), beschriftung=False, hoehenlinien=False, linienbreite=1.6)
    ax.set_title("Lindenfurt, Markt-Ausschnitt (Kernrand NW, Tor am Chaussee-Ende)")
    speichern(fig, "bild_markt.png")
    # Zusammenfassung: eine Tafel
    fig = plt.figure(figsize=(18, 17))
    gs = fig.add_gridspec(2, 2, height_ratios=[1.0, 1.35])
    a1, a2, a3 = fig.add_subplot(gs[0, 0]), fig.add_subplot(gs[0, 1]), fig.add_subplot(gs[1, :])
    dorf_panel(a1, s0, luecken0, "Monat 0: Erlenbach, EW %d, %d Luecken" % (ew0, len(luecken0)))
    dorf_panel(a2, s12, akt, "Monat 12 mit Versorgung: EW %d (gruen neu, orange Upgrade)" % ew12)
    gesamt(a3)
    fig.tight_layout()
    speichern(fig, "uebersicht.png")
