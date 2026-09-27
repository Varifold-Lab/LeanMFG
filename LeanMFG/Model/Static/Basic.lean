import Mathlib.Data.Rat.Defs
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Tactic

/-!
# Finite static mean field games

Probabilities and rewards are rational, so finite expectations are executable.
The representative player's strategy varies while the population stays fixed.
This finite rational representation uses mathlib sums; it does not assert that
every game has a rational equilibrium.
-/

namespace LeanMFG.Static

variable (Action : Type*) [Fintype Action]

/-- A rational probability distribution over a finite action type. -/
@[ext] structure Distribution where
  prob : Action → ℚ
  nonneg : ∀ a, 0 ≤ prob a
  sum_eq_one : ∑ a, prob a = 1

namespace Distribution

variable {Action} [DecidableEq Action]

/-- Put all mass on one action. -/
def pure (a : Action) : Distribution Action where
  prob b := if b = a then 1 else 0
  nonneg b := by split_ifs <;> norm_num
  sum_eq_one := by simp

@[simp] theorem pure_prob (a b : Action) :
    (pure a).prob b = if b = a then 1 else 0 := rfl

end Distribution

/-- The reward may depend on the entire population distribution. -/
structure Game [Nonempty Action] where
  reward : Action → Distribution Action → ℚ

namespace Game

variable {Action} [Nonempty Action] (g : Game Action)

/-- Individual strategy `p` is evaluated against the fixed population `m`. -/
def expectedReward (p m : Distribution Action) : ℚ :=
  ∑ a, p.prob a * g.reward a m

/-- The population strategy is optimal against itself. -/
def IsEquilibrium (m : Distribution Action) : Prop :=
  ∀ p : Distribution Action, g.expectedReward p m ≤ g.expectedReward m m

/-- Exact consistency and individual optimality within a nonnegative tolerance. -/
def IsEpsilonEquilibrium (m : Distribution Action) (ε : ℚ) : Prop :=
  0 ≤ ε ∧ ∀ p : Distribution Action,
    g.expectedReward p m ≤ g.expectedReward m m + ε

@[simp] theorem expectedReward_pure [DecidableEq Action]
    (a : Action) (m : Distribution Action) :
    g.expectedReward (Distribution.pure a) m = g.reward a m := by
  simp [expectedReward, Distribution.pure]

/-- A bound on every pure reward bounds every mixed reward. -/
theorem expectedReward_le (p m : Distribution Action) (r : ℚ)
    (h : ∀ a, g.reward a m ≤ r) : g.expectedReward p m ≤ r := by
  calc
    g.expectedReward p m ≤ ∑ a, p.prob a * r :=
      Finset.sum_le_sum fun a _ => mul_le_mul_of_nonneg_left (h a) (p.nonneg a)
    _ = r := by rw [← Finset.sum_mul, p.sum_eq_one, one_mul]

theorem isEquilibrium_iff_pure [DecidableEq Action] (m : Distribution Action) :
    g.IsEquilibrium m ↔ ∀ a, g.reward a m ≤ g.expectedReward m m := by
  constructor
  · intro h a
    simpa using h (Distribution.pure a)
  · intro h p
    exact g.expectedReward_le p m _ h

@[simp] theorem isEpsilonEquilibrium_zero_iff (m : Distribution Action) :
    g.IsEpsilonEquilibrium m 0 ↔ g.IsEquilibrium m := by
  simp [IsEpsilonEquilibrium, IsEquilibrium]

end Game
end LeanMFG.Static
