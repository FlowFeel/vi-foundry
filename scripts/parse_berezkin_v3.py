#!/usr/bin/env python3
"""v3 parser: fix v2's region false-positives.

v2 treated EVERY <b> run as a region boundary, so mid-text emphasis
("во времена древнего солнца...", episode notes, cross-ref tails) became
bogus "UNMAPPED:" regions (~46k noise slots).

v3 validates each <b> run against the canonical Russian region names
(codes .10-.74) with normalization for dashes, Latin/Cyrillic homoglyphs,
"Ср." cross-ref prefixes, and typo fallback. Bold runs that don't name a
region are folded back into the running text of the current region.

Outputs parsed/motifs_v3.json + a mapping audit.
"""
import os, re, json, difflib, unicodedata, collections

BASE = "/home/node/.openclaw/workspace/corpora/berezkin_catalogue"
HTML = os.path.join(BASE, "html")
OUT = os.path.join(BASE, "parsed")

# Canonical Russian region names -> areal codes (.10-.74; 58 unused in catalogue)
RU_REGIONS = {
    10: "ЮЗ Африка",
    11: "Бантуязычная Африка",
    12: "Западная Африка",
    13: "Судан – Восточная Африка",
    14: "Северная Африка",
    15: "Южная Европа",
    16: "Западная Европа",
    17: "Передняя Азия",
    18: "Австралия",
    19: "Меланезия",
    20: "Микронезия – Полинезия",
    21: "Тибет – Северо-Восток Индии",
    22: "Бирма – Индокитай",
    23: "Южная Азия",
    24: "Малайзия – Индонезия",
    25: "Тайвань – Филиппины",
    26: "Китай – Корея",
    27: "Балканы",
    28: "Средняя Европа",
    29: "Кавказ – Малая Азия",
    30: "Иран – Средняя Азия",
    31: "Северная Европа",
    32: "Волга – Пермь",
    33: "Туркестан",
    34: "Южная Сибирь – Монголия",
    35: "Западная Сибирь",
    36: "Восточная Сибирь",
    37: "Амур – Сахалин",
    38: "Япония",
    39: "СВ Азия",
    40: "Арктика",
    41: "Субарктика",
    42: "СЗ Побережье",
    43: "Побережье – Плато",
    44: "Средний Запад",
    45: "Северо-Восток",
    46: "Равнины",
    47: "Юго-Восток США",
    48: "Калифорния",
    49: "Большой Бассейн",
    50: "Большой Юго-Запад",
    51: "СЗ Мексика",
    52: "Мезоамерика",
    53: "Гондурас – Панама",
    54: "Антилы",
    55: "Северные Анды",
    56: "Льяносы",
    57: "Южная Венесуэла",
    59: "Гвиана",
    60: "Эквадор",
    61: "Западная Амазония",
    62: "СЗ Амазония",
    63: "Центральная Амазония",
    64: "Восточная Амазония",
    65: "Центральные Анды",
    66: "Монтанья – Журуа",
    67: "Боливия – Гуапоре",
    68: "Южная Амазония",
    69: "Арагуая",
    70: "Восточная Бразилия",
    71: "ЮВ Бразилия",
    72: "Чако",
    73: "Южная Бразилия",
    74: "Южный Конус",
}
ALIASES = {
    "Балтоскандия": 31,
    "Северная Еваропа": 31,
    "Балдтоскандия": 31,
    "Балтоякандия": 31,
    "Cеверная Африка": 14,  # Latin C
    "Тибет – СВ Индии": 21,
    "Тибет - Северо-Восток Индии": 21,
    "Тибет – Северо-Восточная Индия": 21,
    "Судан – Северо-Восток Африка": 13,
    "Судан – Северо-Восточная Африка": 13,
    "Судан - Восточная Африка": 13,
    "Иран - Средняя Азия": 30,
    "Китай - Корея": 26,
    "Амур - Сахалин": 37,
    "Волга - Пермь": 32,
    "Гондурас - Панама": 53,
    "Побережье - Плато": 43,
    "Южная Сибирь - Монголия": 34,
    "Боливия-Гуапоре": 67,
    "Тайвань –Филиппины": 25,
    "Тайван – Филиппины": 25,
    "Тайвань – Филлипины": 25,
    "Тайварь – Филиппины": 25,
    "Юго-восток США": 47,
    "ЮЖ Африка": 11,
    "Южная Африка": 11,
    "Северо-Западная Амазония": 62,
    "СВ Амазония": 62,
    "Бирма – Юго-Восточная Азия": 22,
    "Тибет – Северо-Восток Азии": 21,  # observed typo for Индии
    "Передневняя Азия": 17,
    "Переденяя Азия": 17,
    "Передня Азия": 17,
    "Передняя Азиа": 17,
    "Иран – Малая Азия": 30,
    "Иран – Средняя Азиа": 30,
    "Монтанья – Журуна": 66,
    "Западая Европа": 16,
    "Белканы": 27,
    "Средния Запад": 44,
    "СВ побережье": 42,
    "Юго-Восток": 47,
    "Льянос": 56,
    "Индонезия": 24,
    "Филиппины": 25,
    "Полинезия": 20,
    "Монголия": 34,
    "Китай": 26,
    "Япония": 38,
    "Сахалин": 37,
    "Эквадор": 60,
    "Антилы": 54,
    "Кавказ – Средняя Азия": 30,
    "Малайзия - Индонезия": 24,
    "Судан – Восточная Африка": 13,
    "Судан-Восточная Африка": 13,
}

_HOMO = str.maketrans({
    "C": "С", "c": "с", "A": "А", "a": "а", "B": "В", "b": "в",
    "E": "Е", "e": "е", "H": "Н", "K": "К", "k": "к", "M": "М",
    "O": "О", "o": "о", "P": "Р", "p": "р", "T": "Т", "X": "Х",
    "x": "х", "Y": "У", "y": "у",
})

def _norm(s):
    s = s.translate(_HOMO)
    s = unicodedata.normalize("NFKC", s)
    s = s.lower().replace("–", "-").replace("—", "-").replace("−", "-")
    s = re.sub(r'[.,;:!?()«»"\'…]+', " ", s)
    s = re.sub(r'\s+', " ", s).strip()
    return s

def norm_region(s):
    """Strip cross-ref prefixes and trailing notes; return (core, is_crossref)."""
    cross = False
    t = re.sub(r'\s+', " ", str(s)).strip()
    if re.match(r'^(ср\.?|см\.?|cf\.?|compare|проверить:?|надо проверить:?)\s*', t, re.I):
        cross = True
        t = re.sub(r'^(ср\.?|см\.?|cf\.?|compare|проверить:?|надо проверить:?)\s*', "", t, flags=re.I)
    # cut trailing "См. мотив ..."
    t = re.split(r'\bсм\.|\bcf\.|\bср\.', t, flags=re.I)[0]
    t = t.strip(" .,;:")
    return _norm(t), cross

_canon = {}
for code, name in RU_REGIONS.items():
    _canon[_norm(name)] = code
for name, code in ALIASES.items():
    _canon[_norm(name)] = code
_canon_keys = list(_canon)

def resolve_region(raw):
    """Return (code or None, is_crossref)."""
    core, cross = norm_region(raw)
    if not core:
        return None, cross
    if core in _canon:
        return _canon[core], cross
    # typo fallback: fuzzy match, require same-ish length
    if len(core) >= 5:
        best, best_r = None, 0.0
        for k, v in _canon.items():
            r = difflib.SequenceMatcher(None, core, k).ratio()
            if r > best_r:
                best, best_r = v, r
        if best_r >= 0.82 and abs(len(core) - len(best_key_of(best))) <= 4:
            return best, cross
    return None, cross

def best_key_of(code):
    for k, v in _canon.items():
        if v == code:
            return k
    return str(code)

def decode(b):
    try:
        return b.decode("windows-1251")
    except Exception:
        return b.decode("utf-8", errors="replace")

def strip_tags(s):
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", s)).strip()

def parse_variants(html):
    out = []
    for m in re.finditer(r"<u>(.*?)</u>(.*?)(?=<u>|$)", html, re.S):
        trad = strip_tags(m.group(1))
        body = m.group(2)
        sm = re.search(r"\[(.*?)\]\s*:\s*(.*?)$", body, re.S)
        if sm:
            summary = re.sub(r"\s+", " ", sm.group(1)).strip()
            cites = re.sub(r"\s+", " ", sm.group(2)).strip()
        else:
            summary = re.sub(r"\s+", " ", strip_tags(body)).strip()
            cites = ""
        if trad:
            out.append({"tradition": trad, "summary": summary, "citations": cites})
    return out

def parse_page(fname):
    raw = open(os.path.join(HTML, fname), "rb").read()
    t = decode(raw)
    motifs = []
    cur = None
    audit = {"region_runs": 0, "noise_runs": 0, "crossrefs": 0, "unresolved": []}
    for cls, blk in re.findall(r'<p[^>]*class="([^"]+)"[^>]*>(.*?)</p>', t, re.S):
        if cls not in ("NormalLin", "NormalLis", "NormalMai"):
            continue
        if cls == "NormalLin":
            if cur:
                motifs.append(cur)
            text = strip_tags(blk)
            m = re.match(r"^([A-Za-z][0-9][0-9a-zA-Z]*?)\.\s*(.*)$", text)
            if not m:
                cur = None
                continue
            title = m.group(2)
            cm = re.search(r"((?:\.\d+(?:-\.\d+)*)+)\.?\s*$", title)
            codes = []
            if cm:
                for tok in cm.group(1).split("."):
                    if not tok:
                        continue
                    if "-" in tok:
                        a, b = tok.split("-", 1)
                        codes.extend(range(int(a), int(b) + 1))
                    else:
                        codes.append(int(tok))
                title = title[: cm.start()].strip()
            cur = {"code": m.group(1), "title": title.strip(" ."),
                   "areal_codes": sorted(set(codes)), "definition": "", "regions": {}}
        elif cls == "NormalLis" and cur:
            cur["definition"] = strip_tags(blk)
        elif cls == "NormalMai" and cur:
            # split block at <b> runs; a run is a region boundary only if it
            # resolves to a canonical region name
            cur_region = None
            buf = blk
            pos = 0
            segments = []  # (code or None, is_crossref, html_chunk)
            for m in re.finditer(r"<b>(.*?)</b>", blk, re.S):
                chunk = blk[pos:m.start()]
                pos = m.end()
                raw_name = strip_tags(m.group(1)).strip(" .")
                code, cross = resolve_region(raw_name) if raw_name else (None, False)
                if code is not None:
                    audit["region_runs"] += 1
                    if cross:
                        audit["crossrefs"] += 1
                    if cur_region is not None and chunk.strip():
                        segments.append((cur_region, cur_cross, chunk))
                    cur_region = code
                    cur_cross = cross
                else:
                    audit["noise_runs"] += 1
                    if raw_name:
                        audit["unresolved"].append(raw_name[:60])
                    # not a region: bold text folds back into the running chunk
                    if cur_region is not None:
                        segments.append((cur_region, cur_cross, chunk + "<b>" + m.group(1) + "</b>"))
                    else:
                        # emphasis before any region in this block: attach to
                        # previous region's last variant or drop preamble
                        if cur is not None and cur["regions"]:
                            last_key = list(cur["regions"])[-1]
                            if cur["regions"][last_key]:
                                cur["regions"][last_key][-1]["summary"] += " " + strip_tags(chunk + "<b>" + m.group(1) + "</b>")
            tail = blk[pos:]
            if cur_region is not None:
                segments.append((cur_region, cur_cross, tail))
            for code, cross, chunk in segments:
                variants = parse_variants(chunk)
                if cross:
                    for v in variants:
                        v["crossref"] = True
                key = str(code)
                cur["regions"].setdefault(key, []).extend(variants)
    if cur:
        motifs.append(cur)
    return motifs, audit

def main():
    files = sorted(f for f in os.listdir(HTML) if re.match(r"^[a-n][0-9a-z]*\.html$", f))
    all_m = []
    tot = {"region_runs": 0, "noise_runs": 0, "crossrefs": 0}
    unresolved = collections.Counter()
    for f in files:
        motifs, audit = parse_page(f)
        all_m.extend(motifs)
        for k in ("region_runs", "noise_runs", "crossrefs"):
            tot[k] += audit[k]
        for u in audit["unresolved"]:
            unresolved[u] += 1
    seen = {}
    for m in all_m:
        seen.setdefault(m["code"].upper(), m)
    motifs = list(seen.values())
    print(f"{len(files)} files -> {len(all_m)} headers -> {len(motifs)} unique motifs")
    n_codes = sum(1 for m in motifs if m["areal_codes"])
    n_reg = sum(1 for m in motifs if m["regions"])
    n_none = sum(1 for m in motifs if not m["areal_codes"] and not m["regions"])
    print(f"with header codes: {n_codes}, with body regions: {n_reg}, with neither: {n_none}")
    print(f"bold runs accepted as regions: {tot['region_runs']}, folded back as noise: {tot['noise_runs']}, crossrefs: {tot['crossrefs']}")
    keys = collections.Counter()
    for m in motifs:
        for k in m["regions"]:
            if k.startswith("UNMAPPED"):
                keys[k] += 1
    print(f"UNMAPPED keys remaining: {len(keys)} (should be 0)")
    tv = sum(len(v) for m in motifs for v in m["regions"].values())
    tvr = sum(1 for m in motifs for v in m["regions"].values() for x in v if x.get("crossref"))
    print(f"variant summaries: {tv} (crossref-tagged: {tvr})")
    if keys:
        print("samples:", list(keys)[:20])
    top_unres = unresolved.most_common(15)
    if top_unres:
        print("top unresolved bold runs:", top_unres)
    json.dump(motifs, open(os.path.join(OUT, "motifs_v3.json"), "w"), ensure_ascii=False, indent=1)
    print("saved motifs_v3.json")

if __name__ == "__main__":
    main()