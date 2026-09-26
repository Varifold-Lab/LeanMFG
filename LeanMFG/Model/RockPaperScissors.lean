import Mathlib.Data.Rat.Defs
import Mathlib.Tactic

/-!
# A static rock-paper-scissors mean field game

The representative player's mixed strategy `p` and the fixed population
distribution `m` have the same type but play distinct roles. A unilateral
deviation changes `p` while leaving `m` fixed.
-/

namespace LeanMFG.RPS

inductive Action where
  | Rock | Paper | Scissors
  deriving DecidableEq, Repr

instance instFintypeAction : Fintype Action where
  elems := {.Rock, .Paper, .Scissors}
  complete := by intro a; cases a <;> simp

/-- A rational probability distribution on the three actions. -/
structure Distribution where
  rock : ℚ
  paper : ℚ
  scissors : ℚ
  rock_nonneg : 0 ≤ rock
  paper_nonneg : 0 ≤ paper
  scissors_nonneg : 0 ≤ scissors
  sum_eq_one : rock + paper + scissors = 1

def Distribution.prob (p : Distribution) : Action → ℚ
  | .Rock => p.rock
  | .Paper => p.paper
  | .Scissors => p.scissors

/-- Daily play: a win scores 1, a loss scores -1, and a tie scores 0. -/
def reward (a : Action) (m : Distribution) : ℚ :=
  match a with
  | .Rock => m.scissors - m.paper
  | .Paper => m.rock - m.scissors
  | .Scissors => m.paper - m.rock

/-- The finite sum `∑ a, p(a) * reward a m`, expanded over three actions. -/
def expectedReward (p m : Distribution) : ℚ :=
  p.rock * reward .Rock m +
  p.paper * reward .Paper m +
  p.scissors * reward .Scissors m

theorem expectedReward_eq_sum (p m : Distribution) :
    expectedReward p m =
      ∑ a : Action, p.prob a * reward a m := by
  rw [show (Finset.univ : Finset Action) = {.Rock, .Paper, .Scissors} from by
    ext a; cases a <;> simp]
  simp [expectedReward, Distribution.prob, add_assoc]

/-- No rational mixed deviation improves on the consistent population strategy. -/
def IsEquilibrium (m : Distribution) : Prop :=
  ∀ p : Distribution, expectedReward p m ≤ expectedReward m m

/-- Consistency is exact; only individual optimality is relaxed by `ε`. -/
def IsEpsilonEquilibrium (m : Distribution) (ε : ℚ) : Prop :=
  0 ≤ ε ∧ ∀ p : Distribution, expectedReward p m ≤ expectedReward m m + ε

/-- A pure action, regarded as a rational mixed strategy. -/
def pure : Action → Distribution
  | .Rock =>
    ⟨1, 0, 0, by norm_num, by norm_num, by norm_num, by norm_num⟩
  | .Paper =>
    ⟨0, 1, 0, by norm_num, by norm_num, by norm_num, by norm_num⟩
  | .Scissors =>
    ⟨0, 0, 1, by norm_num, by norm_num, by norm_num, by norm_num⟩

@[simp] theorem expectedReward_pure (a : Action) (m : Distribution) :
    expectedReward (pure a) m = reward a m := by
  cases a <;> simp [pure, expectedReward]

/-- The symmetric rational distribution. -/
def uniform : Distribution :=
  ⟨1 / 3, 1 / 3, 1 / 3, by norm_num, by norm_num, by norm_num, by norm_num⟩

end LeanMFG.RPS
