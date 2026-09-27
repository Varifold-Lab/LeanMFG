import LeanMFG.Numerical.Binary64

/-! One forward population step. Sources are flattened state–action indices;
transition storage is destination × source, matching MFGLib. -/
namespace LeanMFG.Numerical.Population

open Binary64

/-- Stored inputs, without assuming exact probability normalization. -/
structure Input (destinations sources : Nat) where
  population : Fin sources → Value
  transition : Fin destinations → Fin sources → Value

def rowPairs {n k : Nat} (d : Input n k) (dst : Fin n) : List (Value × Value) :=
  List.ofFn fun src => (d.population src, d.transition dst src)

/-- Each destination uses separately rounded products and a left-to-right sum. -/
def update {n k : Nat} (d : Input n k) (dst : Fin n) : Value :=
  dot (rowPairs d dst)

def finite {n k : Nat} (d : Input n k) : Bool :=
  decide (∀ dst : Fin n, dotFinite (rowPairs d dst) = true)

def checkedUpdate {n k : Nat} (d : Input n k) : Option (Fin n → Value) :=
  if finite d then some (update d) else none

/-- The unchecked adapter is total; `checkedForward` rejects missing/extra entries. -/
def readInput (n k : Nat) (population transition : Array Float) : Input n k where
  population src := ofFloat (population.getD src.val 0)
  transition dst src := ofFloat (transition.getD (dst.val * k + src.val) 0)

def forward (n k : Nat) (population transition : Array Float) : Array Float :=
  Array.ofFn fun dst => toFloat (update (readInput n k population transition) dst)

def validShape (n k : Nat) (population transition : Array Float) : Bool :=
  decide (0 < n ∧ 0 < k ∧ population.size = k ∧ transition.size = n * k)

/-- Checks shape and finite arithmetic, not stochasticity or equilibrium. -/
def checkedForward (n k : Nat) (population transition : Array Float) : Option (Array Float) :=
  if validShape n k population transition && finite (readInput n k population transition) then
    some (forward n k population transition)
  else none

end LeanMFG.Numerical.Population
