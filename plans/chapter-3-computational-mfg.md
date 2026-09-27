# From Chapter 3 to a computational MFG example

**Status:** Proposed development plan; no new solver or theorem is implemented by this document.
**Baseline:** LeanMFG `512b564`, reviewed on 2026-09-27.
**Tracking issue:** [#7 — From Chapter 3 to a computational MFG example](https://github.com/Varifold-Lab/LeanMFG/issues/7).

Build an executable example that freezes a population forecast, computes a best
response, simulates the resulting population, and measures the consistency error.
Deliver reusable Lean definitions and proofs in small increments. The first
implementation should be a finite-support Wasserstein distance, followed by a
frozen-policy particle simulator and a coupled numerical demonstration.

The motivation comes from [Cardaliaguet's Chapter 3](https://www.ceremade.dauphine.fr/~cardaliaguet/MFGcours2018.pdf#page=15):
Section 3.1 supplies the control formulation, Section 3.2 supplies distribution
distances and empirical approximation, and Section 3.3 addresses interacting
particle limits. These support different parts of the computation. A complete
solver also needs numerical analysis and an outer-iteration convergence argument.

## Existing foundations and gaps

| Existing code | Reuse | Work still needed |
| --- | --- | --- |
| [Deterministic control model](../LeanMFG/Model/Continuous/DeterministicControl.lean), [classical HJB solution](../LeanMFG/Theory/Continuous/HJB/ClassicalSolution.lean), and [verification theorem](../LeanMFG/Verification/Continuous/HJB.lean) | Cost conventions, feedback `a = -∂ₓu`, and the quadratic benchmark | Diffusion, stochastic admissibility, Itô-based verification, and population coupling |
| [Environment](../LeanMFG/Computational/Environment.lean), [Q functions](../LeanMFG/Computational/QFn.lean), and [policy evolution](../LeanMFG/Computational/Policy.lean) | Finite-horizon Bellman recursion and forward distributions for a discrete control approximation | A documented discretization of the continuous problem and its approximation guarantees |
| [Iterative algorithms](../LeanMFG/Computational/Algorithms/Iterative.lean) | Configuration, histories, and existing learning algorithms | A population-flow residual; convergence of the selected outer update |
| [Binary64](../LeanMFG/Numerical/Binary64.lean) and [population error proofs](../LeanMFG/Verification/Numerical/Population.lean) | Selected arithmetic operations and one forward population kernel | Bounds for new distance, interpolation, sampling, and solver operations |
| [Random generator](../LeanMFG/Computational/Random.lean) | Reproducible uniform samples | A documented normal sampler and an explicit distinction between pseudorandom execution and ideal independent Gaussian variables |

The current `MeanField` represents joint state-action arrays. The proposed
continuous model uses state distributions. Any adapter must take state marginals
explicitly. Existing fictitious play mixes occupancies and recovers a policy;
it is not automatically the population-flow update below.

The pinned mathlib includes probability measures, strong-law results, and Brownian
motion definitions. This review did not identify a ready-to-use Wasserstein or
Itô/SDE solver-verification interface. Milestone 0 must check the exact prerequisites
before committing to a stochastic proof scope. See the current
[verification boundary](../docs/app/docs/verification/page.mdx).

## Reference problem

Start in one spatial dimension on the real line, with independent individual
noise, horizon `T = 1`, diffusion `ν > 0`, and an initial probability law `m₀`
with finite second moment. Use the family

$$
dX_t = a_t\,dt + \sqrt{2\nu}\,dB_t,
\qquad
J(a;m)=\mathbb E\left[\int_0^T
\left(\tfrac12 a_t^2+F(X_t,m_t)\right)dt+g(X_T)\right],
$$

$$
F(x,m)=\int_{\mathbb R}K(x,y)m(dy),\qquad
K(x,y)=\kappa\exp\left(-\frac{(x-y)^2}{2\ell^2}\right),\qquad
g(x)=\tfrac12 x^2,
$$

where `κ ≥ 0` and `ℓ > 0`. A symmetric two-point initial law is a simple first
fixture. Neither this kernel choice nor a small empirical residual establishes
convergence of the proposed iteration.

For a fixed forecast `m`, the smooth reference equations are

$$
-\partial_tu-\nu\partial_{xx}u+\tfrac12|\partial_xu|^2=F(x,m_t),
\qquad u(T,x)=g(x),\qquad a=-\partial_xu.
$$

The induced law solves

$$
\partial_t\widetilde m-\nu\partial_{xx}\widetilde m
+\partial_x(a\widetilde m)=0,\qquad \widetilde m(0)=m_0.
$$

These equations specify the target. Smooth solutions, admissible feedback, and
well-posed dynamics are hypotheses to establish, not consequences of storing
functions in a Lean structure.

The numerical problem must specify its finite interval `[-R,R]`, boundary rule,
time and spatial grids, any control bound and action grid, and interpolation.
Clipping a particle or discarding a Gaussian tail changes the approximation and
must be recorded. Use the real-line distance throughout; the sorting formula
below does not compute the geodesic Wasserstein distance on a circle.

## Computation and diagnostics

For `h = T/M`, a frozen feedback gives the Euler–Maruyama update

$$
X_{n+1}^i=X_n^i+h\,a^k(t_n,X_n^i)+\sqrt{2\nu h}\,\xi_n^i,
\qquad
\widetilde m_n^{k+1}=\frac1N\sum_{i=1}^N\delta_{X_n^i}.
$$

Ideal noises are independent standard normal variables. New rollout samples
must be independent of the data used to construct the frozen feedback for the
conditional independent-particle interpretation to apply. A drift that depends
on the current empirical population defines a different, interacting system;
its mean-field limit belongs to a later milestone.

```text
Choose a population forecast m[0] with the prescribed initial law.
For k = 0, ..., max_iterations - 1:
    Solve the frozen-population control approximation for m[k].
    Extract the policy/feedback appropriate to that approximation.
    Run a fresh particle rollout and form weighted empirical laws m_tilde.
    Measure raw_residual = max_n W1(m[k][n], m_tilde[n]).
    Record control diagnostics, sampling settings, and boundary events.
    If the stopping policy is satisfied, return the iterate and diagnostics.
    For n > 0, set m[k+1][n] = (1 - alpha[k]) m[k][n] + alpha[k] m_tilde[n].
    Keep m[k+1][0] = m₀ and require 0 < alpha[k] <= 1.
Return iteration_limit if the stopping policy was not satisfied.
```

Keep the forecast's initial slice equal to `m₀`; report initial sampling error
separately when rollout particles approximate that law. Return the forecast,
its best response, and the induced population together so their roles are clear.

The raw residual must be measured **before** relaxation. A small update caused
by a small `alpha` is not evidence of consistency. A mixture of measures uses
weighted support points; averaging paired particle positions is a different
operation. Any compression or resampling needs its own error accounting.

For equal-size, equally weighted real-line clouds,

$$
W_1\left(\frac1N\sum_i\delta_{x_i},\frac1N\sum_i\delta_{y_i}\right)
=\frac1N\sum_i|x_{(i)}-y_{(i)}|.
$$

For arbitrary normalized weights on a common ordered support
`z₁ < ⋯ < z_J`, including the union of two different supports, use

$$
W_1(p,q)=\sum_{j=1}^{J-1}
\left|\sum_{i=1}^j(p_i-q_i)\right|(z_{j+1}-z_j).
$$

The weighted case is needed for relaxed forecasts and grid-versus-particle
comparisons. Reject empty clouds, nonfinite coordinates, negative weights,
and invalid total mass; document any numerical normalization tolerance.

## Milestones and acceptance criteria

### 0. Fix the numerical model and proof interfaces

Tracking: [#8](https://github.com/Varifold-Lab/LeanMFG/issues/8).

- [ ] Specify state laws, empirical laws, weighted mixtures, kernel evaluation,
  frozen control, rollout, and residual interfaces.
- [ ] Audit the pinned mathlib prerequisites and record reusable declarations
  and missing results for finite transport, SDEs, and stochastic verification.
- [ ] Select and cite a concrete monotone control discretization. A finite
  Markov-chain Bellman approximation is the preferred first implementation
  because it can reuse `Environment` and `QFn`.
- [ ] Specify boundaries, tail treatment, interpolation, action truncation,
  stability restrictions, and refinement parameters before coding the solver.
- [ ] Define the adapter: rewards are negative costs; running costs carry `h`;
  the terminal reward is `-g` without another running-cost step. Discrete
  minimizing actions and interpolated `-∂ₓu` must remain distinct interfaces.

**Done when:** a small benchmark and all representation choices are specified,
and each planned proof has an explicit dependency list. Do not require a full
stochastic calculus library before starting the finite-support work.

### 1. Implement and verify finite-support one-dimensional transport

Tracking: [#9](https://github.com/Varifold-Lab/LeanMFG/issues/9).

- [ ] Define normalized finite distributions with exact rational coordinates
  and weights, their real-valued interpretation, and finite transport couplings.
- [ ] Implement sorted matching for nonempty, equal-size, equal-weight clouds.
  Prove equality to the minimum finite transport cost, including invariance
  under permutations and duplicate positions.
- [ ] Add weighted support merging and the cumulative-mass formula. Prove its
  transport specification and compatibility with empirical laws and mixtures.
- [ ] Prove the estimate
  `|F(x, μ) - F(x, η)| ≤ L_K W₁(μ, η)` for kernels uniformly `L_K`-Lipschitz
  in their second argument, first for the finite-support representation.
- [ ] Connect the finite formulation to probability measures when the needed
  transport API is available; label the finite theorem's scope until then.

**Done when:** the actual exact executable is linked to the finite transport
specification, with examples for translations, permutations, repeated points,
unequal weights, and invalid inputs. A Float implementation needs a separate
refinement/error argument before it can claim the exact program's guarantee.

**Suggested first PR:** equal-weight rational transport only. Weighted transport
and the kernel estimate can follow in separate PRs.

### 2. Build a frozen-feedback particle simulator

Tracking: [#10](https://github.com/Varifold-Lab/LeanMFG/issues/10).

- [ ] Implement a pure step function parameterized by supplied noise increments,
  then add seeded sampling as an execution wrapper. Validate `N > 0`, `M > 0`,
  finite parameters, and `ν ≥ 0`.
- [ ] Add the normal sampler, documenting seed behavior, precision, and handling
  of exceptional inputs to logarithms or other transforms. The existing uniform
  generator is not already a Gaussian sampler.
- [ ] Check deterministic trajectories at `ν = 0`, and sample mean/variance for
  constant drift against `E[X_t] = E[X_0] + bt` and
  `Var(X_t) = Var(X_0) + 2νt` under independent initialization and noise.
- [ ] Add pathwise one-step perturbation bounds under a Lipschitz feedback
  hypothesis; identify additional rounding terms for Float execution.

**Done when:** fixed seeds reproduce a rollout, supplied-noise cases have exact
checks, and distributional checks use stated statistical tolerances across
seeds. These tests do not prove a law of large numbers or Gaussian sampling.

### 3. Assemble the coupled numerical demonstration

Tracking: [#11](https://github.com/Varifold-Lab/LeanMFG/issues/11).

- [ ] Implement the selected frozen-population control approximation, Gaussian
  kernel coupling, and an adapter to the existing numerical layer where its
  semantics match.
- [ ] Validate the uncoupled case `κ = 0`. The smooth reference candidate is
  `u(t,x) = x² / (2(1+T-t)) + ν log(1+T-t)`, with feedback
  `a(t,x) = -x / (1+T-t)`; at `T = 1, ν = 0` this matches the existing example.
- [ ] Compare particle evolution with forward propagation under the **same**
  discrete transition law. A Gaussian Euler rollout and a different quadrature
  or projection rule need a separate discrepancy measurement.
- [ ] Add relaxation, weighted residuals, maximum-iteration handling, and a
  recorded independent validation rollout. If common random numbers are used
  during iteration, keep the final validation sample separate.
- [ ] Export configuration and history: seed, `N`, `h`, grid, boundary and action
  rules, relaxation, raw residual, update size, cost/best-response diagnostics,
  and termination reason. Reuse the current CLI conventions where practical.
- [ ] Run separate particle-count, mesh/time, domain-size, and iteration studies.
  Include a failure or oscillation case so iteration-limit behavior is exercised.

**Done when:** one documented command reproduces an uncoupled benchmark and a
nonzero-coupling example, with residual histories and validation data. A sampled
tolerance hit is reported as a numerical stopping condition. Discrete
exploitability, if available through the adapter, is labeled for that model.

### 4. Prove approximation results in separate tracks

Tracking: [#12](https://github.com/Varifold-Lab/LeanMFG/issues/12).

| Track | Deliverable | Conditions that must be explicit |
| --- | --- | --- |
| Frozen-policy sampling | Empirical-law convergence at the sampled times | Conditional independence, moments, the target law, and whether the grid is fixed |
| Time and space approximation | Convergence/error bounds for the selected control and rollout schemes | Feedback regularity, consistency, stability, interpolation, boundaries, control truncation, and any Gaussian quadrature |
| Stochastic verification | Value lower bound and attainment for a diffusion control problem | Admissible adapted controls, smoothness, Itô formula, integrability, and well-posedness |
| Interacting particles | A McKean–Vlasov approximation theorem for a specified population-dependent drift | Lipschitz/moment assumptions, coupling construction, and the exact mode of convergence |

**Done per track when:** the theorem is proved in Lean with all hypotheses
visible and linked to the relevant definitions. No unspecified rate in `N`,
continuous-time supremum bound, or discretization rate is inferred from a
fixed-time qualitative limit. Track stochastic-proof dependencies separately
from the numerical demonstration.

### 5. Establish an outer-iteration guarantee for a restricted class

Tracking: [#13](https://github.com/Varifold-Lab/LeanMFG/issues/13).

- [ ] Define a single-valued exact response map `Φ` on a specified complete
  space of population flows; include any best-response selection rule.
- [ ] First prove a conditional contraction result with constant `q < 1`, then
  verify its assumptions for a concrete nontrivial model. If another algorithm
  is chosen, state and prove that algorithm's own convergence hypotheses.
- [ ] Prove residual-to-solution control. If
  `D(m, Φ(m)) ≤ observed_residual + η` is certified and `m* = Φ(m*)`, target
  `D(m, m*) ≤ (observed_residual + η) / (1 - q)`.
- [ ] State whether `D` compares discrete slices or entire continuous flows.
  Extending a grid residual to all times requires temporal regularity bounds.
- [ ] Account for sampling, control-solve, discretization, and arithmetic errors
  when bounding `η`, with probability levels where appropriate. A discrete-map
  guarantee needs an additional bridge to the continuous MFG.

**Done when:** at least one instantiated theorem supports the reported claim.
Relaxation alone, MFG uniqueness alone, and existence of a mean-field limit do
not supply an outer-iteration convergence proof.

## Proposed module placement

These are proposed locations, not existing public APIs. Split files further
when a milestone becomes too large for one review.

| Layer | Proposed additions |
| --- | --- |
| `Model/` | `Probability/FiniteLaw.lean`, `Continuous/QuadraticMFG.lean` |
| `Theory/` | `Probability/FiniteTransport.lean`, `Continuous/KernelCoupling.lean`; later sampling, stochastic control, and mean-field results |
| `Algorithm/` | `Probability/Wasserstein1D.lean` for exact finite arithmetic |
| `Computational/` | `Continuous/ControlGrid.lean`, `Continuous/Particles.lean`, `Continuous/PopulationIteration.lean` |
| `Verification/` | Exact distance correctness, rollout stability, arithmetic bridges, and iteration certificates in the corresponding settings |
| `Examples/` | `Continuous/ParticleMFG.lean` with benchmark configuration and executable checks |

## Delivery and validation

Milestones 0–3 define the numerical MVP. Milestone 1 supplies its first formal
component; milestones 4–5 extend the guarantees. The linked milestone issues
are sub-issues of [the roadmap tracker](https://github.com/Varifold-Lab/LeanMFG/issues/7).
Comment on an unassigned issue with the part you intend to implement so a
maintainer can coordinate ownership. Link partial PRs with `Refs #<issue>`;
use `Closes #<issue>` only when all acceptance criteria are met. Keep the parent
open until all six milestones are complete. Avoid assigning dates to the
stochastic proofs until the prerequisite audit is complete.

For each implementation PR, run the applicable checks in the
[verification guide](../docs/app/docs/verification/page.mdx#required-checks),
including `lake exe mfglib_check` when touching `Computational/`. Follow the
[contribution guide](../CONTRIBUTING.md): no `sorry`, `admit`, or new axioms to
bypass proofs, and prove properties of the executable being advertised. Update
imports, examples, the verification scope, capability map, and changelog when
an implementation or guarantee actually lands.

The MVP excludes multidimensional transport, common noise, GPU work, general
MFG convergence, and finite-player Nash error bounds. Its completion means a
reproducible control–population computation with clearly scoped proofs and
diagnostics. A fully certified continuous MFG solver remains the later goal.
