import LeanMFG.Numerical.Binary64
import FloatLib.Floats.Formats.BinaryInterchange.Configured.Rounding.Proof
import FloatLib.Floats.Formats.BinaryInterchange.Analysis.Error
import FloatLib.Floats.Formats.IEEE754.Native.Representation
import Mathlib.Tactic.Ring

/-! Error bounds for the executable reductions. Budgets sum half-ULPs at the
actual intermediate operations, including subnormals. Finiteness is checked by
the runtime functions, rather than postulated for all floating-point values.
These are bounds relative to the exact real values of the stored inputs. -/
namespace LeanMFG.Numerical.Binary64

open FloatLib.Floats FloatLib.Floats.Formats.BinaryInterchange

noncomputable def denote (x : Value) : ℝ := Model.toReal (ExecFloat.Binary.toModel x)
noncomputable def epsilon (x : ℝ) : ℝ := Model.epsilonAt FloatFormat.binary64 x

theorem add_error (x y : Value) (hx : isFinite x = true) (hy : isFinite y = true)
    (hr : isFinite (add x y) = true) :
    |denote (add x y) - (denote x + denote y)| ≤ epsilon (denote x + denote y) := by
  have hm : ExecFloat.Binary.toModel (add x y) =
      Model.add (ExecFloat.Binary.toModel x) (ExecFloat.Binary.toModel y) :=
    ExecFloat.Binary.toModel_addWithRounding x y .nearestEven
  unfold denote epsilon
  rw [hm]
  exact Model.abs_toReal_add_sub_le _ _ rfl hx hy (by simpa only [isFinite,
    ExecFloat.Binary.isFinite, hm] using hr)

theorem mul_error (x y : Value) (hx : isFinite x = true) (hy : isFinite y = true)
    (hr : isFinite (mul x y) = true) :
    |denote (mul x y) - denote x * denote y| ≤ epsilon (denote x * denote y) := by
  have hm : ExecFloat.Binary.toModel (mul x y) =
      Model.mul (ExecFloat.Binary.toModel x) (ExecFloat.Binary.toModel y) :=
    ExecFloat.Binary.toModel_mulWithRounding x y .nearestEven
  unfold denote epsilon
  rw [hm]
  exact Model.abs_toReal_mul_sub_le _ _ rfl hx hy (by simpa only [isFinite,
    ExecFloat.Binary.isFinite, hm] using hr)

theorem sumFinite_initial {acc : Value} {xs : List Value}
    (h : sumFinite acc xs = true) : isFinite acc = true := by
  cases xs with
  | nil => exact h
  | cons x xs => exact (Bool.and_eq_true_iff.mp (Bool.and_eq_true_iff.mp h).1).1

theorem sumFinite_result {acc : Value} {xs : List Value}
    (h : sumFinite acc xs = true) : isFinite (sumFrom acc xs) = true := by
  induction xs generalizing acc with
  | nil => exact h
  | cons x xs ih => exact ih (Bool.and_eq_true_iff.mp h).2

noncomputable def sumErrorBudget (acc : Value) : List Value → ℝ
  | [] => 0
  | x :: xs => sumErrorBudget (add acc x) xs + epsilon (denote acc + denote x)

/-- The left-to-right executable sum differs from the exact real sum by at most
the accumulated local rounding budget. -/
theorem sumFrom_error (acc : Value) (xs : List Value) (h : sumFinite acc xs = true) :
    |denote (sumFrom acc xs) - (denote acc + (xs.map denote).sum)| ≤
      sumErrorBudget acc xs := by
  induction xs generalizing acc with
  | nil => simp [sumFrom, sumErrorBudget]
  | cons x xs ih =>
    obtain ⟨hab, ht⟩ := Bool.and_eq_true_iff.mp h
    obtain ⟨ha, hx⟩ := Bool.and_eq_true_iff.mp hab
    have he := add_error acc x ha hx (sumFinite_initial ht)
    have hi := ih (add acc x) ht
    simp only [sumFrom, List.map_cons, List.sum_cons, sumErrorBudget]
    calc
      _ = |(denote (sumFrom (add acc x) xs) -
          (denote (add acc x) + (xs.map denote).sum)) +
          (denote (add acc x) - (denote acc + denote x))| := by congr 1; ring
      _ ≤ _ := (abs_add_le _ _).trans (add_le_add hi he)

@[simp] theorem denote_zero : denote zero = 0 := by
  simp [denote, zero, ExecFloat.Binary.zero, ExecFloat.Binary.ofModel,
    ExecFloat.Binary.toModel, Configured.Family.toModel_ofModel]

theorem sum_error (xs : List Value) (h : sumFinite zero xs = true) :
    |denote (sum xs) - (xs.map denote).sum| ≤ sumErrorBudget zero xs := by
  simpa only [sum, denote_zero, zero_add] using sumFrom_error zero xs h

noncomputable def exactDot (xs : List (Value × Value)) : ℝ :=
  (xs.map fun p => denote p.1 * denote p.2).sum

noncomputable def productErrorBudget (xs : List (Value × Value)) : ℝ :=
  (xs.map fun p => epsilon (denote p.1 * denote p.2)).sum

theorem products_error (xs : List (Value × Value))
    (h : xs.all (fun p => isFinite p.1 && isFinite p.2 && isFinite (mul p.1 p.2)) = true) :
    |((products xs).map denote).sum - exactDot xs| ≤ productErrorBudget xs := by
  induction xs with
  | nil => simp [products, exactDot, productErrorBudget]
  | cons p xs ih =>
    obtain ⟨hp, ht⟩ := Bool.and_eq_true_iff.mp h
    obtain ⟨hab, hm⟩ := Bool.and_eq_true_iff.mp hp
    obtain ⟨ha, hb⟩ := Bool.and_eq_true_iff.mp hab
    have he := mul_error p.1 p.2 ha hb hm
    have hi := ih ht
    simp only [products, List.map_cons, List.sum_cons, exactDot, productErrorBudget] at *
    calc
      _ = |(denote (mul p.1 p.2) - denote p.1 * denote p.2) +
          ((xs.map (fun p => mul p.1 p.2)).map denote |>.sum) - exactDot xs| := by
            simp only [exactDot]; congr 1; ring
      _ = |(denote (mul p.1 p.2) - denote p.1 * denote p.2) +
          (((xs.map (fun p => mul p.1 p.2)).map denote).sum - exactDot xs)| := by
            congr 1; ring
      _ ≤ _ := (abs_add_le _ _).trans (add_le_add he hi)

noncomputable def dotErrorBudget (xs : List (Value × Value)) : ℝ :=
  sumErrorBudget zero (products xs) + productErrorBudget xs

/-- Includes both separately rounded products and all rounded additions. -/
theorem dot_error (xs : List (Value × Value)) (h : dotFinite xs = true) :
    |denote (dot xs) - exactDot xs| ≤ dotErrorBudget xs := by
  obtain ⟨hp, hs⟩ := Bool.and_eq_true_iff.mp h
  have he := sum_error (products xs) hs
  have hm := products_error xs hp
  calc
    _ = |(denote (sum (products xs)) - ((products xs).map denote).sum) +
        (((products xs).map denote).sum - exactDot xs)| := by unfold dot; congr 1; ring
    _ ≤ _ := (abs_add_le _ _).trans (add_le_add he hm)

theorem checkedSum_sound {xs : List Value} {result : Value}
    (h : checkedSum xs = some result) :
    isFinite result = true ∧
      |denote result - (xs.map denote).sum| ≤ sumErrorBudget zero xs := by
  unfold checkedSum at h
  split at h
  next hf => cases Option.some.inj h; exact ⟨sumFinite_result hf, sum_error xs hf⟩
  next => contradiction

theorem checkedDot_sound {xs : List (Value × Value)} {result : Value}
    (h : checkedDot xs = some result) :
    isFinite result = true ∧ |denote result - exactDot xs| ≤ dotErrorBudget xs := by
  unfold checkedDot at h
  split at h
  next hf =>
    cases Option.some.inj h
    exact ⟨sumFinite_result (Bool.and_eq_true_iff.mp hf).2, dot_error xs hf⟩
  next => contradiction

/-- Exporting and importing preserves the real interpretation. NaN payloads may
change at that boundary; the error theorems separately require finite execution. -/
@[simp] theorem denote_ofFloat_toFloat (x : Value) :
    denote (ofFloat (toFloat x)) = denote x := by
  unfold denote ofFloat toFloat
  rw [ExecFloat.Binary.toModel_ofFloat, ExecFloat.Binary.toModel_toFloat_eq,
    Model.ofFloatModel_toFloatModel]
  let m : Model FloatFormat.binary64 := ExecFloat.Binary.toModel x
  change Model.toReal (Model.canonicalizeModel m) = Model.toReal m
  have h₁ := Model.toReal_eq_unpackedToReal_toModel (fmt := FloatFormat.binary64)
    rfl (Model.canonicalizeModel m)
  have h₂ := Model.toReal_eq_unpackedToReal_toModel (fmt := FloatFormat.binary64) rfl m
  rw [Model.toModel_canonicalizeModel] at h₁
  exact h₁.trans h₂.symm

theorem sumFloat_error (xs : Array Float)
    (h : sumFinite zero (xs.toList.map ofFloat) = true) :
    |denote (ofFloat (sumFloat xs)) - ((xs.toList.map ofFloat).map denote).sum| ≤
      sumErrorBudget zero (xs.toList.map ofFloat) := by
  simpa only [sumFloat, denote_ofFloat_toFloat] using sum_error _ h

theorem dotFloat_error (xs ys : Array Float)
    (h : dotFinite ((xs.toList.zip ys.toList).map fun p => (ofFloat p.1, ofFloat p.2)) = true) :
    let pairs := (xs.toList.zip ys.toList).map fun p => (ofFloat p.1, ofFloat p.2)
    |denote (ofFloat (dotFloat xs ys)) - exactDot pairs| ≤ dotErrorBudget pairs := by
  simpa only [dotFloat, denote_ofFloat_toFloat] using dot_error _ h

theorem checkedDotFloat_sound {xs ys : Array Float} {result : Value}
    (h : checkedDotFloat xs ys = some result) :
    xs.size = ys.size ∧ isFinite result = true ∧
      let pairs := (xs.toList.zip ys.toList).map fun p => (ofFloat p.1, ofFloat p.2)
      |denote result - exactDot pairs| ≤ dotErrorBudget pairs := by
  unfold checkedDotFloat at h
  split at h
  next hsize => exact ⟨by simpa using hsize, checkedDot_sound h⟩
  next => contradiction

end LeanMFG.Numerical.Binary64
