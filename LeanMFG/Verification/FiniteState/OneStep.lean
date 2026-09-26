import LeanMFG.Algorithm.FiniteState.OneStep
import Mathlib.Algebra.Order.BigOperators.Group.Finset

namespace LeanMFG.FiniteState

variable {State Action : Type*} [Fintype State] [Fintype Action]
  [LinearOrder Action] [Inhabited Action]

/-- The executable list argmax returns an action of maximal value. -/
theorem bestAction_optimal (G : Game State Action) (m : Distribution State)
    (s : State) (a : Action) :
    actionValue G m s a ≤ actionValue G m s (bestAction G m s) := by
  let f := actionValue G m s
  let candidates := default :: (Finset.univ : Finset Action).sort (· ≤ ·)
  have ha : a ∈ candidates := by
    apply List.mem_cons_of_mem
    exact (Finset.mem_sort (· ≤ ·)).2 (Finset.mem_univ a)
  cases harg : candidates.argmax f with
  | none =>
    have hempty : candidates = [] := List.argmax_eq_none.mp harg
    simp [candidates] at hempty
  | some b =>
    have hb : b ∈ candidates.argmax f := by simp [harg]
    have hmax := List.le_of_mem_argmax ha hb
    simpa [bestAction, candidates, f, harg] using hmax

private theorem expect_pure {α : Type*} [Fintype α] [DecidableEq α]
    (a : α) (f : α → ℚ) : (Distribution.pure a).expect f = f a := by
  simp [Distribution.expect, Distribution.pure]

/-- No mixed action beats the maximizing pure action. -/
theorem expect_le_bestAction (G : Game State Action) (m : Distribution State)
    (s : State) (p : Distribution Action) :
    p.expect (actionValue G m s) ≤ actionValue G m s (bestAction G m s) := by
  unfold Distribution.expect
  calc
    (∑ a, p.prob a * actionValue G m s a) ≤
        ∑ a, p.prob a * actionValue G m s (bestAction G m s) := by
      apply Finset.sum_le_sum
      intro a _
      exact mul_le_mul_of_nonneg_left (bestAction_optimal G m s a) (p.nonneg a)
    _ = actionValue G m s (bestAction G m s) := by
      rw [← Finset.sum_mul, p.total, one_mul]

/-- The executable best-response policy maximizes expected value at fixed `m`. -/
theorem value_le_bestResponse (G : Game State Action) (m : Distribution State)
    (π : Policy State Action) :
    value G π m ≤ value G (bestResponse G m) m := by
  unfold value Distribution.expect
  apply Finset.sum_le_sum
  intro s _
  apply mul_le_mul_of_nonneg_left _ (G.initial.nonneg s)
  calc
    (π s).expect (actionValue G m s) ≤
        actionValue G m s (bestAction G m s) :=
      expect_le_bestAction G m s (π s)
    _ = (bestResponse G m s).expect (actionValue G m s) := by
      simp [bestResponse, expect_pure]

/-- Exploitability is always nonnegative. -/
theorem exploitability_nonneg (G : Game State Action)
    (π : Policy State Action) : 0 ≤ exploitability G π := by
  unfold exploitability
  exact sub_nonneg.mpr (value_le_bestResponse G (inducedTerminal G π) π)

/-- The executable checker accepts exactly the quantified ε-equilibria. -/
theorem checkEpsilonEquilibrium_iff (G : Game State Action)
    (π : Policy State Action) (ε : ℚ) :
    checkEpsilonEquilibrium G π ε = true ↔ IsEpsilonEquilibrium G π ε := by
  simp only [checkEpsilonEquilibrium, decide_eq_true_eq, IsEpsilonEquilibrium]
  constructor
  · rintro ⟨hε, hgap⟩
    refine ⟨hε, ?_⟩
    intro π'
    have hbest := value_le_bestResponse G (inducedTerminal G π) π'
    unfold exploitability at hgap
    linarith
  · rintro ⟨hε, hdeviation⟩
    refine ⟨hε, ?_⟩
    have hbest := hdeviation (bestResponse G (inducedTerminal G π))
    unfold exploitability
    linarith

/-- A zero exploitability certificate is equivalent to exact equilibrium. -/
theorem exploitability_eq_zero_iff (G : Game State Action)
    (π : Policy State Action) :
    exploitability G π = 0 ↔ IsEquilibrium G π := by
  constructor
  · intro hzero π'
    have hbest := value_le_bestResponse G (inducedTerminal G π) π'
    unfold exploitability at hzero
    linarith
  · intro heq
    have hbest := heq (bestResponse G (inducedTerminal G π))
    have hnonneg := exploitability_nonneg G π
    unfold exploitability at hnonneg ⊢
    linarith

end LeanMFG.FiniteState
