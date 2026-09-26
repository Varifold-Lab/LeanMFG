import LeanMFG.Verification.HJB

/-!
# Quadratic HJB verification example

The feedback `a = -∂ₓu` is constant along the trajectory starting at
`(t₀, x₀)`: `a = -x₀ / (2 - t₀)` and `x(s) = x₀ + a (s - t₀)`.
-/

namespace LeanMFG.ContinuousControl.HJB

open MeasureTheory Set

/-- The explicit trajectory for the quadratic problem. -/
noncomputable def quadraticFeedbackPath (z : InitialCondition) :
    AdmissiblePath quadraticProblem z where
  state := fun s => z.position + (-z.position / (2 - z.time)) * (s - z.time)
  control := fun _ => -z.position / (2 - z.time)
  initial_state := by ring
  state_deriv := by
    intro s hs
    have hsub : HasDerivAt (fun r : ℝ => r - z.time) 1 s :=
      (hasDerivAt_id s).sub_const z.time
    have hmul := HasDerivAt.const_mul (-z.position / (2 - z.time)) hsub
    have hadd := (hasDerivAt_const s z.position).add hmul
    convert! hadd using 1; ring
  control_continuous := by fun_prop
  running_integrable := by
    apply Continuous.intervalIntegrable
    unfold Problem.runningCost quadraticProblem
    fun_prop

/-- Along any admissible path in the quadratic problem, the candidate's
derivative is continuous on the time interval and hence integrable. -/
theorem quadratic_alongPathDerivative_integrable {z : InitialCondition}
    (γ : AdmissiblePath quadraticProblem z) :
    IntervalIntegrable (alongPathDerivative quadraticClassicalSolution γ)
      volume z.time 1 := by
  have hstate : ContinuousOn γ.state (Icc z.time 1) :=
    HasDerivAt.continuousOn γ.state_deriv
  have htime : ∀ s ∈ Icc z.time 1, (2 : ℝ) - s ≠ 0 := by
    intro s hs
    have h : s ≤ 1 := hs.2
    linarith
  have hden : ContinuousOn (fun s : ℝ => 2 - s) (Icc z.time 1) := by
    fun_prop
  have hden2 : ContinuousOn (fun s : ℝ => 2 * (2 - s) ^ 2) (Icc z.time 1) := by
    fun_prop
  have hnonzero2 : ∀ s ∈ Icc z.time 1, (2 : ℝ) * (2 - s) ^ 2 ≠ 0 := by
    intro s hs
    exact mul_ne_zero (by norm_num) (pow_ne_zero 2 (htime s hs))
  have hcont : ContinuousOn (alongPathDerivative quadraticClassicalSolution γ)
      (Icc z.time 1) := by
    change ContinuousOn
      (fun s => γ.state s ^ 2 / (2 * (2 - s) ^ 2) +
        γ.state s / (2 - s) * γ.control s) (Icc z.time 1)
    exact ((hstate.pow 2).div hden2 hnonzero2).add
      ((hstate.div hden htime).mul γ.control_continuous)
  apply ContinuousOn.intervalIntegrable
  simpa only [uIcc_of_le z.time_le_one] using hcont

/-- The explicit trajectory follows the minimizing feedback. -/
theorem quadraticFeedbackPath_feedback (z : InitialCondition)
    (s : ℝ) (hs : s ∈ Icc z.time 1) :
    (quadraticFeedbackPath z).control s =
      -quadraticClassicalSolution.spaceDerivative s
        ((quadraticFeedbackPath z).state s) := by
  have hz : (2 : ℝ) - z.time ≠ 0 := by linarith [z.time_le_one]
  have hs' : (2 : ℝ) - s ≠ 0 := by linarith [hs.2]
  dsimp [quadraticFeedbackPath, quadraticClassicalSolution]
  field_simp
  ring

/-- The displayed path attains the quadratic candidate value. -/
theorem quadraticFeedbackPath_cost (z : InitialCondition) :
    totalCost quadraticProblem z (quadraticFeedbackPath z) =
      quadraticValue z.time z.position := by
  exact verification_attains quadraticClassicalSolution (quadraticFeedbackPath z)
    (quadratic_alongPathDerivative_integrable (quadraticFeedbackPath z))
    (quadraticFeedbackPath_feedback z)

/-- Every admissible path for the quadratic problem costs at least the
explicit feedback path. -/
theorem quadraticFeedbackPath_optimal (z : InitialCondition)
    (γ : AdmissiblePath quadraticProblem z) :
    totalCost quadraticProblem z (quadraticFeedbackPath z) ≤
      totalCost quadraticProblem z γ := by
  exact verification_optimal quadraticClassicalSolution (quadraticFeedbackPath z)
    (quadratic_alongPathDerivative_integrable (quadraticFeedbackPath z))
    (quadraticFeedbackPath_feedback z) γ
    (quadratic_alongPathDerivative_integrable γ)

end LeanMFG.ContinuousControl.HJB
