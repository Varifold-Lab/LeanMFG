import LeanMFG.Computational.Algorithms.Iterative

namespace LeanMFG.Computational
open scoped LeanMFG.Computational

structure OMOParams where
  b : Vec
  A : Vec
  c : Vec
  rows : Nat
  cols : Nat
  deriving Repr, Lean.ToJson, Lean.FromJson

/-- MFGLib's flow matrix, with the initial-distribution rows at the end. -/
def mfOMOParams (e : Environment) (l : MeanField) : Except String OMOParams := do
  if l.size != e.policySize then throw "invalid occupation measure shape"
  let n := e.policySize
  let m := (e.T+1)*e.nStates
  let mut a := Array.replicate (m*n) 0.0
  let mut c := #[]
  for t in [:e.T+1] do
    let lt := slice l (t*e.sliceSize) e.sliceSize
    c := c ++ (e.reward t lt).map (-·)
    if t < e.T then
      let p := e.prob t lt
      for dst in [:e.nStates] do
        let row := t*e.nStates+dst
        for i in [:e.sliceSize] do
          a := a.set! (row*n+t*e.sliceSize+i) p[dst*e.sliceSize+i]!
        for action in [:e.nActions] do
          a := a.set! (row*n+(t+1)*e.sliceSize+dst*e.nActions+action) (-1)
  for s in [:e.nStates] do
    for action in [:e.nActions] do
      a := a.set! ((e.T*e.nStates+s)*n+s*e.nActions+action) 1
  return ⟨Array.replicate (e.T*e.nStates) 0 ++ e.mu0, a, c, m, n⟩

def matVec (a : Vec) (rows cols : Nat) (x : Vec) : Vec :=
  tabulate rows fun r => dot (slice a (r*cols) cols) x

def transposeMatVec (a : Vec) (rows cols : Nat) (x : Vec) : Vec :=
  tabulate cols fun c => sum (tabulate rows fun r => a[r*cols+c]! * x[r]!)

/-- Dense Cholesky factorization. Used by the native equality projection. -/
def cholesky (a : Vec) (n : Nat) : Except String Vec := do
  let mut l := Array.replicate (n*n) 0.0
  for i in [:n] do
    for j in [:i+1] do
      let v := a[i*n+j]! - sum (tabulate j fun k => l[i*n+k]! * l[j*n+k]!)
      if i == j then
        if v ≤ 0 || !v.isFinite then throw "projection constraint matrix is singular"
        l := l.set! (i*n+j) v.sqrt
      else l := l.set! (i*n+j) (v/l[j*n+j]!)
  return l

def choleskySolve (l : Vec) (n : Nat) (b : Vec) : Vec := Id.run do
  let mut x := b
  for i in [:n] do
    let v := b[i]! - sum (tabulate i fun j => l[i*n+j]! * x[j]!)
    x := x.set! i (v/l[i*n+i]!)
  for k in [:n] do
    let i := n-1-k
    let v := x[i]! - sum (tabulate (n-1-i) fun k =>
      let j := i+1+k
      l[j*n+i]! * x[j]!)
    x := x.set! i (v/l[i*n+i]!)
  return x

structure ProjectionOptions where
  atol : Float := 1e-8
  rtol : Float := 1e-8
  maxIter : Nat := 20000
  deriving Repr, Lean.ToJson, Lean.FromJson

structure ProjectionResult where
  x : Vec
  affineCorrection : Vec
  coneCorrection : Vec
  iterations : Nat
  residual : Float
  deriving Repr, Lean.ToJson, Lean.FromJson

/-- Native Dykstra projection onto {x | Ax=b, x≥0}. Same quadratic program as
MFGLib's OSQP call, with a different numerical backend. Failure to meet the
feasibility and complementary-slackness tolerances is returned as an error. -/
def projectOccupation (d : Vec) (p : OMOParams) (o : ProjectionOptions := {})
    (warm : Option ProjectionResult := none) : Except String ProjectionResult := do
  if d.size != p.cols || p.A.size != p.rows*p.cols || p.b.size != p.rows ||
      !allFinite d || !allFinite p.A || !allFinite p.b then throw "invalid projection data"
  if o.atol < 0 || o.rtol < 0 || !o.atol.isFinite || !o.rtol.isFinite || o.maxIter == 0 then
    throw "invalid projection tolerances or iteration limit"
  let gram := tabulate (p.rows*p.rows) fun i =>
    dot (slice p.A (i/p.rows*p.cols) p.cols) (slice p.A (i%p.rows*p.cols) p.cols)
  let chol ← cholesky gram p.rows
  let correction := fun x : Vec => transposeMatVec p.A p.rows p.cols
    (choleskySolve chol p.rows ((matVec p.A p.rows p.cols x).zipWith (· - ·) p.b))
  let mut pc := Array.replicate p.cols 0.0
  let mut qc := Array.replicate p.cols 0.0
  if let some w := warm then
    if w.affineCorrection.size == p.cols && w.coneCorrection.size == p.cols then
      -- Reproject the affine dual when a population-dependent A has changed.
      pc := transposeMatVec p.A p.rows p.cols (choleskySolve chol p.rows
        (matVec p.A p.rows p.cols w.affineCorrection))
      qc := w.coneCorrection.map (min 0)
  let mut x := (d.zipWith (· - ·) pc).zipWith (· - ·) qc
  let tol := o.atol + o.rtol * max 1 (max (norm d) (norm p.b))
  for iter in [:o.maxIter] do
    let xp := x.zipWith (· + ·) pc
    pc := correction xp
    let y := xp.zipWith (· - ·) pc
    let yq := y.zipWith (· + ·) qc
    let newX := yq.map (max 0)
    qc := yq.zipWith (· - ·) newX
    let change := norm (newX.zipWith (· - ·) x)
    x := newX
    let feasibility := norm ((matVec p.A p.rows p.cols x).zipWith (· - ·) p.b)
    let complementarity := (dot x qc).abs
    if change ≤ tol && feasibility ≤ tol && complementarity ≤ tol then
      return ⟨x, pc, qc, iter+1, max feasibility complementarity⟩
  throw "occupation projection did not reach its tolerance; increase projection.maxIter"

structure OccupationMeasureInclusion where
  alpha : Float := 1e-3
  eta : Float := 0
  projection : ProjectionOptions := {}
  warmStart : Bool := true
  deriving Repr, Lean.ToJson, Lean.FromJson

namespace OccupationMeasureInclusion
structure State where
  pi : Policy
  d : MeanField
  projection : Option ProjectionResult := none

def step (cfg : OccupationMeasureInclusion) (e : Environment) (s : State) : Except String State := do
  let params ← mfOMOParams e s.d
  let d := s.d.zipWith (fun d c => d-cfg.alpha*(c+cfg.eta*d)) params.c
  let proj ← projectOccupation d params cfg.projection (if cfg.warmStart then s.projection else none)
  let pi ← policyFromMeanField e proj.x ((cfg.projection.atol+cfg.projection.rtol)*5)
  return ⟨pi, proj.x, if cfg.warmStart then some proj else none⟩

def solve (cfg : OccupationMeasureInclusion) (e : Environment) (pi0 : Option Policy := none)
    (options : SolveOptions := {}) : ExceptT String IO SolveResult := do
  if !cfg.alpha.isFinite || cfg.alpha ≤ 0 || !cfg.eta.isFinite || cfg.eta < 0 then
    throw "invalid occupation measure inclusion parameters"
  let pi := pi0.getD (Policy.uniform e)
  let d ← checked (meanFieldFromPolicy e pi)
  runIterations e ⟨pi, d, none⟩ State.pi (cfg.step e) options
end OccupationMeasureInclusion

end LeanMFG.Computational
