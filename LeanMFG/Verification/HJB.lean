import LeanMFG.Theory.HJB.ClassicalSolution
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Tactic

/-!
# Classical HJB verification

A classical solution bounds the cost of an admissible path when the candidate
value's derivative along that path is interval integrable. A path using the
feedback control `a = -∂ₓu` attains the bound. The quadratic example proves
the integrability condition for all of its admissible paths.
-/

namespace LeanMFG.ContinuousControl.HJB

open MeasureTheory Set

private theorem value_along_path_hasDerivAt {P : Problem} (U : ClassicalSolution P)
    {z : InitialCondition} (γ : AdmissiblePath P z) (s : ℝ)
    (hs : s ∈ Icc z.time 1) :
    HasDerivAt (fun r => U.value r (γ.state r))
      (U.timeDerivative s (γ.state s) +
        U.spaceDerivative s (γ.state s) * γ.control s) s := by
  have hs0 : s ∈ Icc (0 : ℝ) 1 := ⟨le_trans z.time_nonneg hs.1, hs.2⟩
  let f : ℝ × ℝ → ℝ := fun p => U.value p.1 p.2
  let L := fderiv ℝ f (s, γ.state s)
  have hF : HasFDerivAt f L (s, γ.state s) :=
    ((U.smooth s hs0 (γ.state s)).differentiableAt (by norm_num)).hasFDerivAt
  have htimePair : HasDerivAt (fun r : ℝ => (r, γ.state s)) (1, 0) s :=
    (hasDerivAt_id s).prodMk (hasDerivAt_const s _)
  have hspacePair : HasDerivAt (fun y : ℝ => (s, y)) (0, 1) (γ.state s) :=
    (hasDerivAt_const (γ.state s) _).prodMk (hasDerivAt_id (γ.state s))
  have htime : L (1, 0) = U.timeDerivative s (γ.state s) := by
    have h := hF.comp_hasDerivAt s htimePair
    have h' : HasDerivAt (fun r => U.value r (γ.state s)) (L (1, 0)) s := by
      convert! h using 1
    exact (U.hasTimeDerivative s hs0 (γ.state s)).unique h' |>.symm
  have hspace : L (0, 1) = U.spaceDerivative s (γ.state s) := by
    have h := hF.comp_hasDerivAt (γ.state s) hspacePair
    have h' : HasDerivAt (fun y => U.value s y) (L (0, 1)) (γ.state s) := by
      convert! h using 1
    exact (U.hasSpaceDerivative s hs0 (γ.state s)).unique h' |>.symm
  have hpair : HasDerivAt (fun r : ℝ => (r, γ.state r)) (1, γ.control s) s :=
    (hasDerivAt_id s).prodMk (γ.state_deriv s hs)
  have h := hF.comp_hasDerivAt s hpair
  have hL : L (1, γ.control s) =
      U.timeDerivative s (γ.state s) +
        U.spaceDerivative s (γ.state s) * γ.control s := by
    have hsum : ((1 : ℝ), γ.control s) = ((1 : ℝ), (0 : ℝ)) +
        γ.control s • ((0 : ℝ), (1 : ℝ)) := by
      ext <;> simp
    rw [hsum, map_add, map_smul, htime, hspace]
    simp [smul_eq_mul, mul_comm]
  rw [hL] at h
  convert! h using 1

/-- The derivative of the candidate value along a path. -/
noncomputable def alongPathDerivative {P : Problem} (U : ClassicalSolution P)
    {z : InitialCondition} (γ : AdmissiblePath P z) (s : ℝ) : ℝ :=
  U.timeDerivative s (γ.state s) +
    U.spaceDerivative s (γ.state s) * γ.control s

/-- Verification inequality. The derivative along this path is assumed
interval integrable so the fundamental theorem of calculus applies. -/
theorem verification_lower_bound {P : Problem} (U : ClassicalSolution P)
    {z : InitialCondition} (γ : AdmissiblePath P z)
    (hint : IntervalIntegrable (alongPathDerivative U γ) volume z.time 1) :
    U.value z.time z.position ≤ totalCost P z γ := by
  have hderiv : ∀ s ∈ uIcc z.time 1,
      HasDerivAt (fun r => U.value r (γ.state r)) (alongPathDerivative U γ s) s := by
    intro s hs
    apply value_along_path_hasDerivAt U γ s
    simpa only [uIcc_of_le z.time_le_one] using hs
  have hFTC := intervalIntegral.integral_eq_sub_of_hasDerivAt hderiv hint
  have hmono :
      (∫ s in z.time..1, -alongPathDerivative U γ s) ≤
        ∫ s in z.time..1, P.runningCost s (γ.state s) (γ.control s) := by
    apply intervalIntegral.integral_mono_on z.time_le_one hint.neg γ.running_integrable
    intro s hs
    have hs0 : s ∈ Icc (0 : ℝ) 1 := ⟨le_trans z.time_nonneg hs.1, hs.2⟩
    have heq := U.equation s hs0 (γ.state s)
    have hsq := sq_nonneg (γ.control s + U.spaceDerivative s (γ.state s))
    dsimp [alongPathDerivative, Problem.runningCost]
    nlinarith
  simp only [intervalIntegral.integral_neg] at hmono
  rw [γ.initial_state] at hFTC
  rw [U.terminal] at hFTC
  unfold totalCost
  linarith

/-- A path following `a = -∂ₓu` has cost exactly equal to the candidate value. -/
theorem verification_attains {P : Problem} (U : ClassicalSolution P)
    {z : InitialCondition} (γ : AdmissiblePath P z)
    (hint : IntervalIntegrable (alongPathDerivative U γ) volume z.time 1)
    (hfeedback : ∀ s ∈ Icc z.time 1,
      γ.control s = -U.spaceDerivative s (γ.state s)) :
    totalCost P z γ = U.value z.time z.position := by
  have hderiv : ∀ s ∈ uIcc z.time 1,
      HasDerivAt (fun r => U.value r (γ.state r)) (alongPathDerivative U γ s) s := by
    intro s hs
    apply value_along_path_hasDerivAt U γ s
    simpa only [uIcc_of_le z.time_le_one] using hs
  have hFTC := intervalIntegral.integral_eq_sub_of_hasDerivAt hderiv hint
  have hcostEq :
      (∫ s in z.time..1, P.runningCost s (γ.state s) (γ.control s)) =
        ∫ s in z.time..1, -alongPathDerivative U γ s := by
    apply intervalIntegral.integral_congr
    intro s hs
    have hs' : s ∈ Icc z.time 1 := by
      simpa only [uIcc_of_le z.time_le_one] using hs
    have hs0 : s ∈ Icc (0 : ℝ) 1 := ⟨le_trans z.time_nonneg hs'.1, hs'.2⟩
    have heq := U.equation s hs0 (γ.state s)
    have hcontrol := hfeedback s hs'
    dsimp [alongPathDerivative, Problem.runningCost]
    rw [hcontrol]
    nlinarith
  simp only [intervalIntegral.integral_neg] at hcostEq
  rw [γ.initial_state] at hFTC
  rw [U.terminal] at hFTC
  unfold totalCost
  rw [hcostEq]
  linarith

/-- The feedback path is optimal among paths whose value derivative is
interval integrable. -/
theorem verification_optimal {P : Problem} (U : ClassicalSolution P)
    {z : InitialCondition} (γ : AdmissiblePath P z)
    (hintγ : IntervalIntegrable (alongPathDerivative U γ) volume z.time 1)
    (hfeedback : ∀ s ∈ Icc z.time 1,
      γ.control s = -U.spaceDerivative s (γ.state s))
    (η : AdmissiblePath P z)
    (hintη : IntervalIntegrable (alongPathDerivative U η) volume z.time 1) :
    totalCost P z γ ≤ totalCost P z η := by
  rw [verification_attains U γ hintγ hfeedback]
  exact verification_lower_bound U η hintη

end LeanMFG.ContinuousControl.HJB
