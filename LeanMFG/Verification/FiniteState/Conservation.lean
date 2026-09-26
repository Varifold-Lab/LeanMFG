import LeanMFG.Model.FiniteState.OneStep

/-!
# Conservation of population mass

These results depend only on normalized transition probabilities and mixed
policies. No best-response or equilibrium assumption is used.
-/

namespace LeanMFG.FiniteState

variable {State Action : Type*} [Fintype State] [Fintype Action]

/-- The raw weighted update has nonnegative mass at every destination. -/
theorem update_nonneg (m : Distribution State)
    (transition : State → Action → Distribution State)
    (π : Policy State Action) (s' : State) :
    0 ≤ ∑ s, m.prob s * ∑ a, (π s).prob a * (transition s a).prob s' := by
  apply Finset.sum_nonneg
  intro s _
  apply mul_nonneg (m.nonneg s)
  exact Finset.sum_nonneg fun a _ => mul_nonneg ((π s).nonneg a) ((transition s a).nonneg s')

/-- The raw weighted update preserves total population mass. -/
theorem update_total (m : Distribution State)
    (transition : State → Action → Distribution State)
    (π : Policy State Action) :
    (∑ s', ∑ s, m.prob s * ∑ a, (π s).prob a *
      (transition s a).prob s') = 1 := by
  have hinner (s : State) :
      (∑ s', ∑ a, (π s).prob a * (transition s a).prob s') = 1 := by
    calc
      (∑ s', ∑ a, (π s).prob a * (transition s a).prob s') =
          ∑ a, ∑ s', (π s).prob a * (transition s a).prob s' := Finset.sum_comm
      _ = ∑ a, (π s).prob a * (∑ s', (transition s a).prob s') := by
        simp_rw [Finset.mul_sum]
      _ = ∑ a, (π s).prob a := by simp [Distribution.total]
      _ = 1 := (π s).total
  calc
    (∑ s', ∑ s, m.prob s * ∑ a, (π s).prob a *
        (transition s a).prob s') =
          ∑ s, ∑ s', m.prob s * ∑ a, (π s).prob a *
            (transition s a).prob s' := Finset.sum_comm
    _ = ∑ s, m.prob s * (∑ s', ∑ a, (π s).prob a *
        (transition s a).prob s') := by simp_rw [Finset.mul_sum]
    _ = ∑ s, m.prob s := by simp [hinner]
    _ = 1 := m.total

/-- At any step, any policy sequence leaves a nonnegative population law. -/
theorem evolve_nonneg (m₀ : Distribution State)
    (transition : State → Action → Distribution State)
    (π : ℕ → Policy State Action) (n : ℕ) (s : State) :
    0 ≤ (evolve m₀ transition π n).prob s := by
  cases n with
  | zero => exact m₀.nonneg s
  | succ n =>
      simpa only [evolve, update, Distribution.bind] using
        update_nonneg (evolve m₀ transition π n) transition (π n) s

/-- At any step, any policy sequence preserves total mass `1`. -/
theorem evolve_total (m₀ : Distribution State)
    (transition : State → Action → Distribution State)
    (π : ℕ → Policy State Action) (n : ℕ) :
    (∑ s, (evolve m₀ transition π n).prob s) = 1 := by
  cases n with
  | zero => exact m₀.total
  | succ n =>
      simpa only [evolve, update, Distribution.bind] using
        update_total (evolve m₀ transition π n) transition (π n)

end LeanMFG.FiniteState
