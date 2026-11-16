"""Southside'ı Chicago 1920'leri düzeninde yeniden üretir (tekrar çalıştırılabilir).
Yaptıkları:
  1. harita.tscn: Southside Bina düğümlerini siler, sokak ağına göre parsel/bina üretir
     (adlı işletme binaları korunur, geri kalanı 'dolgu' = süs bina).
  2. assets/environment/terrain/renk.png: 2 px/m çözünürlükte yol, kaldırım, şerit, yaya geçidi.
  3. data/sokak_ag.json: sokak lambası ve ağaç konumları (çalışma zamanında dekor olarak dizilir).
Kullanım:  python tools/sehir_uret.py
"""
import json, random, re
from pathlib import Path
from PIL import Image, ImageDraw

KOK = Path(__file__).resolve().parent.parent
TSCN = KOK / "scenes/city/harita.tscn"
RENK = KOK / "assets/environment/terrain/renk.png"
YUK = KOK / "assets/environment/terrain/yukseklik.png"
SOKAK = KOK / "data/sokak_ag.json"
X0, Z0, GEN, DER = -182.0, -258.0, 364.0, 594.0
MIN_H, MAX_H = -6.0, 40.0
OLCEK = 2  # piksel / metre

rng = random.Random(1920)
_y = Image.open(YUK).convert("L")


def yuk(x, z):
    w, h = _y.size
    u = min(max((x - X0) / GEN * (w - 1), 0), w - 1.001)
    v = min(max((z - Z0) / DER * (h - 1), 0), h - 1.001)
    i, j = int(u), int(v)
    fu, fv = u - i, v - j
    g = lambda a, b: _y.getpixel((a, b)) / 255.0
    a = g(i, j) * (1 - fu) + g(i + 1, j) * fu
    b = g(i, j + 1) * (1 - fu) + g(i + 1, j + 1) * fu
    return MIN_H + (MAX_H - MIN_H) * (a * (1 - fv) + b * fv)


# ---------- Southside sokak ağı ----------
BOLGE = "southside"
BX0, BX1, BZ0, BZ1 = -152.0, 0.0, -76.0, 76.0
# E-W caddeler (z merkezi, genişlik), N-S caddeler (x merkezi, genişlik)
EW = [(-38.0, 8.0, "yan"), (0.0, 14.0, "ana"), (38.0, 8.0, "yan")]
NS = [(-114.0, 6.0, "yan"), (-76.0, 11.0, "ana"), (-38.0, 6.0, "yan")]
KALDIRIM = 2.2
ARKA_SOKAK = 3.5
KAT = 3.6

TUGLA = [(0.55, 0.30, 0.25), (0.59, 0.36, 0.31), (0.50, 0.27, 0.22), (0.62, 0.40, 0.30),
         (0.66, 0.55, 0.38), (0.55, 0.52, 0.48), (0.48, 0.30, 0.26), (0.60, 0.34, 0.22)]


def aralik(lo, hi, sokaklar, eksen_pay=0.0):
    """lo-hi arasını sokaklarla bloklara böl: [(a, b)]"""
    kes = [(c - w / 2, c + w / 2) for c, w, _ in sokaklar]
    blok, a = [], lo
    for s0, s1 in kes:
        blok.append((a, s0))
        a = s1
    blok.append((a, hi))
    return blok


def lotlar():
    out = []
    xb = aralik(BX0 + 4, BX1 - 4, NS)
    zb = aralik(BZ0 + 4, BZ1 - 4, EW)
    for bi, (bz0, bz1) in enumerate(zb):
        for bj, (bx0, bx1) in enumerate(xb):
            ix0, ix1 = bx0 + KALDIRIM, bx1 - KALDIRIM
            iz0, iz1 = bz0 + KALDIRIM, bz1 - KALDIRIM
            rd = (iz1 - iz0 - ARKA_SOKAK) / 2
            for sira, (z0, z1) in enumerate([(iz0, iz0 + rd), (iz1 - rd, iz1)]):
                # ana caddeye (z=0) bakan sıra mı?
                ana = (bz1 > -1 and bz1 < 1 and sira == 1) or (bz0 > -1 and bz0 < 1 and sira == 0)
                n = max(2, round((ix1 - ix0) / 11.5))
                kes = sorted(rng.uniform(0.75, 1.25) for _ in range(n))
                agirlik = [rng.uniform(0.75, 1.25) for _ in range(n)]
                top = sum(agirlik)
                x = ix0
                for k in range(n):
                    w = (ix1 - ix0) * agirlik[k] / top
                    a, b = x, x + w
                    x = b
                    out.append({"x0": a + 0.25, "x1": b - 0.25, "z0": z0, "z1": z1, "ana": ana,
                                "kose": k in (0, n - 1)})
    return out


def blok_dikdortgenleri():
    xb = aralik(BX0 + 4, BX1 - 4, NS)
    zb = aralik(BZ0 + 4, BZ1 - 4, EW)
    return [(bx0, bz0, bx1, bz1) for (bz0, bz1) in zb for (bx0, bx1) in xb]


# ---------- tscn ----------
def oku_tscn():
    s = TSCN.read_text(encoding="utf-8")
    parcalar = re.split(r"\n(?=\[node )", s)
    return parcalar


def bina_bilgi(p):
    ad = re.search(r'\bad = "([^"]*)"', p)
    return {
        "isim": re.search(r'name="([^"]+)"', p).group(1),
        "ad": ad.group(1) if ad else "",
        "ozel": "ozel = true" in p,
    }


def uret():
    parcalar = oku_tscn()
    kalan, isletmeler = [], []
    for p in parcalar:
        if 'parent="Binalar"' in p and 'bolge = "southside"' in p:
            if 'dolgu = true' not in p:
                isletmeler.append(bina_bilgi(p))
            continue
        kalan.append(p)
    print("işletme binası:", len(isletmeler))

    L = lotlar()
    rng.shuffle(L)
    # özel mekânlar ana cadde parsellerine; sıra: ana cadde olanlar önce
    ana = [l for l in L if l["ana"]]
    diger = [l for l in L if not l["ana"]]
    ozeller = [b for b in isletmeler if b["ozel"]]
    normaller = [b for b in isletmeler if not b["ozel"]]
    atama = {}
    for b in ozeller:
        l = ana.pop() if ana else diger.pop()
        atama[id(l)] = b
    havuz = ana + diger
    rng.shuffle(havuz)
    for b in normaller:
        atama[id(havuz.pop())] = b

    yeni = []
    sayac = 0
    for l in L:
        w, d = l["x1"] - l["x0"], l["z1"] - l["z0"]
        cx, cz = (l["x0"] + l["x1"]) / 2, (l["z0"] + l["z1"]) / 2
        zem = [yuk(x, z) for x in (l["x0"], l["x1"]) for z in (l["z0"], l["z1"])] + [yuk(cx, cz)]
        taban = min(zem) - 0.25
        fark = max(zem) - taban
        kat = rng.choice([3, 4, 4, 5]) if l["ana"] else rng.choice([2, 3, 3, 4])
        if l["kose"]:
            kat += 1
        h = kat * KAT + 1.0 + fark
        r, g, b = rng.choice(TUGLA)
        b_ = atama.get(id(l))
        if b_:
            ad, isim, ozel = b_["ad"], b_["isim"], b_["ozel"]
        else:
            sayac += 1
            ad, isim, ozel = "", "Dolgu_southside_%d" % sayac, False
        t = [1, 0, 0, 0, 1, 0, 0, 0, 1, round(cx, 2), round(taban, 3), round(cz, 2)]
        blok = '[node name="%s" parent="Binalar" instance=ExtResource("3_vwpxd")]\n' % isim
        blok += "transform = Transform3D(%s)\n" % ", ".join(str(v) for v in t)
        blok += 'ad = "%s"\nbolge = "%s"\n' % (ad, BOLGE)
        if ozel:
            blok += "ozel = true\n"
        if not b_:
            blok += "dolgu = true\n"
        blok += "boyut = Vector3(%.2f, %.2f, %.2f)\nrenk = Color(%.3f, %.3f, %.3f, 1)\n" % (w, h, d, r, g, b)
        yeni.append(blok.rstrip("\n"))
    # Kaideler'den hemen önce ekle
    cikti, eklendi = [], False
    for p in kalan:
        if p.startswith('[node name="Kaideler"') and not eklendi:
            cikti.extend(yeni)
            eklendi = True
        cikti.append(p)
    TSCN.write_text("\n".join(cikti), encoding="utf-8")
    print("lot:", len(L), "dolgu:", sayac)

    # ---------- doku ----------
    eski = Image.open(RENK).convert("RGB")
    W, H = int(GEN * OLCEK), int(DER * OLCEK)
    if eski.size != (W, H):
        im = eski.resize((W, H), Image.NEAREST)
    else:
        im = eski
    d = ImageDraw.Draw(im)
    px = lambda x, z: ((x - X0) * OLCEK, (z - Z0) * OLCEK)
    rect = lambda a, b, c, e, col: d.rectangle([*px(a, b), *px(c, e)], fill=col)
    ASFALT, KALDIR, ARKA, SARI, BEYAZ, CIM = (58, 58, 62), (150, 147, 140), (92, 88, 82), (214, 178, 60), (200, 200, 196), (70, 100, 60)
    rect(BX0, BZ0, BX1, BZ1, ASFALT)
    for (bx0, bz0, bx1, bz1) in blok_dikdortgenleri():
        rect(bx0, bz0, bx1, bz1, KALDIR)
        rect(bx0 + KALDIRIM, (bz0 + bz1) / 2 - ARKA_SOKAK / 2, bx1 - KALDIRIM, (bz0 + bz1) / 2 + ARKA_SOKAK / 2, ARKA)
    # şerit çizgileri
    for zc, w, tur in EW:
        if tur == "ana":
            x = BX0 + 4
            while x < BX1 - 4:
                rect(x, zc - 0.15, x + 2.5, zc + 0.15, SARI)
                x += 5.0
    for xc, w, tur in NS:
        if tur == "ana":
            z = BZ0 + 4
            while z < BZ1 - 4:
                rect(xc - 0.15, z, xc + 0.15, z + 2.5, SARI)
                z += 5.0
    # yaya geçitleri (her kavşakta 4 kenar)
    for zc, zw, _ in EW:
        for xc, xw, _ in NS:
            for dx in (-1, 1):   # N-S yolu boyunca üstüne/altına
                for dz in (-1, 1):
                    pass
            # kavşağa girerken: E-W yol üstünde, kavşağın iki yanında
            for sx in (-1, 1):
                x = xc + sx * (xw / 2 + 1.2)
                z = zc - zw / 2 + 0.6
                while z < zc + zw / 2 - 0.4:
                    rect(x - 0.6, z, x + 0.6, z + 0.5, BEYAZ)
                    z += 1.0
            for sz in (-1, 1):
                z = zc + sz * (zw / 2 + 1.2)
                x = xc - xw / 2 + 0.6
                while x < xc + xw / 2 - 0.4:
                    rect(x, z - 0.6, x + 0.5, z + 0.6, BEYAZ)
                    x += 1.0
    im.save(RENK)

    # ---------- lamba ve ağaç ----------
    lamba, agac = [], []
    for zc, w, tur in EW:
        x = BX0 + 10
        while x < BX1 - 8:
            for sz in (-1, 1):
                ys = zc + sz * (w / 2 + 0.6)
                if all(abs(x - xc) > xw / 2 + 4 for xc, xw, _ in NS):
                    lamba.append([round(x + (6 if sz > 0 else 0), 1), round(ys, 1)])
            x += 24.0
    for xc, w, tur in NS:
        z = BZ0 + 10
        while z < BZ1 - 8:
            for sx in (-1, 1):
                xs = xc + sx * (w / 2 + 0.6)
                if all(abs(z - zc) > zw / 2 + 4 for zc, zw, _ in EW):
                    agac.append([round(xs, 1), round(z, 1)])
            z += 17.0
    SOKAK.write_text(json.dumps({"lamba": lamba, "agac": agac}), encoding="utf-8")
    print("lamba:", len(lamba), "agac:", len(agac))


if __name__ == "__main__":
    uret()
