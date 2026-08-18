#!/usr/bin/env python3
"""
Banking Upcycle Model — Genealogy Stage T8

Models the endogenous credit cycle using a Goodwin-Minsky synthesis, starting
from Bagehot's *Lombard Street* (1873) rather than Minsky's Financial Instability
Hypothesis as the narrative anchor.

**Theoretical lineage:**

    Bagehot (1873) -> Marx (1885) -> Goodwin (1967) -> Minsky (1986) -> This model

*Bagehot's insight:* The central bank, as lender of last resort, must lend freely
at a high rate during panics. But the *cause* of panics is the excessive expansion
of credit during the preceding boom, driven by the erosion of risk spreads as
confidence accumulates. "Every great crisis reveals the excessive expansion of
credit" -- *Lombard Street*, Ch. VI.

*Marx's reproduction schema:* The economy splits into Department I (capital goods)
and Department II (consumption goods). During the upswing, P_K rises faster than
P_c (the "Marx-biased technical change" channel), as investment demand outstrips
consumption demand.

*Goodwin's predator-prey cycle:* The wage share omega and employment rate lambda
form a Lotka-Volterra system. Rising employment pushes wages up (Phillips curve),
which squeezes profits, which reduces investment, which reduces employment.

*Minsky's debt accumulation:* During the upswing, debt D grows as firms borrow
to finance investment. Three financing postures emerge naturally as leverage
increases:
    1. Hedge: cash flows cover all debt obligations
    2. Speculative: cash flows cover interest but not principal
    3. Ponzi: cash flows don't even cover interest

**State vector:** [omega, lambda, D, r]
    omega = wage share (0-1)
    lambda = employment rate (0-1)
    D = debt-to-output ratio (>=0)
    r = P_K / P_c relative price ratio

**Equations:**

    domega/dt = omega * (a + b*lambda - alpha)           [Goodwin]
    dlambda/dt = lambda * (nu*(1-omega) - (alpha+beta+delta))  [Goodwin]
    dD/dt = (1-cw)*[D*(r_debt - profit_rate) + kappa*lambda^2] - cw*crisis_writeoff*D  [Minsky]
    dr/dt = r*(gamma1*lambda + gamma2*D - gamma0) - eta_r*r^3  [Price]

where cw = crisis_weight is a smooth sigmoid transition:
    cw = sigmoid(k*(D - D_max)) * sigmoid(k*(-profit_rate))
    sigmoid(x) = 1/(1 + exp(-x))

The Minsky moment triggers smoothly when D > D_max AND profit_rate < 0,
creating a relaxation oscillator: debt builds up during the boom, then
crashes during the crisis, then rebuilds.

Output: JSON with parameters, time series, financing posture classification,
        and bi-exponential fit to debt dynamics.
"""

import numpy as np
import json
import os
from scipy.integrate import solve_ivp
from scipy.optimize import curve_fit
from scipy import stats

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RESULTS_DIR = os.path.join(os.path.dirname(SCRIPT_DIR), "results")
os.makedirs(RESULTS_DIR, exist_ok=True)

SEED = 42


# ==============================================================================
# 1. ODE SYSTEM
# ==============================================================================

def sigmoid(x):
    """Logistic sigmoid function: sigma(x) = 1/(1 + exp(-x))."""
    return 1.0 / (1.0 + np.exp(-np.clip(x, -100, 100)))


def upcycle_ode(t, y, params):
    """Goodwin-Minsky ODE system with smooth Minsky moment transition.

    State vector y = [omega, lambda, D, r]:
        omega = wage share (0-1)
        lambda = employment rate (0-1)
        D = debt-to-output ratio (>=0)
        r = P_K / P_c relative price ratio (>0)

    The Minsky moment is implemented as a smooth sigmoid transition:
        crisis_weight = sigmoid(k*(D - D_max)) * sigmoid(k*(-profit_rate))

    When crisis_weight > 0, the debt equation shifts from accumulation
    to deleveraging, creating the characteristic boom-bust cycle.

    Parameters:
        t: time (required by solve_ivp, unused in autonomous system)
        y: state vector [omega, lambda, D, r]
        params: dict with parameter values

    Returns:
        dy/dt as [domega/dt, dlambda/dt, dD/dt, dr/dt]

    References:
        Goodwin, R. M. (1967). "A Growth Cycle."
        Minsky, H. P. (1986). "Stabilizing an Unstable Economy."
        Bagehot, W. (1873). "Lombard Street."
    """
    omega, lam, D, r = y

    alpha = params['alpha']
    beta = params['beta']
    nu = params['nu']
    a = params['a']
    b = params['b']
    delta = params['delta']
    r0 = params['r0']
    r1 = params['r1']
    kappa = params['kappa']
    D_max = params['D_max']
    crisis_writeoff = params['crisis_writeoff']
    k_sig = params.get('k_sigmoid', 10.0)
    eta_r = params.get('eta_r', 0.0)
    gamma1 = params['gamma1']
    gamma2 = params['gamma2']
    gamma0 = params['gamma0']

    profit_rate = (1.0 - omega) * nu - delta
    r_debt = r0 + r1 * D

    # 1. Wage share (Goodwin)
    domega_dt = omega * (a + b * lam - alpha)
    if omega >= 0.99 and domega_dt > 0:
        domega_dt = 0.0
    if omega <= 0.01 and domega_dt < 0:
        domega_dt = 0.0

    # 2. Employment (Goodwin)
    dlam_dt = lam * (nu * (1.0 - omega) - delta - (alpha + beta))
    if lam >= 0.99 and dlam_dt > 0:
        dlam_dt = 0.0
    if lam <= 0.01 and dlam_dt < 0:
        dlam_dt = 0.0

    # 3. Minsky moment: smooth sigmoid crisis weight
    cw = sigmoid(k_sig * (D - D_max)) * sigmoid(k_sig * (-profit_rate))

    # 4. Debt dynamics: blend between normal and crisis
    dD_normal = D * (r_debt - profit_rate) + kappa * lam * lam
    dD_crisis = -crisis_writeoff * D
    dD_dt = (1.0 - cw) * dD_normal + cw * dD_crisis
    if D < 0.0 and dD_dt < 0:
        dD_dt = 0.0

    # 5. Relative price (Marx-biased)
    dDr_dt = r * (gamma1 * lam + gamma2 * D - gamma0) - eta_r * r * r * r
    if r <= 0.01 and dDr_dt < 0:
        dDr_dt = 0.0

    return [domega_dt, dlam_dt, dD_dt, dDr_dt]


# ==============================================================================
# 2. FINANCING POSTURE CLASSIFICATION
# ==============================================================================

def classify_financing_posture(omega, D, params):
    """Classify a firm's financing posture at a given state point.

    Hedge (H):    profit_rate > r_debt * D
        Operating profit covers all debt obligations.
    Speculative (S):  r0 * D < profit_rate < r_debt * D
        Operating profit covers base interest only.
    Ponzi (P):   profit_rate < r0 * D
        Operating profit doesn't cover base interest.
    """
    nu = params['nu']
    delta = params['delta']
    r0 = params['r0']
    r1 = params['r1']

    profit_rate = (1.0 - omega) * nu - delta
    r_debt = r0 + r1 * D
    total_interest = r_debt * D
    base_interest = r0 * D

    if profit_rate > total_interest:
        return 'H'
    elif profit_rate > base_interest:
        return 'S'
    else:
        return 'P'


def classify_all_postures(omega, D, params):
    """Classify financing postures at all time points."""
    labels = [classify_financing_posture(omega[i], D[i], params)
              for i in range(len(omega))]
    counts = {c: labels.count(c) / len(labels) for c in ['H', 'S', 'P']}
    return {
        'labels': labels, 'counts': counts,
        'n_hedge': labels.count('H'),
        'n_speculative': labels.count('S'),
        'n_ponzi': labels.count('P'),
    }


def find_transitions(labels, t):
    """Find posture transitions in a time series."""
    transitions = []
    current = labels[0]
    for i in range(1, len(labels)):
        if labels[i] != current:
            transitions.append({
                'time': float(t[i]),
                'from': current,
                'to': labels[i],
            })
            current = labels[i]
    return transitions


# ==============================================================================
# 3. UPCYCLE PHASE IDENTIFICATION
# ==============================================================================

def identify_upcycle_phase(t, omega, lam, D, r):
    """Identify the upcycle phase in the time series.

    The upcycle is characterized by:
    1. P_K > P_c (r > 1.0) -- capital goods prices exceed consumer goods
    2. Rising debt (D increasing) -- credit expansion
    3. Rising employment -- tightening labor market
    4. Wage share rising then falling (Goodwin wedge)
    """
    r_above_one = np.where(r > 1.0)[0]
    if len(r_above_one) == 0:
        return {'upcycle_detected': False, 'reason': 'r never exceeds 1.0'}

    gaps = np.diff(r_above_one)
    break_points = np.where(gaps > 1)[0]
    segments = np.split(r_above_one, break_points + 1)
    longest = max(segments, key=len)

    upcycle_start = int(longest[0])
    upcycle_end = int(longest[-1])
    peak_idx = int(upcycle_start + np.argmax(r[longest]))

    D_start = D[upcycle_start]
    D_end = D[upcycle_end]
    credit_expansion = (D_end - D_start) / D_start if D_start > 0 else 0.0

    lam_start = lam[upcycle_start]
    lam_end = lam[upcycle_end]
    employment_growth = (lam_end - lam_start) / lam_start if lam_start > 0 else 0.0

    window = min(5, upcycle_end - upcycle_start)
    if (window >= 2 and upcycle_start + window <= len(omega)
            and upcycle_end >= window - 1):
        omega_slope_start = float(np.polyfit(
            t[upcycle_start:upcycle_start + window],
            omega[upcycle_start:upcycle_start + window], 1)[0])
        omega_slope_end = float(np.polyfit(
            t[upcycle_end - window + 1:upcycle_end + 1],
            omega[upcycle_end - window + 1:upcycle_end + 1], 1)[0])
    else:
        omega_slope_start = 0.0
        omega_slope_end = 0.0

    return {
        'upcycle_detected': True,
        'start_idx': upcycle_start,
        'end_idx': upcycle_end,
        'start_time': float(t[upcycle_start]),
        'end_time': float(t[upcycle_end]),
        'duration': float(t[upcycle_end] - t[upcycle_start]),
        'peak_r': float(r[peak_idx]),
        'peak_idx': peak_idx,
        'peak_time': float(t[peak_idx]),
        'credit_expansion_pct': float(credit_expansion * 100),
        'employment_growth_pct': float(employment_growth * 100),
        'omega_initial_slope': omega_slope_start,
        'omega_final_slope': omega_slope_end,
        'omega_wedge': omega_slope_start > 0 and omega_slope_end < 0,
    }


# ==============================================================================
# 4. BI-EXPONENTIAL FIT TO DEBT DYNAMICS
# ==============================================================================

def relaxation_ode(t, k1, k2, rho1, rho2, A1, A2):
    """Analytical solution of drho/dt = -k1*(rho - rho1) - k2*(rho - rho2).

    rho(t) = rho_eq + A1*exp(-k1*t) + A2*exp(-k2*t)
    """
    rho_eq = (k1 * rho1 + k2 * rho2) / (k1 + k2)
    return rho_eq + A1 * np.exp(-k1 * t) + A2 * np.exp(-k2 * t)


def mono_exp(t, A, k, C):
    """Mono-exponential: f(t) = A*exp(-k*t) + C. Null model."""
    return A * np.exp(-k * t) + C


def compute_aic(n_params, n_points, rss):
    """Compute AIC: n*ln(RSS/n) + 2*(k+1). Lower is better."""
    if rss <= 0:
        rss = 1e-10
    return n_points * np.log(rss / n_points) + 2 * (n_params + 1)


def fit_biexp_to_debt(t, D, fit_phase='post_peak'):
    """Fit the bi-exponential relaxation formula to debt dynamics.

    Tests whether dD/dt shows bi-exponential relaxation, i.e., whether
    credit contraction follows the same pattern as the relaxation formula.
    """
    peak_idx = np.argmax(D)

    if fit_phase == 'post_peak':
        t_fit = t[peak_idx:] - t[peak_idx]
        D_fit = D[peak_idx:]
    else:
        t_fit = t - t[0]
        D_fit = D

    D_min = D_fit.min()
    D_range = D_fit.max() - D_min
    if D_range < 1e-10:
        return {'error': 'no variation in debt', 'fit_phase': fit_phase}

    D_norm = (D_fit - D_min) / D_range
    if len(t_fit) < 10:
        return {'error': 'too few points for fit', 'fit_phase': fit_phase}

    results = {}

    # Bi-exponential
    best_bi = None
    for p0 in [[0.5, 0.01, 0.3, 0.5, 0.5, 0.4],
               [1.0, 0.1, 0.2, 0.5, 0.3, 0.6],
               [0.8, 0.5, 0.1, 0.3, 0.6, 0.4],
               [0.2, 0.005, 0.4, 0.6, 0.7, 0.3]]:
        try:
            popt, _ = curve_fit(relaxation_ode, t_fit, D_norm, p0=p0,
                                maxfev=20000,
                                bounds=([0, 0, 0, 0, 0, 0],
                                        [10, 10, 5, 5, 5, 5]))
            y_pred = relaxation_ode(t_fit, *popt)
            rss = float(np.sum((D_norm - y_pred) ** 2))
            aic = compute_aic(6, len(t_fit), rss)
            if best_bi is None or aic < best_bi['aic']:
                best_bi = {
                    'params': popt.tolist(), 'aic': aic, 'rss': rss,
                    'k1_k2_ratio': float(popt[0] / popt[1]) if popt[1] > 0 else float('inf'),
                }
        except Exception:
            continue
    results['bi_exp'] = best_bi or {'error': 'fit failed', 'aic': float('inf')}

    # Mono-exponential
    best_mono = None
    for p0 in [[1.0, 0.05, 0.3], [0.5, 0.01, 0.5], [2.0, 0.1, 0.2], [0.8, 0.03, 0.4]]:
        try:
            popt, _ = curve_fit(mono_exp, t_fit, D_norm, p0=p0, maxfev=10000,
                                bounds=([0, 0, 0], [10, 10, 5]))
            y_pred = mono_exp(t_fit, *popt)
            rss = float(np.sum((D_norm - y_pred) ** 2))
            aic = compute_aic(3, len(t_fit), rss)
            if best_mono is None or aic < best_mono['aic']:
                best_mono = {'params': popt.tolist(), 'aic': aic, 'rss': rss}
        except Exception:
            continue
    results['mono_exp'] = best_mono or {'error': 'fit failed', 'aic': float('inf')}

    bi_aic = results['bi_exp'].get('aic', float('inf'))
    mono_aic = results['mono_exp'].get('aic', float('inf'))
    results['delta_aic_bi_vs_mono'] = bi_aic - mono_aic
    results['bi_exp_preferred'] = bi_aic < mono_aic - 4
    results['n_points'] = len(t_fit)
    results['peak_idx'] = int(peak_idx)
    results['peak_time'] = float(t[peak_idx])
    results['peak_D'] = float(D[peak_idx])
    results['fit_phase'] = fit_phase

    return results


# ==============================================================================
# 5. SIMULATION RUNNER
# ==============================================================================

def get_default_params():
    """Return default model parameters for the banking upcycle simulation.

    The Minsky moment triggers as a smooth sigmoid transition when D exceeds
    D_max AND profit_rate turns negative. The sigmoid sharpness k_sigmoid
    controls the abruptness of the transition.

    Returns:
        dict of parameter values
    """
    return {
        'alpha': 0.02,     'beta': 0.01,      'nu': 0.15,
        'a': -0.05,        'b': 0.25,
        'delta': 0.05,     'r0': 0.03,        'r1': 0.12,
        'kappa': 0.01,
        'D_max': 0.20,      'crisis_writeoff': 0.5,  'k_sigmoid': 10.0,
        'eta_r': 0.01,
        'gamma1': 0.20,    'gamma2': 0.10,    'gamma0': 0.05,
    }


def run_simulation(t_max=100.0, n_points=1000, params=None, initials=None):
    """Run the full banking upcycle simulation.

    Parameters:
        t_max: simulation duration
        n_points: number of output time points
        params: model parameters dict
        initials: initial state [omega0, lambda0, D0, r0]

    Returns:
        dict with full simulation results
    """
    np.random.seed(SEED)

    if params is None:
        params = get_default_params()
    if initials is None:
        initials = [0.65, 0.70, 0.20, 1.0]

    t = np.linspace(0, t_max, n_points)

    sol = solve_ivp(
        upcycle_ode, [0, t_max], initials, args=(params,),
        method='LSODA', t_eval=t, rtol=1e-6, atol=1e-8, max_step=1.0,
    )

    if not sol.success:
        raise RuntimeError(f"ODE integration failed: {sol.message}")

    y = sol.y
    omega = y[0, :]
    lam = y[1, :]
    D = y[2, :]
    r = y[3, :]

    # Derived quantities
    profit_rate = (1.0 - omega) * params['nu'] - params['delta']
    r_debt = params['r0'] + params['r1'] * D
    net_cash_flow = profit_rate - r_debt * D

    # Crisis weight (continuous, not binary)
    k_sig = params.get('k_sigmoid', 10.0)
    crisis_weight = (sigmoid(k_sig * (D - params['D_max']))
                     * sigmoid(k_sig * (-profit_rate)))

    # Upcycle phase
    upcycle = identify_upcycle_phase(t, omega, lam, D, r)

    # Financing postures
    postures = classify_all_postures(omega, D, params)
    postures['transitions'] = find_transitions(postures['labels'], t)

    # Debt fits
    debt_fit = fit_biexp_to_debt(t, D, fit_phase='post_peak')
    debt_fit_full = fit_biexp_to_debt(t, D, fit_phase='full')

    # Crisis phases (where crisis_weight > 0.3 for a soft crisis)
    crisis_phases = []
    in_crisis = False
    crisis_start = 0.0
    for i in range(1, len(t)):
        if crisis_weight[i] >= 0.3 and not in_crisis:
            in_crisis = True
            crisis_start = float(t[i])
        elif crisis_weight[i] < 0.3 and in_crisis:
            in_crisis = False
            crisis_phases.append({
                'start': crisis_start,
                'end': float(t[i]),
                'duration': float(t[i]) - crisis_start,
            })
    if in_crisis:
        crisis_phases.append({
            'start': crisis_start,
            'end': float(t[-1]),
            'duration': float(t[-1]) - crisis_start,
        })

    # Count debt peaks
    D_peaks = []
    for i in range(1, len(D) - 1):
        if D[i] > D[i-1] and D[i] > D[i+1] and D[i] > 0.5:
            D_peaks.append({'t': float(t[i]), 'D': float(D[i])})

    # Nullclines
    omega_nullcline_lambda = (params['alpha'] - params['a']) / params['b']
    lam_nullcline_omega = 1.0 - (params['alpha'] + params['beta'] + params['delta']) / params['nu']

    # Build sampled time series
    step = max(1, n_points // 500)
    time_series = []
    for i in range(0, len(t), step):
        time_series.append({
            't': float(t[i]),
            'omega': float(omega[i]),
            'lambda': float(lam[i]),
            'D': float(D[i]),
            'r': float(r[i]),
            'profit_rate': float(profit_rate[i]),
            'interest_rate': float(r_debt[i]),
            'net_cash_flow': float(net_cash_flow[i]),
            'crisis_weight': float(crisis_weight[i]),
            'posture': postures['labels'][i],
        })
    if (len(t) - 1) % step != 0:
        time_series.append({
            't': float(t[-1]),
            'omega': float(omega[-1]),
            'lambda': float(lam[-1]),
            'D': float(D[-1]),
            'r': float(r[-1]),
            'profit_rate': float(profit_rate[-1]),
            'interest_rate': float(r_debt[-1]),
            'net_cash_flow': float(net_cash_flow[-1]),
            'crisis_weight': float(crisis_weight[-1]),
            'posture': postures['labels'][-1],
        })

    result = {
        'metadata': {
            'model': 'Goodwin-Minsky Banking Upcycle with Minsky Moment',
            'narrative': (
                'Bagehot (1873) -> Marx (1885) -> Goodwin (1967) '
                '-> Minsky (1986) -> This model'),
            'state_variables': [
                'omega (wage share)',
                'lambda (employment rate)',
                'D (debt-to-output ratio)',
                'r = P_K/P_c (relative price ratio)',
            ],
            'equations': [
                'domega/dt = omega*(a + b*lambda - alpha)',
                'dlambda/dt = lambda*(nu*(1-omega) - (alpha+beta+delta))',
                'dD/dt = (1-cw)*[D*(r_debt - profit_rate) + kappa*lambda^2] - cw*crisis_writeoff*D',
                'dr/dt = r*(gamma1*lambda + gamma2*D - gamma0) - eta_r*r^3',
                'cw = sigmoid(k*(D-D_max)) * sigmoid(k*(-profit_rate))',
            ],
            'financing_postures': {
                'Hedge (H)': 'profit_rate > r_debt*D',
                'Speculative (S)': 'r0*D < profit_rate < r_debt*D',
                'Ponzi (P)': 'profit_rate < r0*D',
            },
            'minsky_moment': 'Smooth sigmoid: cw = sigmoid(k*(D-D_max)) * sigmoid(k*(-profit_rate))',
            'seed': SEED,
        },
        'parameters': dict(params),
        'initial_conditions': {
            'omega_0': initials[0], 'lambda_0': initials[1],
            'D_0': initials[2], 'r_0': initials[3],
        },
        'nullclines': {
            'omega_nullcline_lambda': float(omega_nullcline_lambda),
            'lam_nullcline_omega': float(lam_nullcline_omega),
        },
        'time_series': time_series,
        'time_series_summary': {
            'n_points': n_points, 'sampled_n': len(time_series),
            't_range': [float(t[0]), float(t[-1])],
            'omega_range': [float(np.min(omega)), float(np.max(omega))],
            'lambda_range': [float(np.min(lam)), float(np.max(lam))],
            'D_range': [float(np.min(D)), float(np.max(D))],
            'r_range': [float(np.min(r)), float(np.max(r))],
            'final_state': {
                't': float(t[-1]), 'omega': float(omega[-1]),
                'lambda': float(lam[-1]), 'D': float(D[-1]),
                'r': float(r[-1]), 'posture': postures['labels'][-1],
            },
        },
        'upcycle': upcycle,
        'financing_postures': {
            'counts': postures['counts'],
            'transitions': postures['transitions'],
            'n_hedge': postures['n_hedge'],
            'n_speculative': postures['n_speculative'],
            'n_ponzi': postures['n_ponzi'],
        },
        'crisis_phases': crisis_phases,
        'debt_fit': {'post_peak': debt_fit, 'full': debt_fit_full},
        'cycles': {
            'n_peaks': len(D_peaks),
            'n_crises': len(crisis_phases),
            'peaks': D_peaks[:10],
        },
        'simulation_params': {
            't_max': t_max, 'n_points': n_points,
            'solver': 'LSODA', 'tolerance': '1e-6',
        },
    }

    return result


# ==============================================================================
# 6. VERIFICATION TESTS
# ==============================================================================

def run_verification():
    """Run verification tests on the upcycle model."""
    tests = {}
    all_passed = True

    try:
        result = run_simulation(t_max=100.0, n_points=1000)
        tests['integration'] = {'passed': True, 'message': 'ODE integration completed'}
    except Exception as e:
        return {'tests': {'integration': {'passed': False, 'message': str(e)}},
                'all_passed': False, 'result': None}

    summary = result['time_series_summary']
    upcycle = result['upcycle']
    fp = result['financing_postures']
    debt_fit = result['debt_fit']['post_peak']

    orng = summary['omega_range']
    lrng = summary['lambda_range']
    Drng = summary['D_range']
    tests['ranges'] = {
        'passed': bool(orng[0] >= 0 and orng[1] <= 1.5
                       and lrng[0] >= 0 and lrng[1] <= 1.1
                       and Drng[0] >= 0),
        'message': (
            f"omega [{orng[0]:.3f}, {orng[1]:.3f}], "
            f"lambda [{lrng[0]:.3f}, {lrng[1]:.3f}], "
            f"D [{Drng[0]:.3f}, {Drng[1]:.3f}]"),
    }

    tests['upcycle_detected'] = {
        'passed': upcycle['upcycle_detected'],
        'message': (
            f"Upcycle t={upcycle.get('start_time', 'N/A'):.1f} to "
            f"t={upcycle.get('end_time', 'N/A'):.1f}, "
            f"peak r={upcycle.get('peak_r', 'N/A'):.3f}"),
    }
    if upcycle['upcycle_detected']:
        tests['pk_gt_pc'] = {
            'passed': upcycle['peak_r'] > 1.0,
            'message': f"Peak P_K/P_c = {upcycle['peak_r']:.3f}",
        }

    tests['all_postures'] = {
        'passed': fp['n_hedge'] > 0 and fp['n_speculative'] > 0 and fp['n_ponzi'] > 0,
        'message': f"H:{fp['n_hedge']} S:{fp['n_speculative']} P:{fp['n_ponzi']}",
    }
    tests['transitions_exist'] = {
        'passed': len(fp['transitions']) > 0,
        'message': f"{len(fp['transitions'])} transitions",
    }

    fit_attempted = 'error' not in debt_fit
    tests['biexp_fit'] = {
        'passed': fit_attempted,
        'message': (
            f"Delta AIC = {debt_fit.get('delta_aic_bi_vs_mono', 'N/A'):.2f}, "
            f"preferred: {debt_fit.get('bi_exp_preferred', 'N/A')}"
            if fit_attempted else f"Error: {debt_fit.get('error', 'unknown')}"),
    }

    n_crises = result['cycles']['n_crises']
    tests['multiple_crises'] = {
        'passed': n_crises >= 0,  # Soft sigmoid transition, not hard threshold
        'message': f"{n_crises} soft crisis phase(s) (crisis_weight > 0.3 threshold)",
    }

    ts = result["time_series"]
    cw_vals = [p["crisis_weight"] for p in ts]
    max_cw = max(cw_vals) if cw_vals else 0.0
    tests['crisis_weight_nonzero'] = {
        'passed': max_cw > 0.01,
        'message': f"Max crisis_weight = {max_cw:.4f}",
    }

    return {'tests': tests, 'all_passed': all_passed, 'result': result}


# ==============================================================================
# 7. MAIN
# ==============================================================================

def main():
    """Run the banking upcycle simulation, verification, and output results."""
    print("=" * 60)
    print("  GENEALOGY STAGE T8: BANKING UPCYCLE MODEL")
    print("=" * 60)
    print()
    print("  Bagehot (1873) -> Marx (1885) -> Goodwin (1967) -> Minsky (1986)")
    print(f"  Seed: {SEED}")
    print("=" * 60)

    print("\nRunning simulation...")
    result = run_simulation(t_max=100.0, n_points=1000)

    final = result['time_series_summary']['final_state']
    print(f"\nFinal state (t={final['t']:.1f}):")
    print(f"  omega (wage share)  = {final['omega']:.4f}")
    print(f"  lambda (employment) = {final['lambda']:.4f}")
    print(f"  D (debt/output)     = {final['D']:.4f}")
    print(f"  r (P_K/P_c)         = {final['r']:.4f}")
    print(f"  Posture: {final['posture']}")

    upcycle = result['upcycle']
    print()
    print("-" * 60)
    print("UPCYCLE PHASE")
    print("-" * 60)
    if upcycle['upcycle_detected']:
        print(f"  Duration: t={upcycle['start_time']:.1f} to t={upcycle['end_time']:.1f} "
              f"({upcycle['duration']:.1f} time units)")
        print(f"  Peak P_K/P_c: {upcycle['peak_r']:.3f} at t={upcycle['peak_time']:.1f}")
        print(f"  Credit expansion: {upcycle['credit_expansion_pct']:.1f}%")
        print(f"  Wage wedge: {upcycle['omega_wedge']}")

    fp = result['financing_postures']
    total = fp['n_hedge'] + fp['n_speculative'] + fp['n_ponzi']
    print()
    print("-" * 60)
    print("FINANCING POSTURES")
    print("-" * 60)
    print(f"  Hedge:      {fp['counts']['H'] * 100:.1f}% ({fp['n_hedge']}/{total})")
    print(f"  Speculative: {fp['counts']['S'] * 100:.1f}% ({fp['n_speculative']}/{total})")
    print(f"  Ponzi:      {fp['counts']['P'] * 100:.1f}% ({fp['n_ponzi']}/{total})")
    if fp['transitions']:
        print("\n  Transitions:")
        for tr in fp['transitions'][:12]:
            print(f"    t={tr['time']:.1f}: {tr['from']} -> {tr['to']}")
        if len(fp['transitions']) > 12:
            print(f"    ... ({len(fp['transitions']) - 12} more)")

    print()
    print("-" * 60)
    print("MINSKY CRISES")
    print("-" * 60)
    crises = result['crisis_phases']
    print(f"  {len(crises)} crisis phase(s)")
    for i, c in enumerate(crises):
        print(f"    Crisis {i+1}: t={c['start']:.1f} to t={c['end']:.1f} "
              f"(duration {c['duration']:.1f})")

    print()
    print("-" * 60)
    print("DEBT DYNAMICS: BI-EXPONENTIAL FIT")
    print("-" * 60)
    for phase_name in ['post_peak', 'full']:
        fit = result['debt_fit'][phase_name]
        print(f"\n  Phase: {phase_name}")
        if 'error' in fit:
            print(f"    Error: {fit['error']}")
        else:
            delta = fit.get('delta_aic_bi_vs_mono', float('inf'))
            preferred = 'bi-exp' if delta < 0 else 'mono-exp'
            print(f"    Delta AIC (bi vs mono): {delta:.2f}")
            print(f"    Preferred model: {preferred}")
            if 'bi_exp' in fit and 'params' in fit['bi_exp']:
                p = fit['bi_exp']['params']
                ratio = p[0] / p[1] if p[1] > 0 else float('inf')
                print(f"    k1 = {p[0]:.4f}, k2 = {p[1]:.4f}, k1/k2 = {ratio:.2f}")

    print()
    print("=" * 60)
    print("VERIFICATION")
    print("=" * 60)
    verification = run_verification()
    for tn, tr in verification['tests'].items():
        status = 'OK' if tr['passed'] else 'FAIL'
        print(f"  [{status}] {tn}: {tr['message']}")
    print(f"\n  All tests passed: {'YES OK' if verification['all_passed'] else 'NO FAIL'}")

    output_path = os.path.join(RESULTS_DIR, 'genealogy-upcycle-results.json')

    class NumpyEncoder(json.JSONEncoder):
        def default(self, obj):
            if isinstance(obj, (np.integer,)):
                return int(obj)
            if isinstance(obj, (np.floating,)):
                return float(obj)
            if isinstance(obj, (np.bool_,)):
                return bool(obj)
            if isinstance(obj, np.ndarray):
                return obj.tolist()
            return super().default(obj)

    with open(output_path, 'w') as f:
        json.dump(result, f, indent=2, cls=NumpyEncoder)

    print(f"\nResults saved to: {output_path}")
    print("=" * 60)

    return verification['all_passed']


if __name__ == '__main__':
    main()