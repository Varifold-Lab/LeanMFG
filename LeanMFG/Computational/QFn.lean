import LeanMFG.Computational.Policy

namespace LeanMFG.Computational

/-- Backward Bellman recursion. None maximizes; some pi evaluates a fixed policy.
The mean field remains fixed while evaluating any deviating policy. -/
def qFunction (e : Environment) (l : MeanField) (pi : Option Policy := none) : Except String Vec := do
  validateMeanField e l
  if let some p := pi then Policy.validate e p
  let mut future := Array.replicate e.nStates 0.0
  let mut out := Array.replicate e.policySize 0.0
  for k in [:e.T + 1] do
    let t := e.T - k
    let lt := slice l (t * e.sliceSize) e.sliceSize
    let r := e.reward t lt
    let p := if t == e.T then #[] else e.prob t lt
    let q := tabulate e.sliceSize fun i =>
      r[i]! + if t == e.T then 0 else
        sum (tabulate e.nStates fun dst => p[dst * e.sliceSize + i]! * future[dst]!)
    for i in [:e.sliceSize] do out := out.set! (t * e.sliceSize + i) q[i]!
    future := tabulate e.nStates fun s =>
      let row := slice q (s * e.nActions) e.nActions
      match pi with
      | none => maxEntry row
      | some policy => dot row (slice policy (t * e.sliceSize + s * e.nActions) e.nActions)
  return out

namespace QFn
def optimal (e : Environment) (l : MeanField) : Except String Vec := qFunction e l
def forPolicy (e : Environment) (l : MeanField) (pi : Policy) : Except String Vec :=
  qFunction e l (some pi)
end QFn

/-- Match MFGLib: split probability equally among all maximizing actions. -/
def greedyPolicyGivenMeanField (e : Environment) (l : MeanField) : Except String Policy := do
  let q ← QFn.optimal e l
  let mut out := #[]
  for row in [:(e.T + 1) * e.nStates] do
    let qs := slice q (row * e.nActions) e.nActions
    let m := maxEntry qs
    out := out ++ normalize (qs.map fun x => if x == m then 1 else 0)
  return out

def exploitabilityScore (e : Environment) (pi : Policy) (postprocess : Bool := true)
    (precision : Option Float := none) : Except String Float := do
  let pi ← if postprocess then Policy.postprocess e pi else Policy.build e pi
  let l ← meanFieldFromPolicy e pi
  let qo ← QFn.optimal e l
  let qp ← QFn.forPolicy e l pi
  let score := sum (tabulate e.nStates fun s =>
    e.mu0[s]! * (maxEntry (slice qo (s * e.nActions) e.nActions) -
      dot (slice pi (s * e.nActions) e.nActions) (slice qp (s * e.nActions) e.nActions)))
  return match precision with
    | some tol => if score < 0 && score.abs ≤ tol then 0 else score
    | none => score

def exploitabilityScores (e : Environment) (pis : Array Policy) : Except String Vec :=
  pis.mapM (exploitabilityScore e ·)

end LeanMFG.Computational
