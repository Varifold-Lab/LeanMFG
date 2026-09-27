#!/usr/bin/env python3
"""Generate differential fixtures from the pinned, unmodified MFGLib source.

Python/PyTorch are test-oracle dependencies only. No Lean runtime uses Python.
Run with --upstream pointing at a checkout of the commit below.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys

PIN = "d4adccf134e88ad47e0a517af5175edaec15a30f"
parser = argparse.ArgumentParser()
parser.add_argument("--upstream", type=Path, required=True)
parser.add_argument("--output", type=Path, default=Path("tests/mfglib/reference.json"))
args = parser.parse_args()
head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=args.upstream, text=True).strip()
if head != PIN:
    raise SystemExit(f"expected MFGLib {PIN}, got {head}")
if subprocess.check_output(["git", "status", "--porcelain"], cwd=args.upstream, text=True).strip():
    raise SystemExit("oracle checkout must be clean")
sys.path.insert(0, str(args.upstream.resolve()))

import torch
from mfglib.env import Environment
from mfglib.policy import Policy
from mfglib.utils import mean_field_from_policy, policy_from_mean_field
from mfglib.alg import FictitiousPlay, OnlineMirrorDescent, PriorDescent, MFOMO, OccupationMeasureInclusion
from mfglib.scoring import exploitability_score
from mfglib.alg.q_fn import QFn
from mfglib.alg.greedy_policy_given_mean_field import Greedy_Policy
from mfglib.alg.mf_omo_params import mf_omo_params
from mfglib.alg.mf_omo_obj import mf_omo_obj
from mfglib.alg.mf_omo_constraints import mf_omo_constraints
from mfglib.alg.mf_omo_residual_balancing import mf_omo_residual_balancing
from mfglib.alg.utils import project_onto_simplex, hat_initialization
from mfglib.alg.occupation_measure_inclusion import osqp_proj

torch.set_num_threads(1)
data = {}
known_errors = {}

def put(key, value):
    if isinstance(value, torch.Tensor):
        value = value.detach().flatten().tolist()
    data[key] = value

# CPU float32 sampling is checked separately; arithmetic fixtures use float64.
for seed in (0, 17):
    torch.manual_seed(seed)
    put(f"rng/{seed}", torch.rand(700))
random_env = Environment.random_linear(T=2, n=3, m=2, seed=17)
for obj, attrs in [(random_env.reward_fn, ("r1", "r2")), (random_env.transition_fn, ("p1", "p2"))]:
    for attr in attrs:
        tensor = getattr(obj, attr)
        put(f"random_coeff/{attr}", tensor)
        setattr(obj, attr, tensor.double())
random_env.mu0 = torch.ones(3, dtype=torch.float64) / 3
torch.set_default_dtype(torch.float64)

envs = [
    Environment.left_right(),
    Environment.rock_paper_scissors(T=2),
    Environment.susceptible_infected(T=3),
    Environment.beach_bar(T=2, n=4, bar_loc=1, p_still=0.3),
    Environment.building_evacuation(T=2, n_floor=2, floor_l=2, floor_w=2),
    Environment.conservative_treasure_hunting(T=2, n=3, r=(1, 2, 3), c=(0.7, 1.2)),
    Environment.crowd_motion(T=3, torus_l=3, torus_w=4, seed=17),
    Environment.equilibrium_price(T=2, s_inv=2, Q=1, H=2, sigma=1.3),
    Environment.linear_quadratic(T=2, el=2, m=1),
    random_env,
]
names = ["left_right", "rock_paper_scissors", "susceptible_infected", "beach_bar",
         "building_evacuation", "conservative_treasure_hunting", "crowd_motion",
         "equilibrium_price", "linear_quadratic", "random_linear"]

for name, env in zip(names, envs):
    shape = (env.T + 1,) + env.S + env.A
    n = (env.T + 1) * env.n_states * env.n_actions
    values = (1 + (torch.arange(n) * 7 + 3) % 11).double().reshape(-1, env.n_actions)
    pi = (values / values.sum(-1, keepdim=True)).reshape(shape)
    raw_l = (1 + (torch.arange(n) * 3 + 1) % 7).double().reshape(env.T+1, -1)
    L = (raw_l / raw_l.sum(-1, keepdim=True)).reshape(shape)
    put(f"{name}/policy", pi)
    put(f"{name}/mean_field", mean_field_from_policy(pi, env=env))
    put(f"{name}/recovered", policy_from_mean_field(mean_field_from_policy(pi, env=env), env=env))
    for t in range(env.T+1):
        put(f"{name}/reward/{t}", env.reward(t, L[t]))
        if t < env.T:
            put(f"{name}/prob/{t}", env.prob(t, L[t]))
    put(f"{name}/q_optimal", QFn(env, L).optimal())
    put(f"{name}/q_policy", QFn(env, L).for_policy(pi))
    put(f"{name}/greedy", Greedy_Policy(env, L))
    put(f"{name}/score", [exploitability_score(env, pi)])
    b, A, c = mf_omo_params(env, L)
    for key, val in [("b", b), ("A", A), ("c", c)]:
        put(f"{name}/params/{key}", val)
    z, y = hat_initialization(env, L, False)
    put(f"{name}/hat/z", z)
    put(f"{name}/hat/y", y)
    solvers = [("fp", FictitiousPlay()), ("fp_constant", FictitiousPlay(alpha=0.3)),
               ("omd", OnlineMirrorDescent(alpha=0.2)), ("pd", PriorDescent(eta=0.7)),
               ("pd_inner", PriorDescent(eta=0.7, n_inner=2))]
    if name in ("left_right", "susceptible_infected", "random_linear"):
        solvers += [("mfomo", MFOMO()),
                    ("omi", OccupationMeasureInclusion(alpha=0.03, osqp_atol=1e-10, osqp_rtol=1e-10)),
                    ("mfomo_parameterized", MFOMO(parameterize=True)),
                    ("mfomo_sgd", MFOMO(loss="l2", hat_init=False, rb_freq=2,
                       optimizer={"name": "SGD", "config": {"lr": 0.01, "momentum": 0.3}}))]
        for parameterize in (False, True):
            nz = n + int(parameterize)
            zv = torch.arange(nz) / (nz+1) + 0.1
            yw = torch.arange((env.T+1)*env.n_states) / 13 - 0.3
            lu = L.log() if parameterize else L
            for loss in ("l1", "l2", "l1_l2"):
                xs = [v.clone().detach().requires_grad_() for v in (lu, zv, yw)]
                objective = mf_omo_obj(env, *xs, loss, 1.2, 0.7, 0.4, parameterize)
                objective.backward()
                prefix = f"{name}/objective/{int(parameterize)}/{loss}"
                put(prefix, [objective.item()])
                put(prefix+"/gradient", torch.cat([v.grad.flatten() for v in xs]))
            v, w = hat_initialization(env, L, parameterize)
            # Compare represented probabilities instead of ill-conditioned
            # log coordinates near zero (different reduction roundoff).
            put(f"{name}/hat/{int(parameterize)}/v",
                torch.softmax(v, dim=0) if parameterize and v is not None else v if v is not None else [])
            put(f"{name}/hat/{int(parameterize)}/w", w)
        lp, zp, yp = mf_omo_constraints(env, L*4-0.1, z*100-1, y*100)
        put(f"{name}/constraints", torch.cat([lp.flatten(), zp, yp]))
        put(f"{name}/balancing", list(mf_omo_residual_balancing(
            env, L, z, y, "l1_l2", 1., 1., 10., 2., .1, False)))
        # Compare the native QP to OSQP at tight tolerances. OSQP returns float32.
        d = L.flatten() - 0.03*c
        projected, _, _ = osqp_proj(d, b, A, None, None, 1e-10, 1e-10)
        put(f"{name}/projection", projected)
    for key, solver in solvers:
        try:
            if key == "omi":
                # Upstream OSQP explicitly casts its result to float32. Keep
                # this solver in float32, otherwise RandomLinear's matmul
                # fails on its second iteration with a dtype mismatch.
                torch.set_default_dtype(torch.float32)
                omi_env = {"left_right": lambda: Environment.left_right(),
                           "susceptible_infected": lambda: Environment.susceptible_infected(T=3),
                           "random_linear": lambda: Environment.random_linear(T=2, n=3, m=2, seed=17)}[name]()
                pis, scores, _ = solver.solve(omi_env, pi_0=pi.float(), max_iter=3, atol=None, rtol=None)
                torch.set_default_dtype(torch.float64)
            else:
                pis, scores, _ = solver.solve(env, pi_0=pi, max_iter=3, atol=None, rtol=None)
        except RuntimeError as error:
            if name == "equilibrium_price" and key in ("fp", "fp_constant"):
                known_errors[f"{name}/solver/{key}"] = str(error)
                continue
            raise
        put(f"{name}/solver/{key}/policies", torch.cat([p.flatten() for p in pis]))
        put(f"{name}/solver/{key}/scores", scores)

for radius in (0., 1., 2.):
    put(f"simplex/{int(radius)}", project_onto_simplex(torch.tensor([-2., .3, 1.2, 3.]), radius))

args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(json.dumps({"upstream": PIN, "torch": torch.__version__, "known_errors": known_errors, "vectors": data},
                                  indent=2, allow_nan=False) + "\n")
print(f"wrote {len(data)} reference vectors to {args.output}")
