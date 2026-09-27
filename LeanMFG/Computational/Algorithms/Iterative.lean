import LeanMFG.Computational.QFn

namespace LeanMFG.Computational
open scoped LeanMFG.Computational

structure SolveOptions where
  maxIter : Nat := 100
  atol : Option Float := some 1e-3
  rtol : Option Float := some 1e-3
  verbose : Bool := false
  printEvery : Nat := 50
  deriving Repr, Lean.ToJson, Lean.FromJson

structure SolveResult where
  policies : Array Policy
  exploitabilities : Vec
  runtimes : Vec
  stoppedEarly : Bool
  deriving Repr, Lean.ToJson, Lean.FromJson

def SolveResult.bestIndex (r : SolveResult) : Nat := Id.run do
  let mut best := 0
  for i in [:r.exploitabilities.size] do
    if r.exploitabilities[i]! < r.exploitabilities[best]! then best := i
  return best

def triggerEarlyStopping (initial current : Float) (o : SolveOptions) : Bool :=
  let a := o.atol.getD 0
  let r := o.rtol.getD 0
  (a != 0 || r != 0) && current ≤ a + r*initial

def checked (x : Except String α) : ExceptT String IO α := ExceptT.mk (pure x)

def runIterations {σ : Type} (e : Environment) (initial : σ) (policy : σ → Policy)
    (step : σ → Except String σ) (o : SolveOptions := {}) : ExceptT String IO SolveResult := do
  if o.atol.any (fun x => !x.isFinite || x < 0) || o.rtol.any (fun x => !x.isFinite || x < 0) then
    throw "stopping tolerances must be finite and nonnegative"
  checked (Policy.validate e (policy initial))
  let score ← checked (exploitabilityScore e (policy initial))
  let mut result : SolveResult := ⟨#[policy initial], #[score], #[0], false⟩
  let mut state := initial
  if triggerEarlyStopping score score o then return { result with stoppedEarly := true }
  let start ← IO.monoNanosNow
  for i in [:o.maxIter] do
    state ← checked (step state)
    checked (Policy.validate e (policy state))
    let scoreN ← checked (exploitabilityScore e (policy state))
    if !scoreN.isFinite then throw "non-finite exploitability"
    let now ← IO.monoNanosNow
    result := { result with
      policies := result.policies.push (policy state)
      exploitabilities := result.exploitabilities.push scoreN
      runtimes := result.runtimes.push ((now-start).toFloat / 1e9) }
    if o.verbose && (i+1) % (max 1 o.printEvery) == 0 then
      IO.eprintln s!"iteration={i+1} exploitability={scoreN} best={result.bestIndex}"
    if triggerEarlyStopping score scoreN o then return { result with stoppedEarly := true }
  return result

structure FictitiousPlay where
  alpha : Float := 0
  deriving Repr, Lean.ToJson, Lean.FromJson

namespace FictitiousPlay
structure State where
  pi : Policy
  iteration : Nat := 0

def step (cfg : FictitiousPlay) (e : Environment) (s : State) : Except String State := do
  if !cfg.alpha.isFinite || cfg.alpha < 0 || cfg.alpha > 1 then throw "alpha must be in [0,1]"
  let l ← meanFieldFromPolicy e s.pi
  let br ← greedyPolicyGivenMeanField e l
  let lbr ← meanFieldFromPolicy e br
  let alpha := if cfg.alpha == 0 then 1/(s.iteration+2).toFloat else cfg.alpha
  let mixed := l.zipWith (fun x y => (1-alpha)*x + alpha*y) lbr
  let pi ← policyFromMeanField e mixed
  return ⟨pi, s.iteration+1⟩

def solve (cfg : FictitiousPlay) (e : Environment) (pi0 : Option Policy := none)
    (options : SolveOptions := {}) : ExceptT String IO SolveResult := do
  if !cfg.alpha.isFinite || cfg.alpha < 0 || cfg.alpha > 1 then throw "alpha must be in [0,1]"
  runIterations e ⟨pi0.getD (Policy.uniform e), 0⟩ State.pi (cfg.step e) options
end FictitiousPlay

structure OnlineMirrorDescent where
  alpha : Float := 1
  deriving Repr, Lean.ToJson, Lean.FromJson

namespace OnlineMirrorDescent
structure State where
  pi : Policy
  y : Vec

def step (cfg : OnlineMirrorDescent) (e : Environment) (s : State) : Except String State := do
  let l ← meanFieldFromPolicy e s.pi
  let q ← QFn.forPolicy e l s.pi
  if s.y.size != e.policySize then throw "invalid mirror descent accumulator shape"
  let y := s.y.zipWith (fun x q => x + cfg.alpha*q) q
  let mut pi := #[]
  for row in [:(e.T+1)*e.nStates] do
    pi := pi ++ softmax (slice y (row*e.nActions) e.nActions)
  return ⟨pi, y⟩

def solve (cfg : OnlineMirrorDescent) (e : Environment) (pi0 : Option Policy := none)
    (options : SolveOptions := {}) : ExceptT String IO SolveResult := do
  if !cfg.alpha.isFinite || cfg.alpha ≤ 0 then throw "alpha must be positive"
  runIterations e ⟨pi0.getD (Policy.uniform e), Array.replicate e.policySize 0⟩
    State.pi (cfg.step e) options
end OnlineMirrorDescent

structure PriorDescent where
  eta : Float := 1
  nInner : Option Nat := none
  deriving Repr, Lean.ToJson, Lean.FromJson

namespace PriorDescent
structure State where
  pi : Policy
  prior : Policy
  iteration : Nat := 0

def step (cfg : PriorDescent) (e : Environment) (s : State) : Except String State := do
  if !cfg.eta.isFinite || cfg.eta ≤ 0 || cfg.nInner == some 0 then throw "invalid prior descent parameters"
  Policy.validate e s.prior
  let l ← meanFieldFromPolicy e s.pi
  let q ← QFn.optimal e l
  let mut pi := #[]
  for row in [:(e.T+1)*e.nStates] do
    let prior := slice s.prior (row*e.nActions) e.nActions
    let qs := (slice q (row*e.nActions) e.nActions).map (· / cfg.eta)
    -- The maximum is taken over the prior support to avoid zero-times-infinity.
    let shift := maxEntry (tabulate e.nActions fun a => if prior[a]! > 0 then qs[a]! else -1/0)
    pi := pi ++ normalize (tabulate e.nActions fun a =>
      if prior[a]! == 0 then 0 else prior[a]! * (qs[a]!-shift).exp)
  let update := cfg.nInner.any fun n => (s.iteration+2) % n == 0
  return ⟨pi, if update then pi else s.prior, s.iteration+1⟩

def solve (cfg : PriorDescent) (e : Environment) (pi0 : Option Policy := none)
    (options : SolveOptions := {}) : ExceptT String IO SolveResult := do
  if !cfg.eta.isFinite || cfg.eta ≤ 0 || cfg.nInner == some 0 then throw "invalid prior descent parameters"
  let p := pi0.getD (Policy.uniform e)
  runIterations e ⟨p, p, 0⟩ State.pi (cfg.step e) options
end PriorDescent

end LeanMFG.Computational
