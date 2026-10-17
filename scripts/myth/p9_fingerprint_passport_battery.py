import json, random, collections, time
import numpy as np

R = 'results/myths/'

def load(f):
    return json.load(open(R + f))

def prof(tokens):
    c = collections.Counter(tokens)
    n = sum(c.values()) or 1
    return {k: v / n for k, v in c.items()}

def macro_acc(labels, feats):
    vocab = sorted(set(w for f in feats for w in f))
    V = np.array([[f.get(v, 0.0) for v in vocab] for f in feats], dtype=float)
    n = len(labels)
    norms = np.linalg.norm(V, axis=1, keepdims=True)
    norms[norms == 0] = 1.0
    Vn = V / norms
    labs = np.array(labels)
    ul = sorted(set(labels))
    correct = collections.defaultdict(list)
    for i in range(n):
        sims = {}
        for t in ul:
            idx = np.where(labs == t)[0]
            idx = idx[idx != i]
            if len(idx) == 0:
                continue
            c = V[idx].mean(axis=0)
            cn = np.linalg.norm(c)
            sims[t] = float(Vn[i] @ (c / cn)) if cn > 0 else -1.0
        pred = max(sims, key=sims.get)
        correct[labels[i]].append(pred == labels[i])
    per = {t: float(np.mean(v)) for t, v in correct.items() if v}
    return float(np.mean(list(per.values()))), per

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
    out = []
    for c in e['event_chain']:
        if isinstance(c, dict):
            out.append(c['event_type'])
        # bare-string predicates (legacy Formosan rows) have no event_type; skip
    return out
def mtoks(e): return [str(m) for m in e.get('mythemes', [])]
def ptoks(e): return [p for p in (pm(m) for m in e.get('mythemes', [])) if p]
def prefix(e): return e['id'].split(':')[0].strip()

sib = [(e['tribe'], e) for e in load('SIBERIA_CODING.json')] + \
      [(e['id'].split('—')[0].split('(')[0].strip(), e) for e in load('RIFTIN_AMUR_EXTRACT.json')]
form = [(e['tribe'], e) for e in load('FORMOSAN_CONSENSUS.json')]
grey = [('Maui-cycle' if 'maui' in e['id'] else 'other', e) for e in load('GREY_MERGED.json')]

DATASETS = [
    ('Ancient Near East', [(prefix(e), e) for e in load('ANCIENT_CODING.json')], 800),
    ('Hebrew vs Rig Veda', [(prefix(e), e) for e in load('CODING_P2_BATCH.json')], 800),
    ('Formosa tribes', form, 500),
    ('Koryak vs Amur', sib, 800),
    ('Maori Maui-cycle (exploratory)', grey, 800),
]

rng = random.Random(11)
out = {}
print(f"{'dataset':34} {'n':>4} {'k':>2}  {'gram':>5} {'myth':>5} {'pmyth':>5}   p(g)    p(m)    p(p)")
for name, pairs, NB in DATASETS:
    t0 = time.time()
    cnt = collections.Counter(l for l, _ in pairs)
    kept = [(l, e) for l, e in pairs if cnt[l] >= 2]
    labels = [l for l, _ in kept]
    ents = [e for _, e in kept]
    if len(set(labels)) < 2:
        print(f'{name} skipped (<2 classes)')
        continue
    res = {}
    for key, fn in [('gram', gtoks), ('myth', mtoks), ('pmyth', ptoks)]:
        feats = [prof(fn(e)) for e in ents]
        if not any(f for f in feats):
            res[key] = (None, None)
            continue
        acc, per = macro_acc(labels, feats)
        null = []
        for _ in range(NB):
            lab = labels[:]
            rng.shuffle(lab)
            null.append(macro_acc(lab, feats)[0])
        p = sum(1 for v in null if v >= acc) / len(null)
        res[key] = (round(acc, 3), p)
    g = res['gram'][0]; m = res['myth'][0]; pmv = res['pmyth'][0]
    pg = res['gram'][1]; pm_ = res['myth'][1]; pp = res['pmyth'][1]
    print(f"{name:34} {len(kept):4} {len(set(labels)):2}  {g or 0:5.2f} {m or 0:5.2f} {pmv or 0:5.2f}   {pg:.3f}   {pm_:.3f}   {pp if pp is not None else float('nan'):.3f}   ({time.time()-t0:.0f}s)")
    out[name] = {'n': len(kept), 'k': len(set(labels)), 'grammar': res['gram'], 'mytheme': res['myth'], 'parent_mytheme': res['pmyth'], 'class_sizes': dict(cnt)}

json.dump(out, open(R + 'P9_FINGERPRINT_PASSPORT_ACROSS_DATASETS.json', 'w'), indent=1)
print('SAVED')
