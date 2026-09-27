import LeanMFG.Verification.FiniteState.OneStep

/-!
# A one-step Left/Right mean field game

Initially everyone is at state `0`. Action `0` moves to state `1` (Left),
and action `1` moves to state `2` (Right). A Left agent receives minus the
Left population mass; a Right agent receives minus twice the Right mass.
The representative player's deviation leaves the population law fixed.
-/

namespace LeanMFG.FiniteState.LeftRight

open LeanMFG.FiniteState

abbrev State := Fin 3
abbrev Action := Fin 2

/-- The single-decision environment. -/
def game : Game State Action where
  initial := Distribution.pure 0
  transition := fun _ a =>
    if a = 0 then Distribution.pure 1 else Distribution.pure 2
  stageReward := fun _ _ _ => 0
  terminalReward := fun s m =>
    if s = 1 then -m.prob 1 else if s = 2 then -2 * m.prob 2 else 0

/-- Every agent chooses Left with probability `2/3`. -/
def equilibriumActionDistribution : Distribution Action where
  prob := fun a => if a = 0 then 2 / 3 else 1 / 3
  nonneg := by intro a; fin_cases a <;> norm_num
  total := by norm_num [Fin.sum_univ_succ]

def equilibriumPolicy : Policy State Action :=
  fun _ => equilibriumActionDistribution

/-- Every agent chooses Left. -/
def allLeft : Policy State Action := fun _ => Distribution.pure 0

-- These guards evaluate the definitions and algorithm during compilation.
#guard (inducedTerminal game equilibriumPolicy).prob 1 == (2 / 3 : ℚ)
#guard (inducedTerminal game equilibriumPolicy).prob 2 == (1 / 3 : ℚ)
#guard bestAction game (inducedTerminal game equilibriumPolicy) 0 == (0 : Action)
#guard exploitability game equilibriumPolicy == (0 : ℚ)
#guard checkEpsilonEquilibrium game equilibriumPolicy 0
#guard bestAction game (inducedTerminal game allLeft) 0 == (1 : Action)
#guard exploitability game allLeft == (1 : ℚ)
#guard !checkEpsilonEquilibrium game allLeft 0
#guard !checkEpsilonEquilibrium game equilibriumPolicy (-1)

/-- The candidate policy induces the advertised population masses. -/
theorem equilibrium_mass_left :
    (inducedTerminal game equilibriumPolicy).prob 1 = 2 / 3 := by
  norm_num [inducedTerminal, update, Distribution.bind, game, equilibriumPolicy,
    equilibriumActionDistribution, Distribution.pure, Fin.sum_univ_succ]

theorem equilibrium_mass_right :
    (inducedTerminal game equilibriumPolicy).prob 2 = 1 / 3 := by
  norm_num [inducedTerminal, update, Distribution.bind, game, equilibriumPolicy,
    equilibriumActionDistribution, Distribution.pure, Fin.sum_univ_succ]

private theorem equilibrium_action_value (s : State) (a : Action) :
    actionValue game (inducedTerminal game equilibriumPolicy) s a = -(2 / 3 : ℚ) := by
  fin_cases a
  · simpa [actionValue, game, Distribution.expect, Fin.sum_univ_succ,
      Distribution.pure] using congrArg Neg.neg equilibrium_mass_left
  · have h := congrArg (fun q : ℚ => -2 * q) equilibrium_mass_right
    norm_num at h
    simpa [actionValue, game, Distribution.expect, Fin.sum_univ_succ,
      Distribution.pure] using h

private theorem equilibrium_value (π : Policy State Action) :
    value game π (inducedTerminal game equilibriumPolicy) = -(2 / 3 : ℚ) := by
  unfold value
  have hinner (s : State) :
      (π s).expect (actionValue game (inducedTerminal game equilibriumPolicy) s) =
        -(2 / 3 : ℚ) := by
    calc
      _ = (π s).expect (fun _ => -(2 / 3 : ℚ)) := by
        congr 1
        funext a
        exact equilibrium_action_value s a
      _ = -(2 / 3 : ℚ) := Distribution.expect_const (π s) _
  simp_rw [hinner]
  exact Distribution.expect_const game.initial _

/-- The executable zero-gap check certifies the Left/Right equilibrium. -/
theorem equilibriumPolicy_isEquilibrium : IsEquilibrium game equilibriumPolicy := by
  intro π'
  rw [equilibrium_value π', equilibrium_value equilibriumPolicy]

end LeanMFG.FiniteState.LeftRight
