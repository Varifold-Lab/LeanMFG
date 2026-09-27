import LeanMFG.Computational.Algorithms.OccupationMeasure

namespace LeanMFG.Computational
open scoped LeanMFG.Computational
open LeanMFG.Computational.Dual (const)

inductive OMOLoss where
  | l1 | l2 | l1L2
  deriving BEq, Repr, Lean.ToJson, Lean.FromJson

inductive OptimizerKind where
  | adam | sgd
  deriving BEq, Repr, Lean.ToJson, Lean.FromJson

structure OptimizerConfig where
  kind : OptimizerKind := .adam
  lr : Float := 0.1
  beta1 : Float := 0.9
  beta2 : Float := 0.999
  eps : Float := 1e-8
  weightDecay : Float := 0
  momentum : Float := 0
  dampening : Float := 0
  nesterov : Bool := false
  deriving Repr, Lean.ToJson, Lean.FromJson

structure MFOMO where
  loss : OMOLoss := .l1L2
  c1 : Float := 1
  c2 : Float := 1
  c3 : Float := 1
  rbFreq : Option Nat := none
  m1 : Float := 10
  m2 : Float := 2
  m3 : Float := 0.1
  optimizer : OptimizerConfig := {}
  parameterize : Bool := false
  hatInit : Bool := true
  L : Option Vec := none
  z : Option Vec := none
  y : Option Vec := none
  u : Option Vec := none
  v : Option Vec := none
  w : Option Vec := none
  deriving Repr, Lean.ToJson, Lean.FromJson

def omoZRadius (e : Environment) : Float :=
  (e.nStates*e.nActions*(e.T*e.T+e.T+2)).toFloat * e.rMax
def omoYRadius (e : Environment) : Float :=
  (e.nStates*(e.T+1)*(e.T+2)).toFloat * e.rMax / 2
def omoWScale (e : Environment) : Float := omoYRadius e / ((e.T+1)*e.nStates).toFloat.sqrt

structure OMOVariables where
  l : Vec
  z : Vec
  y : Vec
  deriving Repr, Lean.ToJson, Lean.FromJson

def OMOVariables.flatten (v : OMOVariables) : Vec := v.l ++ v.z ++ v.y

def omoDecodeD (e : Environment) (parameterize : Bool) (x : Array Dual) :
    Array Dual × Array Dual × Array Dual := Id.run do
  let n := e.policySize
  let m := (e.T+1)*e.nStates
  let mut l := slice x 0 n
  let mut z := slice x n (n + if parameterize then 1 else 0)
  let mut y := slice x (n+z.size) m
  if parameterize then
    let mut out := #[]
    for t in [:e.T+1] do out := out ++ Dual.softmax (slice l (t*e.sliceSize) e.sliceSize)
    l := out
    z := ((Dual.softmax z).extract 0 n).map (const (omoZRadius e) * ·)
    y := y.map fun v => const (omoWScale e) * v.sin
  return (l,z,y)

def omoDecode (e : Environment) (parameterize : Bool) (x : Vec) : OMOVariables :=
  let (l,z,y) := omoDecodeD e parameterize (x.map const)
  ⟨l.map (·.val), z.map (·.val), y.map (·.val)⟩

/-- Differentiable residuals, using exactly the callbacks used by forward simulation.
The matrix-free formula equals `(A_L L-b, A_Lᵀ y+z-c_L, z·L)`. -/
def omoTermsD (e : Environment) (parameterize : Bool) (loss : OMOLoss) (x : Array Dual) :
    Array Dual := Id.run do
  let (l,z,y) := omoDecodeD e parameterize x
  let mut flow := #[]
  let mut dual := #[]
  for t in [:e.T+1] do
    let lt := slice l (t*e.sliceSize) e.sliceSize
    let p := if t == e.T then #[] else e.transitionFn t lt
    let r := e.rewardFn t lt
    if t < e.T then
      let nextMu := stateMarginalD e.nStates e.nActions (slice l ((t+1)*e.sliceSize) e.sliceSize)
      flow := flow ++ tabulate e.nStates (fun dst =>
        Dual.sum (tabulate e.sliceSize fun i => p[dst*e.sliceSize+i]! * lt[i]!) - nextMu[dst]!)
    dual := dual ++ tabulate e.sliceSize (fun i =>
      let state := i/e.nActions
      let current := if t == 0 then y[e.T*e.nStates+state]! else -y[(t-1)*e.nStates+state]!
      let future := if t == e.T then 0 else
        Dual.sum (tabulate e.nStates fun dst => p[dst*e.sliceSize+i]! * y[t*e.nStates+dst]!)
      current + future + z[t*e.sliceSize+i]! + r[i]!)
  flow := flow ++ ((stateMarginalD e.nStates e.nActions (slice l 0 e.sliceSize)).zipWith
    (fun a b => a-const b) e.mu0)
  let residual := fun v : Array Dual =>
    Dual.sum (v.map fun a => if loss == .l1 then a.abs else a*a)
  let comp := Dual.sum (l.zipWith (· * ·) z)
  return #[residual flow, residual dual, if loss == .l2 then comp*comp else comp]

def mfOMOObjective (cfg : MFOMO) (e : Environment) (x : Vec) : Float :=
  let terms := omoTermsD e cfg.parameterize cfg.loss (x.map const)
  cfg.c1*terms[0]!.val + cfg.c2*terms[1]!.val + cfg.c3*terms[2]!.val

/-- Forward automatic differentiation, one basis seed per variable. This trades
speed for a small native Lean implementation and includes derivatives of P and r. -/
def mfOMOGradient (cfg : MFOMO) (e : Environment) (x : Vec) : Vec :=
  tabulate x.size fun seed =>
    let input := tabulate x.size fun i => Dual.mk x[i]! (if i == seed then 1 else 0)
    let terms := omoTermsD e cfg.parameterize cfg.loss input
    cfg.c1*terms[0]!.tangent + cfg.c2*terms[1]!.tangent + cfg.c3*terms[2]!.tangent

def mfOMOConstraints (e : Environment) (x : Vec) : Except String Vec := do
  let vars := omoDecode e false x
  let mut l := #[]
  for t in [:e.T+1] do l := l ++ (← projectSimplex (slice vars.l (t*e.sliceSize) e.sliceSize))
  let mut z := vars.z.map (max 0)
  if sum z > omoZRadius e then z ← projectSimplex z (omoZRadius e)
  let y := if norm vars.y > omoYRadius e then vars.y.map (· * (omoYRadius e / norm vars.y)) else vars.y
  return l ++ z ++ y

/-- Match the pinned upstream hat initialization, including its augmented-z convention. -/
def hatInitialization (e : Environment) (l : MeanField) (parameterize : Bool := false)
    (zEps : Float := 1e-8) : Except String (Option Vec × Vec) := do
  let q ← QFn.optimal e l
  let values := tabulate ((e.T+1)*e.nStates) fun row => maxEntry (slice q (row*e.nActions) e.nActions)
  let y := slice values e.nStates (e.T*e.nStates) ++ (slice values 0 e.nStates).map (-·)
  let mut z := #[]
  for t in [:e.T+1] do
    let lt := slice l (t*e.sliceSize) e.sliceSize
    let r := e.reward t lt
    let p := if t == e.T then #[] else e.prob t lt
    z := z ++ tabulate e.sliceSize (fun i =>
      let future := if t == e.T then 0 else sum (tabulate e.nStates fun dst =>
        p[dst*e.sliceSize+i]! * values[(t+1)*e.nStates+dst]!)
      max 0 (values[t*e.nStates+i/e.nActions]! - r[i]! - future))
  if !parameterize then return (some z, y)
  if omoZRadius e ≤ 0 || omoWScale e ≤ 0 then throw "parameterized hat initialization needs positive reward scale"
  let zs := z.map (· / omoZRadius e)
  let v := if sum zs < 1 then
      some ((zs.push (sum zs)).map fun a => (if a == 0 then zEps else a).log)
    else none
  return (v, y.map fun a => (a / omoWScale e).asin)

def mfOMOResidualBalancing (cfg : MFOMO) (e : Environment) (x : Vec)
    (safeguard : Float := 1e3) : Float × Float := Id.run do
  let ts := (omoTermsD e cfg.parameterize cfg.loss (x.map const)).map (·.val)
  let o1 := ts[0]!; let o2 := ts[1]!; let o3 := ts[2]!
  let mut c1 := cfg.c1
  let mut c2 := cfg.c2
  if max o2 o3 != 0 && o1 / max o2 o3 > cfg.m1 then c1 := cfg.c1*cfg.m2
  if min o2 o3 != 0 && o1 / min o2 o3 < cfg.m3 then c1 := cfg.c1/cfg.m2
  if max o1 o3 != 0 && o2 / max o1 o3 > cfg.m1 then c2 := cfg.c2*cfg.m2
  if min o1 o3 != 0 && o2 / min o1 o3 < cfg.m3 then c2 := cfg.c2/cfg.m2
  return (min c1 safeguard, min c2 safeguard)

namespace MFOMO
structure State where
  pi : Policy
  x : Vec
  firstMoment : Vec
  secondMoment : Vec
  c1 : Float
  c2 : Float
  iteration : Nat := 0

def validate (cfg : MFOMO) : Except String Unit := do
  let o := cfg.optimizer
  if cfg.rbFreq == some 0 || cfg.m2 ≤ 0 ||
      !allFinite #[cfg.c1,cfg.c2,cfg.c3,cfg.m1,cfg.m2,cfg.m3] then throw "invalid MFOMO coefficients"
  if cfg.parameterize then
    if cfg.L.isSome || cfg.z.isSome || cfg.y.isSome then throw "parameterized MFOMO accepts u,v,w"
  else
    if cfg.u.isSome || cfg.v.isSome || cfg.w.isSome then throw "projected MFOMO accepts L,z,y"
  if !allFinite #[o.lr,o.beta1,o.beta2,o.eps,o.weightDecay,o.momentum,o.dampening] ||
      o.lr ≤ 0 || o.eps ≤ 0 || o.beta1 < 0 || o.beta1 ≥ 1 || o.beta2 < 0 || o.beta2 ≥ 1 ||
      o.weightDecay < 0 || o.momentum < 0 || o.dampening < 0 then throw "invalid optimizer configuration"
  if o.nesterov && (o.momentum ≤ 0 || o.dampening != 0) then throw "invalid Nesterov parameters"

def init (cfg : MFOMO) (e : Environment) (pi : Policy) : Except String State := do
  cfg.validate
  Policy.validate e pi
  let n := e.policySize
  let m := (e.T+1)*e.nStates
  let base := cfg.L.getD (pi.map (· / e.nStates.toFloat))
  let lu ← if cfg.parameterize then do
    match cfg.u with
    | some u => pure u
    | none =>
      if base.any (· ≤ 0) then throw "zero probability cannot initialize log parameterization"
      pure (base.map Float.log)
    else pure base
  if lu.size != n || !allFinite lu then throw "invalid L/u initialization"
  let mut hatZ : Option Vec := none
  let mut hatY := Array.replicate m 0.0
  if cfg.hatInit then
    let hatL := if cfg.parameterize && cfg.u.isSome then
      (omoDecode e true (lu ++ Array.replicate (n+1+m) 0)).l else base
    let (hz, hy) ← hatInitialization e hatL cfg.parameterize
    hatZ := hz
    hatY := hy
  let nz := n + if cfg.parameterize then 1 else 0
  let zv := (if cfg.parameterize then cfg.v else cfg.z).getD (hatZ.getD (Array.replicate nz 0))
  let yw := (if cfg.parameterize then cfg.w else cfg.y).getD hatY
  if zv.size != nz || yw.size != m || !allFinite zv || !allFinite yw then throw "invalid z/v or y/w initialization"
  let x := lu ++ zv ++ yw
  let pi ← policyFromMeanField e (omoDecode e cfg.parameterize x).l
  return ⟨pi, x, Array.replicate x.size 0, Array.replicate x.size 0, cfg.c1, cfg.c2, 0⟩

def step (cfg : MFOMO) (e : Environment) (s : State) : Except String State := do
  let mut cfg := { cfg with c1 := s.c1, c2 := s.c2 }
  if cfg.rbFreq.any (fun n => (s.iteration+2)%n == 0) then
    let (c1,c2) := mfOMOResidualBalancing cfg e s.x
    cfg := { cfg with c1 := c1, c2 := c2 }
  let gradient := mfOMOGradient cfg e s.x
  if !allFinite gradient then throw "non-finite MFOMO gradient"
  let o := cfg.optimizer
  let g := gradient.zipWith (fun g x => g+o.weightDecay*x) s.x
  let first := if o.kind == .adam then s.firstMoment.zipWith (fun m g => o.beta1*m+(1-o.beta1)*g) g
    else if s.iteration == 0 then g else s.firstMoment.zipWith (fun m g => o.momentum*m+(1-o.dampening)*g) g
  let second := s.secondMoment.zipWith (fun v g => o.beta2*v+(1-o.beta2)*g*g) g
  let dir := if o.kind == .adam then tabulate s.x.size (fun i =>
      (first[i]! / (1-o.beta1.pow (s.iteration+1).toFloat)) /
        ((second[i]! / (1-o.beta2.pow (s.iteration+1).toFloat)).sqrt+o.eps))
    else if o.momentum == 0 then g
    else if o.nesterov then g.zipWith (fun g m => g+o.momentum*m) first else first
  let x := s.x.zipWith (fun x d => x-o.lr*d) dir
  let x ← if cfg.parameterize then pure x else mfOMOConstraints e x
  if !allFinite x then throw "non-finite MFOMO iterate"
  let pi ← policyFromMeanField e (omoDecode e cfg.parameterize x).l
  return ⟨pi,x,first,second,cfg.c1,cfg.c2,s.iteration+1⟩

def solve (cfg : MFOMO) (e : Environment) (pi0 : Option Policy := none)
    (options : SolveOptions := {}) : ExceptT String IO SolveResult := do
  let initial ← checked (cfg.init e (pi0.getD (Policy.uniform e)))
  runIterations e initial State.pi (cfg.step e) options
end MFOMO

end LeanMFG.Computational
