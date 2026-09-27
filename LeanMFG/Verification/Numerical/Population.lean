import LeanMFG.Numerical.Population
import LeanMFG.Verification.Numerical.Binary64
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Tactic.Linarith

/-! One-step error bounds for the actual population update, including input
perturbations and the distinction between exact and approximate mass balance. -/
namespace LeanMFG.Numerical.Population

open Binary64
open scoped BigOperators

variable {n k : Nat}

/-- Real arithmetic on the exact values of the stored inputs. -/
noncomputable def exactUpdate (d : Input n k) (dst : Fin n) : ℝ :=
  ∑ src, denote (d.population src) * denote (d.transition dst src)

noncomputable def errorBudget (d : Input n k) (dst : Fin n) : ℝ :=
  dotErrorBudget (rowPairs d dst)

theorem finite_iff (d : Input n k) :
    finite d = true ↔ ∀ dst, dotFinite (rowPairs d dst) = true := by
  simp [finite]

theorem update_finite (d : Input n k) (h : finite d = true) (dst : Fin n) :
    isFinite (update d dst) = true :=
  sumFinite_result (Bool.and_eq_true_iff.mp ((finite_iff d).mp h dst)).2

theorem update_error (d : Input n k) (h : finite d = true) (dst : Fin n) :
    |denote (update d dst) - exactUpdate d dst| ≤ errorBudget d dst := by
  have he := dot_error (rowPairs d dst) ((finite_iff d).mp h dst)
  simpa [update, exactUpdate, errorBudget, exactDot, rowPairs,
    List.map_ofFn, List.sum_ofFn] using he

/-- Total L1 error of the computed next-state population. -/
theorem update_l1_error (d : Input n k) (h : finite d = true) :
    (∑ dst, |denote (update d dst) - exactUpdate d dst|) ≤ ∑ dst, errorBudget d dst :=
  Finset.sum_le_sum fun dst _ => update_error d h dst

theorem checkedUpdate_sound {d : Input n k} {result : Fin n → Value}
    (h : checkedUpdate d = some result) :
    (∀ dst, isFinite (result dst) = true) ∧
    (∀ dst, |denote (result dst) - exactUpdate d dst| ≤ errorBudget d dst) := by
  unfold checkedUpdate at h
  split at h
  next hf =>
    cases Option.some.inj h
    exact ⟨update_finite d hf, update_error d hf⟩
  next => contradiction

/-- Exact column balance, without presuming normalization of stored values. -/
theorem exactUpdate_total (d : Input n k) :
    (∑ dst, exactUpdate d dst) =
      ∑ src, denote (d.population src) * ∑ dst, denote (d.transition dst src) := by
  simp only [exactUpdate, Finset.mul_sum]
  exact Finset.sum_comm

noncomputable def columnDefect (d : Input n k) (src : Fin k) : ℝ :=
  (∑ dst, denote (d.transition dst src)) - 1

/-- Deviation from the incoming mass: rounding plus actual transition-column defects.
The sums here are exact real sums of stored values, not another floating reduction. -/
theorem update_mass_error (d : Input n k) (h : finite d = true) :
    |(∑ dst, denote (update d dst)) - (∑ src, denote (d.population src))| ≤
      (∑ dst, errorBudget d dst) +
        ∑ src, |denote (d.population src)| * |columnDefect d src| := by
  have hround : |(∑ dst, denote (update d dst)) - ∑ dst, exactUpdate d dst| ≤
      ∑ dst, errorBudget d dst := by
    rw [← Finset.sum_sub_distrib]
    exact (Finset.abs_sum_le_sum_abs _ _).trans (update_l1_error d h)
  have hbalance : (∑ dst, exactUpdate d dst) - (∑ src, denote (d.population src)) =
      ∑ src, denote (d.population src) * columnDefect d src := by
    rw [exactUpdate_total, ← Finset.sum_sub_distrib]
    apply Finset.sum_congr rfl
    intro src _
    simp [columnDefect, mul_sub]
  calc
    _ = |((∑ dst, denote (update d dst)) - ∑ dst, exactUpdate d dst) +
        ((∑ dst, exactUpdate d dst) - ∑ src, denote (d.population src))| := by congr 1; ring
    _ ≤ _ := (abs_add_le _ _).trans (add_le_add hround (by
      rw [hbalance]
      simpa only [abs_mul] using Finset.abs_sum_le_sum_abs
        (fun src => denote (d.population src) * columnDefect d src) Finset.univ))

/-- Exact input normalization is an explicit additional premise, not a Float check. -/
theorem update_mass_error_of_normalized (d : Input n k) (h : finite d = true)
    (hmass : (∑ src, denote (d.population src)) = 1)
    (hcolumns : ∀ src, (∑ dst, denote (d.transition dst src)) = 1) :
    |(∑ dst, denote (update d dst)) - 1| ≤ ∑ dst, errorBudget d dst := by
  simpa [hmass, columnDefect, hcolumns] using update_mass_error d h

/-- Approximate input normalization contributes its actual mass defect as well. -/
theorem update_mass_error_to_one (d : Input n k) (h : finite d = true) :
    |(∑ dst, denote (update d dst)) - 1| ≤
      (∑ dst, errorBudget d dst) +
        (∑ src, |denote (d.population src)| * |columnDefect d src|) +
        |(∑ src, denote (d.population src)) - 1| := by
  calc
    _ = |((∑ dst, denote (update d dst)) - ∑ src, denote (d.population src)) +
        ((∑ src, denote (d.population src)) - 1)| := by congr 1; ring
    _ ≤ _ := (abs_add_le _ _).trans (add_le_add (update_mass_error d h) le_rfl)

/-- A different exact population/kernel may already differ from the stored input.
This includes population-dependent kernel error when the supplied bounds cover it. -/
theorem update_error_with_input (d : Input n k) (h : finite d = true)
    (population : Fin k → ℝ) (transition : Fin n → Fin k → ℝ)
    (populationError : Fin k → ℝ) (transitionError : Fin n → Fin k → ℝ)
    (hl : ∀ src, |denote (d.population src) - population src| ≤ populationError src)
    (hp : ∀ dst src, |denote (d.transition dst src) - transition dst src| ≤
      transitionError dst src) (dst : Fin n) :
    |denote (update d dst) - ∑ src, population src * transition dst src| ≤
      errorBudget d dst + ∑ src,
        (populationError src * |denote (d.transition dst src)| +
          |population src| * transitionError dst src) := by
  have hinput : |exactUpdate d dst - ∑ src, population src * transition dst src| ≤
      ∑ src, (populationError src * |denote (d.transition dst src)| +
        |population src| * transitionError dst src) := by
    rw [exactUpdate, ← Finset.sum_sub_distrib]
    apply (Finset.abs_sum_le_sum_abs _ _).trans
    apply Finset.sum_le_sum
    intro src _
    calc
      _ = |(denote (d.population src) - population src) * denote (d.transition dst src) +
          population src * (denote (d.transition dst src) - transition dst src)| := by
            congr 1; ring
      _ ≤ _ := (abs_add_le _ _).trans (by
        simp only [abs_mul]
        exact add_le_add (mul_le_mul_of_nonneg_right (hl src) (abs_nonneg _))
          (mul_le_mul_of_nonneg_left (hp dst src) (abs_nonneg _)))
  calc
    _ = |(denote (update d dst) - exactUpdate d dst) +
        (exactUpdate d dst - ∑ src, population src * transition dst src)| := by congr 1; ring
    _ ≤ _ := (abs_add_le _ _).trans (add_le_add (update_error d h dst) hinput)

@[simp] theorem forward_size (population transition : Array Float) :
    (forward n k population transition).size = n := by simp [forward]

/-- The array program's output denotes the typed kernel's result at every destination. -/
theorem forward_denote (population transition : Array Float) (dst : Fin n) :
    denote (ofFloat ((forward n k population transition).getD dst.val 0)) =
      denote (update (readInput n k population transition) dst) := by
  simp [forward, Array.getD, dst.isLt, denote_ofFloat_toFloat]

theorem forward_error (population transition : Array Float)
    (h : finite (readInput n k population transition) = true) (dst : Fin n) :
    let d := readInput n k population transition
    |denote (ofFloat ((forward n k population transition).getD dst.val 0)) -
      exactUpdate d dst| ≤ errorBudget d dst := by
  simpa only [forward_denote] using
    update_error (readInput n k population transition) h dst

theorem forward_l1_error (population transition : Array Float)
    (h : finite (readInput n k population transition) = true) :
    let d := readInput n k population transition
    (∑ dst : Fin n,
      |denote (ofFloat ((forward n k population transition).getD dst.val 0)) -
        exactUpdate d dst|) ≤ ∑ dst, errorBudget d dst := by
  simpa only [forward_denote] using update_l1_error (readInput n k population transition) h

theorem forward_mass_error (population transition : Array Float)
    (h : finite (readInput n k population transition) = true) :
    let d := readInput n k population transition
    |(∑ dst : Fin n, denote (ofFloat ((forward n k population transition).getD dst.val 0))) - 1| ≤
      (∑ dst, errorBudget d dst) +
        (∑ src, |denote (d.population src)| * |columnDefect d src|) +
        |(∑ src, denote (d.population src)) - 1| := by
  simpa only [forward_denote] using update_mass_error_to_one (readInput n k population transition) h

/-- Array bounds make the adapter's defaults unreachable on correctly shaped input. -/
theorem readInput_population (population transition : Array Float)
    (hsize : population.size = k) (src : Fin k) :
    (readInput n k population transition).population src =
      ofFloat (population[src.val]'(by simp [hsize])) := by
  simp [readInput, Array.getD, show src.val < population.size by omega]

theorem readInput_transition (population transition : Array Float)
    (hsize : transition.size = n * k) (dst : Fin n) (src : Fin k) :
    (readInput n k population transition).transition dst src =
      ofFloat (transition[dst.val * k + src.val]'(by
        rw [hsize]
        exact (Nat.add_lt_add_left src.isLt _).trans_le (by
          simpa [Nat.succ_mul] using Nat.mul_le_mul_right k dst.isLt))) := by
  have hi : dst.val * k + src.val < transition.size := by
    rw [hsize]
    exact (Nat.add_lt_add_left src.isLt _).trans_le (by
      simpa [Nat.succ_mul] using Nat.mul_le_mul_right k dst.isLt)
  simp [readInput, Array.getD, hi]

/-- Soundness for the array interface, including shape and every destination bound. -/
theorem checkedForward_sound {population transition result : Array Float}
    (h : checkedForward n k population transition = some result) :
    (0 < n ∧ 0 < k ∧ population.size = k ∧ transition.size = n * k) ∧
    result.size = n ∧
    (∀ dst : Fin n,
      let d := readInput n k population transition
      |denote (ofFloat (result.getD dst.val 0)) - exactUpdate d dst| ≤ errorBudget d dst) := by
  unfold checkedForward at h
  split at h
  next hf =>
    obtain ⟨hshape, hfinite⟩ := Bool.and_eq_true_iff.mp hf
    cases Option.some.inj h
    exact ⟨by simpa [validShape] using hshape, forward_size _ _,
      forward_error _ _ hfinite⟩
  next => contradiction

theorem checkedForward_mass_error {population transition result : Array Float}
    (h : checkedForward n k population transition = some result) :
    let d := readInput n k population transition
    |(∑ dst : Fin n, denote (ofFloat (result.getD dst.val 0))) - 1| ≤
      (∑ dst, errorBudget d dst) +
        (∑ src, |denote (d.population src)| * |columnDefect d src|) +
        |(∑ src, denote (d.population src)) - 1| := by
  unfold checkedForward at h
  split at h
  next hf =>
    cases Option.some.inj h
    exact forward_mass_error _ _ (Bool.and_eq_true_iff.mp hf).2
  next => contradiction

end LeanMFG.Numerical.Population
