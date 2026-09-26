import LeanMFG.Model.FiniteState.OneStep
import Mathlib.Data.Finset.Sort
import Mathlib.Data.List.MinMax

namespace LeanMFG.FiniteState

variable {State Action : Type*} [Fintype State] [Fintype Action]
  [LinearOrder Action] [Inhabited Action]

/-- A maximizing action against a fixed population distribution. The list
order resolves ties, with the default action first. -/
def bestAction (G : Game State Action) (m : Distribution State)
    (s : State) : Action :=
  ((default :: (Finset.univ : Finset Action).sort (· ≤ ·)).argmax
    (actionValue G m s)).getD default

/-- A deterministic maximizing policy for the representative player. -/
def bestResponse (G : Game State Action) (m : Distribution State) :
    Policy State Action :=
  fun s => Distribution.pure (bestAction G m s)

/-- Largest individual gain against the population induced by `π`. -/
def exploitability (G : Game State Action) (π : Policy State Action) : ℚ :=
  let m := inducedTerminal G π
  value G (bestResponse G m) m - value G π m

/-- Executable certificate for an approximate equilibrium. -/
def checkEpsilonEquilibrium (G : Game State Action)
    (π : Policy State Action) (ε : ℚ) : Bool :=
  decide (0 ≤ ε ∧ exploitability G π ≤ ε)

end LeanMFG.FiniteState
