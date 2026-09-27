import LeanMFG.Model.Static.Basic
import LeanMFG.Model.Static.RockPaperScissors

/-! # The existing RPS model as a finite static game

The conversions are inverse, so quantifying over mixed deviations in either
representation gives the same exact and approximate equilibrium predicates.
-/

namespace LeanMFG.RPS

instance : Nonempty Action := ⟨.Rock⟩

private theorem sum_actions (f : Action → ℚ) :
    ∑ a, f a = f .Rock + f .Paper + f .Scissors := by
  rw [show (Finset.univ : Finset Action) = {.Rock, .Paper, .Scissors} from by
    ext a; cases a <;> simp]
  simp [add_assoc]

def Distribution.toStatic (p : Distribution) : Static.Distribution Action where
  prob := p.prob
  nonneg a := by
    cases a
    · exact p.rock_nonneg
    · exact p.paper_nonneg
    · exact p.scissors_nonneg
  sum_eq_one := by simpa [sum_actions, prob] using p.sum_eq_one

def Distribution.ofStatic (p : Static.Distribution Action) : Distribution where
  rock := p.prob .Rock
  paper := p.prob .Paper
  scissors := p.prob .Scissors
  rock_nonneg := p.nonneg .Rock
  paper_nonneg := p.nonneg .Paper
  scissors_nonneg := p.nonneg .Scissors
  sum_eq_one := by simpa [sum_actions] using p.sum_eq_one

@[simp] theorem Distribution.ofStatic_toStatic (p : Distribution) :
    ofStatic p.toStatic = p := by cases p; rfl

@[simp] theorem Distribution.toStatic_ofStatic (p : Static.Distribution Action) :
    (ofStatic p).toStatic = p := by
  ext a
  cases a <;> rfl

/-- RPS with exactly the reward convention of the original model. -/
def staticGame : Static.Game Action where
  reward a m := reward a (Distribution.ofStatic m)

@[simp] theorem staticGame_expectedReward (p m : Distribution) :
    staticGame.expectedReward p.toStatic m.toStatic = expectedReward p m := by
  simp [Static.Game.expectedReward, staticGame, Distribution.toStatic,
    Distribution.ofStatic, sum_actions, expectedReward, Distribution.prob, reward]

theorem isEquilibrium_iff_static (m : Distribution) :
    IsEquilibrium m ↔ staticGame.IsEquilibrium m.toStatic := by
  constructor
  · intro h p
    have hp := h (Distribution.ofStatic p)
    simpa only [← staticGame_expectedReward, Distribution.toStatic_ofStatic] using hp
  · intro h p
    simpa only [staticGame_expectedReward] using h p.toStatic

theorem isEpsilonEquilibrium_iff_static (m : Distribution) (ε : ℚ) :
    IsEpsilonEquilibrium m ε ↔ staticGame.IsEpsilonEquilibrium m.toStatic ε := by
  constructor
  · rintro ⟨hε, h⟩
    refine ⟨hε, fun p => ?_⟩
    have hp := h (Distribution.ofStatic p)
    simpa only [← staticGame_expectedReward, Distribution.toStatic_ofStatic] using hp
  · rintro ⟨hε, h⟩
    exact ⟨hε, fun p => by simpa only [staticGame_expectedReward] using h p.toStatic⟩

end LeanMFG.RPS
