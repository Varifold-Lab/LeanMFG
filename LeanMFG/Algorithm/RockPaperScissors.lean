import LeanMFG.Model.RockPaperScissors

namespace LeanMFG.RPS

/-- A maximizing pure action; ties are resolved Rock, then Paper, then Scissors. -/
def bestResponse (m : Distribution) : Action :=
  if reward .Paper m > reward .Rock m then
    if reward .Scissors m > reward .Paper m then .Scissors else .Paper
  else
    if reward .Scissors m > reward .Rock m then .Scissors else .Rock

/-- Maximum individual improvement when the population remains at `m`. -/
def exploitability (m : Distribution) : ℚ :=
  reward (bestResponse m) m - expectedReward m m

/-- Executable approximate-equilibrium certificate. -/
def checkEpsilonEquilibrium (m : Distribution) (ε : ℚ) : Bool :=
  decide (0 ≤ ε ∧ exploitability m ≤ ε)

end LeanMFG.RPS
