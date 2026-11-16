"""Tüm şehri organik (gerçekçi) bir Chicago-1920 haritası olarak yeniden üretir. Tekrar çalıştırılabilir.
Üretilenler:
  assets/environment/terrain/yukseklik.png  (1 px = 0.5 m; göl, nehir, Hilltop tepesi)
  assets/environment/terrain/renk.png       (yol, kaldırım, park, su, tren hattı)
  data/sokak_ag.json                        (lamba, ağaç, köprü/iskele güverteleri)
  scenes/city/harita.tscn                   (Binalar düğümleri yeniden yazılır; adlı işletmeler korunur)
Kullanım:  python tools/sehir_uret2.py
"""
import json, math, random, re
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi

KOK = Path(__file__).resolve().parent.parent
TSCN = KOK / "scenes/city/harita.tscn"
RENK = KOK / "assets/environment/terrain/renk.png"
YUK = KOK / "assets/environment/terrain/yukseklik.png"
SOKAK = KOK / "data/sokak_ag.json"
K = 2.0   # şehir ölçeği (1 = ilk küçük harita, 2 = her yönde iki kat)
X0, Z0, GEN, DER = -182.0 * K, -258.0 * K, 364.0 * K, 594.0 * K
MIN_H, MAX_H = -4.0, 18.0
S = 2                      # piksel / metre
W, H = int(GEN * S), int(DER * S)
rng = random.Random(1920)
nrng = np.random.default_rng(1920)
_TABAN = {"docks": ("Docks", -152, 152, 190, 266), "downtown": ("Downtown", 0, 152, -228, -76),
          "eastside": ("Eastside", 0, 152, -76, 76), "flats": ("The Flats", -152, 152, 76, 190),
          "hilltop": ("Hilltop", -152, 0, -228, -76), "southside": ("Southside", -152, 0, -76, 76)}
BOL = {k: {"ad": v[0], "x0": v[1] * K, "x1": v[2] * K, "z0": v[3] * K, "z1": v[4] * K} for k, v in _TABAN.items()}
(KOK / "data/bolgeler.json").write_text(json.dumps(BOL, indent=1, ensure_ascii=False), encoding="utf-8")
KALDIRIM = 2.2
ZEMIN = 2.0                # kara seviyesi
SU_DIP = -3.0

I, J = np.meshgrid(np.arange(W), np.arange(H))
XX = X0 + (I + 0.5) / S
ZZ = Z0 + (J + 0.5) / S


def gurultu(olcek_m, genlik=1.0):
    a = ndi.gaussian_filter(nrng.normal(size=(H, W)), olcek_m * S)
    return a / (a.std() + 1e-9) * genlik


def inreg(x, z, pay=0.0):
    for k, b in BOL.items():
        if b["x0"] + pay <= x <= b["x1"] - pay and b["z0"] + pay <= z <= b["z1"] - pay:
            return k
    return ""


# ---------------- su: göl + nehir ----------------
def kiyi(x):
    u = x / K
    return K * (238 + 7 * np.sin(u / 37.0) + 4 * np.sin(u / 13.0 + 1) + 5 * np.sin(u / 71.0 + 2))


def nehir_x(z):
    u = z / K
    return K * (2 + 6 * np.sin(u / 55.0) + 3 * np.sin(u / 23.0 + 1))


def nehir_yari(z):
    return 10 + 3 * np.sin(z / 82.0 + 2)


GOL = ZZ > kiyi(XX)
NEHIR = np.abs(XX - nehir_x(ZZ)) < nehir_yari(ZZ)
SU = GOL | NEHIR
d_su = ndi.distance_transform_edt(~SU) / S          # karada sudan uzaklık (m)

# ---------------- yükseklik ----------------
taban = ZEMIN + gurultu(14, 0.12) + gurultu(40, 0.12)
taban += 14.0 * np.exp(-(((XX + 85 * K) ** 2 + (ZZ + 150 * K) ** 2) / (2 * (48.0 * K) ** 2)))   # Hilltop tepesi
sd = d_su - ndi.distance_transform_edt(SU) / S
t = np.clip((sd + 2.0) / 6.0, 0, 1)
t = t * t * (3 - 2 * t)
HM = SU_DIP + (taban - SU_DIP) * t
pix = np.clip(np.round((HM - MIN_H) / (MAX_H - MIN_H) * 255), 0, 255).astype(np.uint8)
HQ = pix.astype(np.float32) / 255 * (MAX_H - MIN_H) + MIN_H
Image.fromarray(pix, "L").save(YUK)


def yuk(x, z):
    i = min(max(int((x - X0) * S), 0), W - 1)
    j = min(max(int((z - Z0) * S), 0), H - 1)
    return float(HQ[j, i])


# ---------------- yollar ----------------
yollar = []   # {pts(n,2), w, sinif:'ana'|'yan'|'ray', sari, gec}


def yeniden_ornekle(p, adim=2.0):
    p = np.asarray(p, float)
    seg = np.hypot(*np.diff(p, axis=0).T)
    s = np.concatenate([[0], np.cumsum(seg)])
    n = max(2, int(s[-1] / adim) + 1)
    u = np.linspace(0, s[-1], n)
    return np.stack([np.interp(u, s, p[:, 0]), np.interp(u, s, p[:, 1])], axis=1)


def yol_ekle(pts, w, sinif, sari=False, gec=False, kes_su=True):
    pts = yeniden_ornekle(pts)
    ok = np.array([inreg(x, z) != "" for x, z in pts])
    if kes_su and not gec:
        ok &= np.array([d_su[min(max(int((z - Z0) * S), 0), H - 1), min(max(int((x - X0) * S), 0), W - 1)] >= 7.0 for x, z in pts])
    # ardışık parçalara böl
    i = 0
    n = len(pts)
    while i < n:
        if not ok[i]:
            i += 1
            continue
        k = i
        while k < n and ok[k]:
            k += 1
        if k - i >= 8:
            yollar.append({"pts": pts[i:k], "w": w, "sinif": sinif, "sari": sari, "gec": gec})
        i = k


# ana caddeler (eksene paralel; nehri köprüyle geçerler)
XM, ZA, ZB = 152 * K, -228 * K, 266 * K
for z, w in [(-304, 8), (-228, 8), (-152, 10), (-76, 12), (0, 14), (76, 12), (152, 10), (228, 8), (304, 10), (380, 8)]:
    yol_ekle([(-XM, z), (XM, z)], w, "ana", sari=(w >= 12), gec=True)
for x, w in [(-228, 9), (-152, 11), (-76, 11), (76, 11), (152, 11), (228, 9)]:
    yol_ekle([(x, ZA), (x, ZB)], w, "ana", sari=(w >= 11))
# tren hattı (Flats), nehri demir köprüyle geçer
yol_ekle([(-XM, 236), (XM, 236)], 6, "ray", gec=True)
# çapraz caddeler
yol_ekle([(300, 104), (224, -40), (120, -220), (44, -452)], 10, "ana", sari=True)
yol_ekle([(-300, 376), (-236, 300), (-164, 216), (-24, 156)], 9, "ana")
yol_ekle([(-300, -250), (-200, -330), (-110, -420)], 8, "ana")
yol_ekle([(300, 330), (230, 250), (160, 180), (40, 120)], 9, "ana")


def izgara(reg, aci, sa, sb, w, warp=0.0, lam=70.0, birak=0.12):
    b = BOL[reg]
    cx, cz = (b["x0"] + b["x1"]) / 2, (b["z0"] + b["z1"]) / 2
    R = max(b["x1"] - b["x0"], b["z1"] - b["z0"])
    a = math.radians(aci)
    d1 = (math.cos(a), math.sin(a))
    n1 = (-math.sin(a), math.cos(a))
    ph = rng.uniform(0, 6)
    for eksen in (0, 1):
        sp = sa if eksen == 0 else sb
        d, n = (d1, n1) if eksen == 0 else (n1, d1)
        for k in range(-int(R / sp) - 1, int(R / sp) + 2):
            if rng.random() < birak:
                continue
            off = (k + 0.5) * sp + rng.uniform(-3, 3)
            t0, t1 = -R, R
            if rng.random() < 0.25:
                if rng.random() < 0.5:
                    t0 = rng.uniform(-R * 0.6, 0)
                else:
                    t1 = rng.uniform(0, R * 0.6)
            pts = []
            for t_ in np.arange(t0, t1, 2.0):
                x = cx + n[0] * off + d[0] * t_
                z = cz + n[1] * off + d[1] * t_
                if warp:
                    x += warp * math.sin(z / lam + ph)
                    z += warp * math.cos(x / lam + ph)
                if b["x0"] <= x <= b["x1"] and b["z0"] <= z <= b["z1"]:
                    pts.append((x, z))
            if len(pts) > 8:
                yol_ekle(pts, w, "yan")


izgara("southside", 7, 40, 38, 6, 1.5, 90, 0.5)
izgara("hilltop", -22, 46, 42, 6, 7.0, 60, 0.5)
izgara("downtown", 10, 36, 34, 7, 1.0, 90, 0.4)
izgara("eastside", -9, 44, 40, 6, 3.0, 90, 0.55)
izgara("flats", 0, 46, 40, 6, 2.0, 100, 0.5)
izgara("docks", 0, 110, 60, 7, 1.5, 100, 0.2)

# ---------------- yol maskeleri ----------------
M_KALDIR = Image.new("L", (W, H), 0)
M_ASFALT = Image.new("L", (W, H), 0)
M_RAY = Image.new("L", (W, H), 0)
dk, da, dr = ImageDraw.Draw(M_KALDIR), ImageDraw.Draw(M_ASFALT), ImageDraw.Draw(M_RAY)


def px(p):
    return [((x - X0) * S, (z - Z0) * S) for x, z in p]


def cizgi(draw, pts, genislik_m):
    pp = px(pts)
    gw = max(1, int(round(genislik_m * S)))
    draw.line(pp, fill=255, width=gw, joint="curve")
    r = gw / 2
    for (x, y) in (pp[0], pp[-1]):
        draw.ellipse([x - r, y - r, x + r, y + r], fill=255)


for y in yollar:
    if y["sinif"] == "ray":
        cizgi(dr, y["pts"], y["w"])
    else:
        cizgi(dk, y["pts"], y["w"] + 2 * KALDIRIM)
for y in yollar:
    if y["sinif"] != "ray":
        cizgi(da, y["pts"], y["w"])
KALDIR = np.array(M_KALDIR) > 0
ASFALT = np.array(M_ASFALT) > 0
RAY = np.array(M_RAY) > 0

# ---------------- köprüler ve iskeleler ----------------
guverte = []   # {x,z,y,w,d,renk}
for y in yollar:
    if not y["gec"]:
        continue
    zc = float(y["pts"][0][1])
    satir = NEHIR[int((zc - Z0) * S)]
    xs_ = np.where(satir)[0]
    if len(xs_) == 0:
        continue
    xa, xb = X0 + xs_.min() / S - 5, X0 + (xs_.max() + 1) / S + 5
    ray = y["sinif"] == "ray"
    guverte.append({"x": (xa + xb) / 2, "z": zc, "y": ZEMIN + 0.05, "w": xb - xa, "d": y["w"] + (1.0 if not ray else 0.5),
                    "renk": [0.30, 0.30, 0.32] if not ray else [0.22, 0.2, 0.2]})
for xp in range(-270, 300, 54):
    zk = float(kiyi(xp))
    z_a, z_b = zk - 8, min(zk + 24, ZB - 3)
    guverte.append({"x": xp, "z": (z_a + z_b) / 2, "y": ZEMIN, "w": 7.0, "d": z_b - z_a, "renk": [0.36, 0.27, 0.18]})
PIER = np.zeros((H, W), bool)
for g in guverte:
    PIER[int((g["z"] - g["d"] / 2 - Z0) * S):int((g["z"] + g["d"] / 2 - Z0) * S) + 1,
         int((g["x"] - g["w"] / 2 - X0) * S):int((g["x"] + g["w"] / 2 - X0) * S) + 1] = True

# ---------------- parsel / bina yerleştirme ----------------
OCC = ndi.binary_dilation(KALDIR | RAY, iterations=1)
OCC |= d_su < 5.5
OCC |= ndi.binary_dilation(PIER, iterations=3)
disarisi = np.ones((H, W), bool)
for k, b in BOL.items():
    disarisi[(XX >= b["x0"] + 2.5) & (XX <= b["x1"] - 2.5) & (ZZ >= b["z0"] + 2.5) & (ZZ <= b["z1"] - 2.5)] = False
OCC |= disarisi
LOTMASK = np.zeros((H, W), bool)

TUGLA = [(0.55, 0.30, 0.25), (0.59, 0.36, 0.31), (0.50, 0.27, 0.22), (0.62, 0.40, 0.30), (0.66, 0.55, 0.38), (0.55, 0.52, 0.48), (0.48, 0.30, 0.26), (0.60, 0.34, 0.22)]
TAS = [(0.70, 0.67, 0.60), (0.58, 0.58, 0.60), (0.66, 0.60, 0.50), (0.50, 0.50, 0.52), (0.72, 0.70, 0.64)]
DEPO = [(0.45, 0.30, 0.24), (0.40, 0.33, 0.28), (0.36, 0.38, 0.40), (0.50, 0.36, 0.26), (0.42, 0.26, 0.20)]
VILLA = [(0.82, 0.78, 0.66), (0.78, 0.74, 0.70), (0.70, 0.78, 0.68), (0.85, 0.82, 0.74), (0.66, 0.56, 0.44)]
FABRIKA = [(0.38, 0.27, 0.22), (0.33, 0.28, 0.26), (0.43, 0.30, 0.22), (0.30, 0.26, 0.25)]

TIP = {
    "southside": dict(w=(9, 16), d=(10, 14), kat=[3, 3, 4, 4, 5], kh=3.6, set=(0.2, 0.8), pal=TUGLA, ana=1),
    "downtown": dict(w=(14, 26), d=(12, 16), kat=[5, 6, 7, 8], kh=3.8, set=(0.2, 0.6), pal=TAS, ana=3),
    "eastside": dict(w=(8, 15), d=(9, 13), kat=[3, 4, 4, 5, 6], kh=3.6, set=(0.2, 0.8), pal=TUGLA, ana=1),
    "hilltop": dict(w=(11, 17), d=(10, 14), kat=[2, 3, 3], kh=3.4, set=(1.0, 3.0), pal=VILLA, ana=0),
    "flats": dict(w=(10, 16), d=(10, 15), kat=[3, 4, 4, 5], kh=3.4, set=(0.2, 0.8), pal=TUGLA, ana=0),
    "docks": dict(w=(13, 30), d=(10, 15), kat=[1, 2], kh=5.5, set=(0.4, 1.5), pal=DEPO, ana=0),
}


def kutu_noktalari(cx, cz, th, w, d, pay, adim=0.4):
    c, s = math.cos(th), math.sin(th)
    U, V = np.meshgrid(np.arange(-w / 2 - pay, w / 2 + pay + 0.01, adim), np.arange(-d / 2 - pay, d / 2 + pay + 0.01, adim))
    X = cx + U * c + V * s
    Z = cz - U * s + V * c
    i = ((X - X0) * S).astype(int)
    j = ((Z - Z0) * S).astype(int)
    return j, i


lotlar = []


def lot_dene(cx, cz, th, w, d, reg):
    c, s = math.cos(th), math.sin(th)
    for sx in (-1, 1):
        for sz in (-1, 1):
            x = cx + sx * w / 2 * c + sz * d / 2 * s
            z = cz - sx * w / 2 * s + sz * d / 2 * c
            if inreg(x, z, 2.5) != reg:
                return False
    j, i = kutu_noktalari(cx, cz, th, w, d, 0.3)
    if j.min() < 0 or i.min() < 0 or j.max() >= H or i.max() >= W:
        return False
    if OCC[j, i].any():
        return False
    j2, i2 = kutu_noktalari(cx, cz, th, w, d, 0.2)
    j2 = np.clip(j2, 0, H - 1)
    i2 = np.clip(i2, 0, W - 1)
    OCC[j2, i2] = True
    j3, i3 = kutu_noktalari(cx, cz, th, w, d, 0.0, 0.3)
    LOTMASK[np.clip(j3, 0, H - 1), np.clip(i3, 0, W - 1)] = True
    return True


def lotla(y, sira_no=0):
    p = y["pts"]
    seg = np.hypot(*np.diff(p, axis=0).T)
    sc = np.concatenate([[0], np.cumsum(seg)])
    L = sc[-1]

    def at(s):
        return np.array([np.interp(s, sc, p[:, 0]), np.interp(s, sc, p[:, 1])])

    for yan in (-1, 1):
        s = 1.0
        while s < L - 4:
            ilk = at(min(s + 6, L))
            ilk2 = at(min(s + 7, L))
            tt = (ilk2 - ilk) / (np.hypot(*(ilk2 - ilk)) + 1e-9)
            reg0 = inreg(*(ilk + np.array([-tt[1], tt[0]]) * yan * (y["w"] / 2 + 12)))
            tp = TIP.get(reg0)
            if tp is None:
                s += 4
                continue
            wl = rng.uniform(*tp["w"])
            d = rng.uniform(*tp["d"])
            fab = False
            if reg0 == "flats" and rng.random() < 0.45:
                wl, d, fab = rng.uniform(24, 38), rng.uniform(14, 20), True
            if s + wl > L:
                break
            a, b = at(s), at(s + wl)
            m = (a + b) / 2
            T = (b - a) / (np.hypot(*(b - a)) + 1e-9)
            N = np.array([-T[1], T[0]]) * yan
            sb_ = rng.uniform(*tp["set"])
            off = y["w"] / 2 + KALDIRIM + 1.1 + sb_ + d / 2 + sira_no * 13.5
            cx, cz = m[0] + N[0] * off, m[1] + N[1] * off
            th = math.atan2(-T[1], T[0])
            reg = inreg(cx, cz)
            if reg == reg0 and lot_dene(cx, cz, th, wl - 0.5, d, reg):
                kat = rng.choice(tp["kat"])
                if y["sinif"] == "ana":
                    kat += tp["ana"] if reg != "downtown" else rng.choice([2, 4, 6])
                kh = tp["kh"]
                pal = tp["pal"]
                if fab:
                    kat, kh, pal = rng.choice([2, 2, 3]), 5.2, FABRIKA
                lotlar.append({"cx": cx, "cz": cz, "th": th, "w": wl - 0.5, "d": d, "reg": reg, "kat": kat, "kh": kh,
                               "renk": rng.choice(pal), "ana": y["sinif"] == "ana"})
                s += wl + rng.uniform(0.2, 1.5)
            else:
                s += 3.5


for sira_no in (0, 1, 2):
    for y in sorted((y for y in yollar if y["sinif"] != "ray"), key=lambda q: (q["sinif"] != "ana", -q["w"])):
        lotla(y, sira_no)

# ---------------- boşlukları doldur: en yakın yola dönük ek parseller ----------------
from scipy.spatial import cKDTree
ornek, teget, ygen, yid = [], [], [], []
for ki, y in enumerate(yollar):
    if y["sinif"] == "ray":
        continue
    p = y["pts"]
    t = np.gradient(p, axis=0)
    t /= (np.hypot(t[:, 0], t[:, 1])[:, None] + 1e-9)
    yid.append(np.full(len(p), ki))
    ornek.append(p)
    teget.append(t)
    ygen.append(np.full(len(p), y["w"]))
ornek, teget, ygen, yid = np.concatenate(ornek), np.concatenate(teget), np.concatenate(ygen), np.concatenate(yid)
agac_ = cKDTree(ornek)
for gecis in range(2):
    adaylar = []
    for gx in np.arange(X0 + 4, X0 + GEN - 4, 2.0):
        for gz in np.arange(Z0 + 4, Z0 + DER - 4, 2.0):
            r = inreg(gx, gz, 3)
            if not r or r not in TIP:
                continue
            if OCC[int((gz - Z0) * S), int((gx - X0) * S)]:
                continue
            dist, k = agac_.query([gx, gz])
            if dist > ygen[k] / 2 + KALDIRIM + 45:
                continue
            adaylar.append((dist + rng.uniform(0, 9), gx, gz, k))
    adaylar.sort()
    for _, gx, gz, k in adaylar:
        if OCC[int((gz - Z0) * S), int((gx - X0) * S)]:
            continue
        reg = inreg(gx, gz)
        tp = TIP[reg]
        wl0, d0, fab = rng.uniform(*tp["w"]), rng.uniform(*tp["d"]), False
        if reg == "flats" and rng.random() < 0.4:
            wl0, d0, fab = rng.uniform(24, 38), rng.uniform(14, 20), True
        T = teget[k]
        th0 = math.atan2(-T[1], T[0])
        for sc_, dth in ((1.0, 0.0), (0.8, 0.0), (0.65, 0.0), (0.8, 0.35), (0.65, -0.35), (0.55, 0.0)):
            th = th0 + dth
            wl, d = wl0 * sc_, d0 * sc_
            if wl < 7 or d < 7:
                continue
            if lot_dene(gx, gz, th, wl, d, reg):
                kat = rng.choice(tp["kat"])
                kh = tp["kh"]
                pal = tp["pal"]
                if fab:
                    kat, kh, pal = rng.choice([2, 2, 3]), 5.2, FABRIKA
                lotlar.append({"cx": gx, "cz": gz, "th": th, "w": wl, "d": d, "reg": reg, "kat": kat, "kh": kh,
                               "renk": rng.choice(pal), "ana": False})
                break

# ---------------- tscn ----------------
s_ = TSCN.read_text(encoding="utf-8")
editable = re.findall(r"^\[editable [^\n]*\]\s*$", s_, flags=re.M)
s_ = re.sub(r"^\[editable [^\n]*\]\s*$", "", s_, flags=re.M)
parcalar = re.split(r"\n(?=\[node )", s_)
kalan, isletmeler = [], []
for p in parcalar:
    if 'parent="Binalar"' in p:
        if "dolgu = true" not in p:
            ad = re.search(r'\bad = "([^"]*)"', p)
            isletmeler.append({"isim": re.search(r'name="([^"]+)"', p).group(1), "ad": ad.group(1) if ad else "",
                               "bolge": re.search(r'bolge = "(\w+)"', p).group(1), "ozel": "ozel = true" in p})
        continue
    if re.search(r'parent="(Kaideler|Iskeleler|Deniz)"', p) or re.match(r'\[node name="(Kaideler|Iskeleler|Deniz)"', p):
        continue
    kalan.append(p)

atama = {}
for reg in BOL:
    L = [l for l in lotlar if l["reg"] == reg]
    ms = BOL[reg]
    mx, mz = (ms["x0"] + ms["x1"]) / 2, (ms["z0"] + ms["z1"]) / 2
    ad_ = [b for b in isletmeler if b["bolge"] == reg]
    ozel = [b for b in ad_ if b["ozel"]]
    norm = [b for b in ad_ if not b["ozel"]]
    L.sort(key=lambda l: (l["cx"] - mx) ** 2 + (l["cz"] - mz) ** 2)
    print("%-10s lot %3d  işletme %2d" % (reg, len(L), len(ad_)))
    if len(L) < len(ad_):
        print("  !! yetersiz parsel:", reg)
    for b in ozel:
        atama[id(L.pop(0))] = b
    rng.shuffle(L)
    # büyük cephe/çok katlı olanlar işletme olsun: önce rastgele
    for b in norm:
        if L:
            atama[id(L.pop())] = b

yeni = []
sayac = 0
for l in lotlar:
    c, s = math.cos(l["th"]), math.sin(l["th"])
    zem = [yuk(l["cx"] + sx * l["w"] / 2 * c + sz * l["d"] / 2 * s, l["cz"] - sx * l["w"] / 2 * s + sz * l["d"] / 2 * c)
           for sx in (-1, 0, 1) for sz in (-1, 0, 1)]
    taban_y = min(zem) - 0.25
    h = l["kat"] * l["kh"] + 1.0 + (max(zem) - taban_y)
    r, g, b = l["renk"]
    b_ = atama.get(id(l))
    if b_:
        ad, isim, ozel, dol = b_["ad"], b_["isim"], b_["ozel"], False
    else:
        sayac += 1
        ad, isim, ozel, dol = "", "Dolgu_%d" % sayac, False, True
    t = [round(v, 5) for v in (c, 0, s, 0, 1, 0, -s, 0, c)] + [round(l["cx"], 2), round(taban_y, 3), round(l["cz"], 2)]
    blok = '[node name="%s" parent="Binalar" instance=ExtResource("3_vwpxd")]\n' % isim
    blok += "transform = Transform3D(%s)\n" % ", ".join(str(v) for v in t)
    blok += 'ad = "%s"\nbolge = "%s"\n' % (ad, l["reg"])
    if ozel:
        blok += "ozel = true\n"
    if dol:
        blok += "dolgu = true\n"
    blok += "boyut = Vector3(%.2f, %.2f, %.2f)\nrenk = Color(%.3f, %.3f, %.3f, 1)\n" % (l["w"], h, l["d"], r, g, b)
    yeni.append(blok.rstrip("\n"))
# işletme adları aynı sırada (oyun yerler sırasına güvenir): adlı düğümleri orijinal sırada öne al
sira = {b["isim"]: k for k, b in enumerate(isletmeler)}
yeni.sort(key=lambda bl: sira.get(re.search(r'name="([^"]+)"', bl).group(1), 10 ** 6))
cikti = []
for p in kalan:
    cikti.append(p)
    if p.startswith('[node name="Binalar"'):
        cikti.extend(yeni)
TSCN.write_text("\n".join(cikti).rstrip("\n") + "\n\n" + "\n".join(editable) + "\n", encoding="utf-8")
print("toplam parsel:", len(lotlar), "dolgu:", sayac, "yerleşen işletme:", len(atama), "/", len(isletmeler))

# ---------------- doku ----------------
tex = np.zeros((H, W, 3), np.float32)
ci = gurultu(3, 1.0)
CIM = np.array([74, 104, 62], np.float32)
tex[:] = CIM + ci[..., None] * np.array([6, 7, 5])
bolge_ici = ~disarisi | ndi.binary_dilation(~disarisi, iterations=5)
ZEMIN_R = np.array([112, 104, 92], np.float32) + gurultu(1.2, 1.0)[..., None] * 4
# blok içi zemin: bölge dikdörtgenlerinin birleşimi
birlesim = np.zeros((H, W), bool)
for k, b in BOL.items():
    birlesim[(XX >= b["x0"]) & (XX <= b["x1"]) & (ZZ >= b["z0"]) & (ZZ <= b["z1"])] = True
tex[birlesim] = ZEMIN_R[birlesim]
# parklar: bina/yol olmayan geniş boşluklar
bos = birlesim & ~OCC & ~KALDIR & ~RAY & ~LOTMASK & ~SU
dist = ndi.distance_transform_edt(bos) / S
cekirdek = dist >= 4.5
park = ndi.binary_dilation(cekirdek, iterations=int(4.5 * S)) & bos
lab, n = ndi.label(park)
alan = ndi.sum(park, lab, range(1, n + 1)) / (S * S)
park = np.isin(lab, [k + 1 for k in range(n) if alan[k] > 160])
PARK_R = np.array([66, 116, 56], np.float32) + ci[..., None] * np.array([6, 9, 5])
tex[park] = PARK_R[park]
# kıyı kumu
kum = (d_su < 3.2) & ~SU
tex[kum] = np.array([188, 172, 128], np.float32) + ci[kum][:, None] * 5
tex[SU] = np.array([34, 74, 96], np.float32) + ci[SU][:, None] * 3
tex[KALDIR] = (150, 147, 140)
tex[ASFALT] = np.array([58, 58, 62], np.float32) + gurultu(0.8, 1.0)[ASFALT][:, None] * 2.5
tex[RAY] = (88, 84, 78)
im = Image.fromarray(np.clip(tex, 0, 255).astype(np.uint8), "RGB")
d = ImageDraw.Draw(im)
SARI, BEYAZ = (214, 178, 60), (200, 200, 196)
# tren traverseleri ve rayları
for y in yollar:
    if y["sinif"] == "ray":
        z = float(y["pts"][0][1])
        for x in np.arange(-XM, XM, 0.9):
            d.line(px([(x, z - 2.4), (x, z + 2.4)]), fill=(58, 44, 34), width=1)
        for dz in (-0.7, 0.7):
            d.line(px([(-XM, z + dz), (XM, z + dz)]), fill=(150, 150, 154), width=1)
# sarı şerit (diğer yollarla kesişen yerleri atla)
tum = [(q["pts"], q["w"], k) for k, q in enumerate(yollar) if q["sinif"] != "ray"]
for k, y in enumerate(yollar):
    if not y["sari"]:
        continue
    p = y["pts"]
    seg = np.hypot(*np.diff(p, axis=0).T)
    sc = np.concatenate([[0], np.cumsum(seg)])
    for s0 in np.arange(2, sc[-1] - 3, 5.0):
        a = np.array([np.interp(s0, sc, p[:, 0]), np.interp(s0, sc, p[:, 1])])
        b = np.array([np.interp(s0 + 2.5, sc, p[:, 0]), np.interp(s0 + 2.5, sc, p[:, 1])])
        m = (a + b) / 2
        if any(yid[h] != k and np.hypot(*(ornek[h] - m)) < ygen[h] / 2 + 1.5 for h in agac_.query_ball_point(m, 12.0)):
            continue
        if any(abs(m[1] - o["pts"][0][1]) < o["w"] / 2 + 0.5 and o["sinif"] == "ray" for o in yollar):
            continue
        d.line(px([a, b]), fill=SARI, width=max(1, int(0.3 * S)))
im.save(RENK)

# ---------------- lamba ve ağaç ----------------
lamba, agac = [], []


def yolda(x, z):
    j, i = int((z - Z0) * S), int((x - X0) * S)
    return not (0 <= j < H and 0 <= i < W) or ASFALT[j, i] or RAY[j, i] or SU[j, i] or LOTMASK[j, i] or OCC[j, i] and not KALDIR[j, i]


for y in yollar:
    if y["sinif"] == "ray":
        continue
    p = y["pts"]
    seg = np.hypot(*np.diff(p, axis=0).T)
    sc = np.concatenate([[0], np.cumsum(seg)])
    adim_l = 26.0 if y["sinif"] == "ana" else 44.0
    adim_a = 30.0 if y["sinif"] == "ana" else 26.0
    for kind, adim, lst in (("l", adim_l, lamba), ("a", adim_a, agac)):
        s0 = rng.uniform(4, 12)
        sira_ = 0
        while s0 < sc[-1] - 4:
            a = np.array([np.interp(s0, sc, p[:, 0]), np.interp(s0, sc, p[:, 1])])
            b = np.array([np.interp(s0 + 1.5, sc, p[:, 0]), np.interp(s0 + 1.5, sc, p[:, 1])])
            T = (b - a) / (np.hypot(*(b - a)) + 1e-9)
            N = np.array([-T[1], T[0]])
            for yan in (-1, 1):
                if (sira_ + (yan > 0)) % 2:
                    continue
                q = a + N * yan * (y["w"] / 2 + (0.7 if kind == "l" else 1.3))
                if not yolda(q[0], q[1]) and inreg(q[0], q[1]):
                    lst.append([round(float(q[0]), 1), round(float(q[1]), 1)])
            sira_ += 1
            s0 += adim
# park ağaçları
pj, pi = np.where(park)
if len(pj):
    for _ in range(int(park.sum() / (S * S) / 55)):
        k = rng.randrange(len(pj))
        agac.append([round(float(X0 + pi[k] / S), 1), round(float(Z0 + pj[k] / S), 1)])
SOKAK.write_text(json.dumps({"lamba": lamba, "agac": agac, "iskele": guverte}), encoding="utf-8")
print("yol:", len(yollar), "lamba:", len(lamba), "agac:", len(agac), "köprü/iskele:", len(guverte), "park px:", int(park.sum()))
