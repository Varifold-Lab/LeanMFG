import LeanMFG.Model.Static.RockPaperScissorsAdapter
import LeanMFG.Theory.Static.RockPaperScissors

/-! # Executable finite static games beyond RPS -/

namespace LeanMFG.Static.Examples

/-- Two choices with a penalty equal to the mass choosing the same action. -/
def congestion : Game (Fin 2) where
  reward a m := -m.prob a

def balanced : Distribution (Fin 2) where
  prob _ := 1 / 2
  nonneg _ := by norm_num
  sum_eq_one := by norm_num [Fin.sum_univ_two]

theorem balanced_equilibrium : congestion.IsEquilibrium balanced := by
  rw [Game.isEquilibrium_iff_pure]
  intro a
  norm_num [congestion, Game.expectedReward, balanced, Fin.sum_univ_two]

/-- Concentrating everyone on one choice admits a profitable deviation. -/
theorem concentrated_not_equilibrium :
    ¬congestion.IsEquilibrium (Distribution.pure 0) := by
  intro h
  have hp := (congestion.isEquilibrium_iff_pure _).mp h 1
  norm_num [congestion, Game.expectedReward, Distribution.pure, Fin.sum_univ_two] at hp

/-- A single available action is allowed, including negative payoffs. -/
def singleton : Game (Fin 1) where
  reward _ _ := -2

example : singleton.IsEquilibrium (Distribution.pure 0) := by
  rw [Game.isEquilibrium_iff_pure]
  intro a
  simp [singleton]

example : ¬congestion.IsEpsilonEquilibrium balanced (-1) := by
  rintro ⟨h, _⟩
  norm_num at h

example : RPS.staticGame.IsEquilibrium RPS.uniform.toStatic :=
  (RPS.isEquilibrium_iff_static _).mp RPS.uniform_equilibrium

#guard congestion.expectedReward balanced balanced == (-1 / 2 : ℚ)
#guard congestion.expectedReward (Distribution.pure 1) (Distribution.pure 0) == 0
#guard singleton.expectedReward (Distribution.pure 0) (Distribution.pure 0) == -2
#guard RPS.staticGame.expectedReward RPS.uniform.toStatic RPS.uniform.toStatic == 0

end LeanMFG.Static.Examples
