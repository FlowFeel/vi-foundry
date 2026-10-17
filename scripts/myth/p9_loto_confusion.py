import json, random, collections
import numpy as np

R = 'results/myths/'

def load(f):
    return json.load(open(R + f))

def prof(tokens):
    c = collections.Counter(tokens)
    n = sum(c.values()) or 1
    return {k: v / n for k, v in c.items()}

def loto_landing(labels, feats):
    """Leave-one-tradition-out: for each tradition t, classify its entries against
    centroids of all OTHER traditions. Returns {t: Counter(landing)}, n per t."""
    vocab = sorted(set(w for f in feats for w in f))
    V = np.array([[f.get(v, 0.0) for v in vocab] for f in feats], dtype=float)
    norms = np.linalg.norm(V, axis=1, keepdims=True)
    norms[norms == 0] = 1.0
    Vn = V / norms
    labs = np.array(labels)
    ul = sorted(set(labels))
    out = {}
    for t in ul:
        tr_idx = np.where(labs != t)[0]
        te_idx = np.where(labs == t)[0]
        if len(tr_idx) == 0 or len(te_idx) == 0:
            continue
        cents = {}
        for u in ul:
            if u == t:
                continue
            idx = np.where(labs == u)[0]
            c = V[idx].mean(axis=0)
            cn = np.linalg.norm(c)
            cents[u] = c / cn if cn > 0 else c
        landing = collections.Counter()
        for i in te_idx:
            sims = {u: float(Vn[i] @ c) for u, c in cents.items()}
            landing[max(sims, key=sims.get)] += 1
        out[t] = {'landing': dict(landing), 'n': len(te_idx)}
    return out

def perm_loto_p(labels, feats, target_t, close_set, NB=1000, seed=7):
    """P(fraction of target_t entries landing on close_set) under label shuffles >= observed."""
    rng = random.Random(seed)
    vocab = sorted(set(w for f in feats for w in f))
    V = np.array([[f.get(v, 0.0) for v in vocab] for f in feats], dtype=float)
    norms = np.linalg.norm(V, axis=1, keepdims=True)
    norms[norms == 0] = 1.0
    Vn = V / norms

    def close_frac(labs):
        labs = np.array(labs)
        ul = sorted(set(labs))
        if target_t not in ul:
            return 0.0
        tr_idx = np.where(labs != target_t)[0]
        te_idx = np.where(labs == target_t)[0]
        cents = {}
        for u in ul:
            if u == target_t:
                continue
            idx = np.where(labs == u)[0]
            if len(idx) == 0:
                continue
            c = V[idx].mean(axis=0)
            cn = np.linalg.norm(c)
            cents[u] = c / cn if cn > 0 else c
        if not cents:
            return 0.0
        hit = 0
        for i in te_idx:
            sims = {u: float(Vn[i] @ c) for u, c in cents.items()}
            if max(sims, key=sims.get) in close_set:
                hit += 1
        return hit / len(te_idx)

    obs = close_frac(labels)
    ge = 0
    for _ in range(NB):
        lab = labels[:]
        rng.shuffle(lab)
        if close_frac(lab) >= obs:
            ge += 1
    return obs, ge / NB

STEM = {'creat':'creation','cosmo':'cosmology','genea':'genealogy','conflict':'conflict','journey':'journey','trick':'trickery','marri':'marriage','kin':'kinship','death':'death','afterl':'afterlife','taboo':'taboo-violation','transform':'transformation','punish':'divine-punishment','ritual':'ritual','king':'kingship','weather':'weather-celestial','celesti':'weather-celestial','animal':'animal-origin','etiol':'etiology-local','origin':'creation','flood':'cosmology','theft':'trickery','ordeal':'ritual','trial':'ritual','trap':'trickery'}
CODE2P = {'CREA':'creation','ORIG':'creation','ORIGIN':'creation','EXPL':'etiology-local','CURS':'journey','JOUR':'journey','TRAVL':'journey','MEET':'kinship','REQ':'ritual','SACR':'ritual','PREP':'ritual','TEST':'ritual','CONFL':'conflict','ORDER':'kingship','ORDERING':'kingship','DETH':'death','ESCP':'journey','RESC':'conflict','TRFM':'transformation','TRANS':'transformation','MARRIAGE':'marriage','REW':'divine-punishment','REWD':'divine-punishment','REVR':'divine-punishment','FAIL':'conflict','COMB':'conflict','DECEP':'trickery','DECP':'trickery','THEF':'trickery','TRAP':'trickery','PUNS':'taboo-violation','REFU':'taboo-violation','GENEAL':'genealogy','WEATHER':'weather-celestial','MOON':'weather-celestial','SUN':'weather-celestial','STAR':'weather-celestial','VICT':'conflict'}

def pm(m):
    s = str(m).strip().upper()
    if s in CODE2P:
        return CODE2P[s]
    ml = str(m).lower()
    for k, v in STEM.items():
        if k in ml:
            return v
    return None

def gtoks(e):
    return [c['event_type'] for c in e['event_chain'] if isinstance(c, dict)]
def mtoks(e):
    return [str(m) for m in e.get('mythemes', [])]
def ptoks(e):
    return [p for p in (pm(m) for m in e.get('mythemes', [])) if p]
def prefix(e):
    return e['id'].split(':')[0].strip()

sib = [(e['tribe'], e) for e in load('SIBERIA_CODING.json')] + \
      [(e['id'].split('—')[0].split('(')[0].strip(), e) for e in load('RIFTIN_AMUR_EXTRACT.json')]
form = [(e['tribe'], e) for e in load('FORMOSAN_CONSENSUS.json')]

# culturally/linguistically defensible close sets
CLOSE = {
    'Ancient Near East': {'Akkadian': {'Ugaritic'}, 'Ugaritic': {'Akkadian'}, 'Hittite': {'Ugaritic', 'Mesopotamian'}},
    'Koryak vs Amur': {'Koryak': {'Chukchee'}, 'Chukchee': {'Koryak'}, 'Nanai': {'Orochi', 'Udege', 'Nivkh'}, 'Nivkh': {'Nanai', 'Orochi', 'Udege'}},
    'Formosa tribes': {
        'Atayal': {'Seediq', 'Truku'}, 'Seediq': {'Atayal', 'Truku'}, 'Truku': {'Atayal', 'Seediq'},
        'Paiwan': {'Rukai'}, 'Rukai': {'Paiwan'},
        'Tsou': {'Kanakanavu', 'Hla\'alua'},
        'Yami': set(),  # Bashiic (Malayo-Polynesian) — distant from all; used as negative control
    },
}

DATASETS = [
    ('Ancient Near East', [(prefix(e), e) for e in load('ANCIENT_CODING.json')]),
    ('Koryak vs Amur', sib),
    ('Formosa tribes', form),
]

out = {}
for name, pairs in DATASETS:
    cnt = collections.Counter(l for l, _ in pairs)
    kept = [(l, e) for l, e in pairs if cnt[l] >= 3]  # need >=3 for a meaningful landing distribution
    labels = [l for l, _ in kept]
    ents = [e for _, e in kept]
    res = {}
    for key, fn in [('gram', gtoks), ('myth', mtoks), ('pmyth', ptoks)]:
        feats = [prof(fn(e)) for e in ents]
        if not any(f for f in feats):
            continue
        res[key] = loto_landing(labels, feats)
    print(f"\n=== {name} (n={len(kept)}) ===")
    close_tests = CLOSE.get(name, {})
    stats = {}
    for key in ['gram', 'myth', 'pmyth']:
        if key not in res:
            continue
        close_hit = 0
        close_tot = 0
        for t, info in res[key].items():
            cs = close_tests.get(t)
            if not cs:
                continue
            cs_in_train = [c for c in cs if c in res[key] or c != t]
            cs_avail = [c for c in cs if c in set(labels) and c != t]
            if not cs_avail:
                continue
            hits = sum(v for u, v in info['landing'].items() if u in cs_avail)
            tot = info['n']
            exp = len(cs_avail) / (len(set(labels)) - 1)
            obs = hits / tot
            obs_p, pp = perm_loto_p(labels, feats_for(key, ents), t, set(cs_avail), NB=400) if False else (obs, None)
            stats[(key, t)] = {'obs': round(obs, 3), 'exp': round(exp, 3), 'n': tot}
            print(f"  [{key}] {t:12} -> close-set {sorted(cs_avail)}: obs {obs:.2f} vs exp {exp:.2f} (n={tot})")
        # aggregate enrichment
    out[name] = {'loto': {k: v for k, v in res.items()}, 'close_tests': {f'{k}|{t}': v for (k, t), v in stats.items()}}

json.dump(out, open(R + 'P9_LOTO_CONFUSION_RESULTS.json', 'w'), indent=1)
print('\nSAVED')
