import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic

/-!
# One-dimensional deterministic control

This model is independent of the finite rock-paper-scissors game. Time runs
from an initial time in `[0, 1]` to the fixed terminal time `1`. A control is
a real-valued function, and the state follows `x'(s) = a(s)`.

The admissible class below uses continuous controls and differentiable state
paths. Integrability of the running cost is recorded explicitly, so the
interval integral in `totalCost` has its intended mathematical meaning.
-/

namespace LeanMFG.ContinuousControl

open MeasureTheory Set

/-- Exogenous running potential and terminal cost. The kinetic cost is fixed
to `a² / 2`. A later MFG model may obtain the potential from a fixed
population path. -/
structure Problem where
  potential : ℝ → ℝ → ℝ
  terminalCost : ℝ → ℝ

/-- Initial time and position for a problem with terminal time `1`. -/
structure InitialCondition where
  time : ℝ
  position : ℝ
  time_nonneg : 0 ≤ time
  time_le_one : time ≤ 1

/-- Kinetic effort plus the exogenous running potential. -/
noncomputable def Problem.runningCost (P : Problem) (s x a : ℝ) : ℝ :=
  a ^ 2 / 2 + P.potential s x

/-- A continuous control and a state path satisfying the dynamics. Derivatives
at the interval endpoints are ordinary two-sided derivatives of the supplied
real-valued extension of the path. -/
structure AdmissiblePath (P : Problem) (z : InitialCondition) where
  state : ℝ → ℝ
  control : ℝ → ℝ
  initial_state : state z.time = z.position
  state_deriv : ∀ s ∈ Icc z.time 1, HasDerivAt state (control s) s
  control_continuous : ContinuousOn control (Icc z.time 1)
  running_integrable :
    IntervalIntegrable (fun s => P.runningCost s (state s) (control s))
      volume z.time 1

/-- Running cost over the finite horizon plus the terminal cost. -/
noncomputable def totalCost (P : Problem) (z : InitialCondition)
    (γ : AdmissiblePath P z) : ℝ :=
  (∫ s in z.time..1, P.runningCost s (γ.state s) (γ.control s)) +
    P.terminalCost (γ.state 1)

end LeanMFG.ContinuousControl
