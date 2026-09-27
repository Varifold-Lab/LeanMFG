import LeanMFG.Computational.Numeric

namespace LeanMFG.Computational

/-- Finite horizon, with rewards at times 0 through T, including the terminal time.
Callbacks take one joint state-action slice. Probability layout is destination × source × action.
Dual-valued callbacks allow MFOMO to differentiate through population-dependent dynamics. -/
structure Environment where
  name : String
  T : Nat
  S : Array Nat
  A : Array Nat
  mu0 : Vec
  rMax : Float
  rewardFn : Nat → Array Dual → Array Dual
  transitionFn : Nat → Array Dual → Array Dual
  inputError : Option String := none

namespace Environment
def nStates (e : Environment) : Nat := e.S.foldl (· * ·) 1
def nActions (e : Environment) : Nat := e.A.foldl (· * ·) 1
def sliceSize (e : Environment) : Nat := e.nStates * e.nActions
def policySize (e : Environment) : Nat := (e.T + 1) * e.sliceSize
def policyShape (e : Environment) : Array Nat := #[e.T + 1] ++ e.S ++ e.A
def reward (e : Environment) (t : Nat) (l : Vec) : Vec :=
  (e.rewardFn t (l.map Dual.const)).map (·.val)
def prob (e : Environment) (t : Nat) (l : Vec) : Vec :=
  (e.transitionFn t (l.map Dual.const)).map (·.val)

def validate (e : Environment) : Except String Unit := do
  if let some err := e.inputError then throw err
  if e.S.isEmpty || e.A.isEmpty || e.S.contains 0 || e.A.contains 0 then
    throw "state and action dimensions must be positive"
  if e.mu0.size != e.nStates || !allFinite e.mu0 || e.mu0.any (· < 0) ||
      (sum e.mu0 - 1).abs > 1e-6 then
    throw "invalid initial state distribution"
  if !e.rMax.isFinite || e.rMax < 0 then throw "invalid reward scale"

/-- Validate a callback's output at one supplied population (not a general proof). -/
def validateAt (e : Environment) (t : Nat) (l : Vec) (tol : Float := 1e-8) : Except String Unit := do
  e.validate
  if t > e.T || l.size != e.sliceSize || !allFinite l || l.any (· < 0) ||
      (sum l - 1).abs > tol then throw "invalid population slice"
  let r := e.reward t l
  if r.size != e.sliceSize || !allFinite r then throw "invalid reward callback output"
  if t == e.T then return
  let p := e.prob t l
  if p.size != e.nStates * e.sliceSize || !allFinite p || p.any (· < 0) then
    throw "invalid transition callback output"
  for i in [:e.sliceSize] do
    let mass := sum (tabulate e.nStates fun dst => p[dst * e.sliceSize + i]!)
    if (mass - 1).abs > tol then throw "transition column does not sum to one"
end Environment

def stateMarginal (nStates nActions : Nat) (l : Vec) : Vec :=
  tabulate nStates fun s => sum (slice l (s * nActions) nActions)

def stateMarginalD (nStates nActions : Nat) (l : Array Dual) : Array Dual :=
  tabulate nStates fun s => Dual.sum (slice l (s * nActions) nActions)

end LeanMFG.Computational
