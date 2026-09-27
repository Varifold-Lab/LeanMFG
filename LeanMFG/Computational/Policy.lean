import LeanMFG.Computational.Environment
import LeanMFG.Numerical.Population

namespace LeanMFG.Computational

abbrev Policy := Vec
abbrev MeanField := Vec

namespace Policy
def uniform (e : Environment) : Policy := Array.replicate e.policySize (1 / e.nActions.toFloat)

def validate (e : Environment) (pi : Policy) (tol : Float := 1e-8) : Except String Unit := do
  e.validate
  if pi.size != e.policySize || !allFinite pi || pi.any (· < 0) then
    throw "invalid policy shape or probabilities"
  for row in [:(e.T + 1) * e.nStates] do
    if (sum (slice pi (row * e.nActions) e.nActions) - 1).abs > tol then
      throw "policy action probabilities do not sum to one"

def build (e : Environment) (pi : Vec) : Except String Policy := do
  validate e pi
  return pi

def stationary (e : Environment) (row : Vec) : Except String Policy := do
  if row.size != e.sliceSize then throw "invalid stationary policy shape"
  build e (tabulate e.policySize fun i => row[i % e.sliceSize]!)

def postprocess (e : Environment) (pi : Vec) : Except String Policy := do
  if pi.size != e.policySize || !allFinite pi then throw "invalid policy input"
  let mut out := #[]
  for row in [:(e.T + 1) * e.nStates] do
    out := out ++ normalize ((slice pi (row * e.nActions) e.nActions).map (max 0))
  return out
end Policy

def meanFieldFromPolicy (e : Environment) (pi : Policy) : Except String MeanField := do
  Policy.validate e pi
  let mut mu := e.mu0
  let mut out := #[]
  for t in [:e.T + 1] do
    let l := tabulate e.sliceSize fun i => mu[i / e.nActions]! * pi[t * e.sliceSize + i]!
    e.validateAt t l
    out := out ++ l
    if t < e.T then
      let p := e.prob t l
      let some next := Numerical.Population.checkedForward e.nStates e.sliceSize l p
        | throw "invalid shape or nonfinite arithmetic in population update"
      mu := next
  return out

def policyFromMeanField (e : Environment) (l : MeanField) (tol : Float := 0) : Except String Policy := do
  if l.size != e.policySize || !allFinite l || tol < 0 then throw "invalid mean field input"
  let clean := l.map fun x => if x.abs ≤ tol then 0 else x
  if clean.any (· < 0) then throw "negative mean field after tolerance cleanup"
  let mut out := #[]
  for row in [:(e.T + 1) * e.nStates] do
    out := out ++ normalize (slice clean (row * e.nActions) e.nActions)
  return out

def validateMeanField (e : Environment) (l : MeanField) : Except String Unit := do
  e.validate
  if l.size != e.policySize then throw "invalid mean field shape"
  for t in [:e.T + 1] do e.validateAt t (slice l (t * e.sliceSize) e.sliceSize) 1e-2

end LeanMFG.Computational
