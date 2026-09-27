import LeanMFG.Computational.Environment
import LeanMFG.Computational.Random

/-! Ports of all ten environments in MFGLib 0.3.0. The formulas follow the
implementation, including clamped (not periodic) beach/crowd transitions. -/
namespace LeanMFG.Computational.Environments
open scoped LeanMFG.Computational
open LeanMFG.Computational.Dual (const)

private def initial (n : Nat) (mu : Option Vec) : Vec := mu.getD (uniformVec n)
private def invalid (condition : Bool) (message : String) : Option String :=
  if condition then some message else none
private def deterministic (ns na : Nat) (next : Nat → Nat → Nat) : Array Dual :=
  tabulate (ns * ns * na) fun i =>
    if i / (ns * na) == next (i / na % ns) (i % na) then 1 else 0

def leftRight (mu0 : Vec := #[1, 0, 0]) : Environment where
  name := "left_right"
  T := 1; S := #[3]; A := #[2]; mu0 := mu0; rMax := 2
  rewardFn := fun _ l =>
    let mu := stateMarginalD 3 2 l
    tabulate 6 fun i => if i / 2 == 1 then -mu[1]! else if i / 2 == 2 then const (-2) * mu[2]! else 0
  transitionFn := fun _ _ => deterministic 3 2 (fun _ a => a + 1)

/-- The weighted, non-zero-sum upstream game. Distinct from LeanMFG.RPS. -/
def rockPaperScissors (T : Nat := 1) (mu0 : Vec := #[1, 0, 0, 0]) : Environment where
  name := "rock_paper_scissors"
  T := T; S := #[4]; A := #[3]; mu0 := mu0; rMax := 6
  rewardFn := fun _ l =>
    let mu := stateMarginalD 4 3 l
    tabulate 12 fun i => match i / 3 with
      | 1 => const 2 * mu[3]! - mu[2]!
      | 2 => const 4 * mu[1]! - const 2 * mu[3]!
      | 3 => const 6 * mu[2]! - const 3 * mu[1]!
      | _ => 0
  transitionFn := fun _ _ => deterministic 4 3 (fun _ a => a + 1)

def susceptibleInfected (T : Nat := 50) (mu0 : Vec := #[0.4, 0.6]) : Environment where
  name := "susceptible_infected"
  T := T; S := #[2]; A := #[2]; mu0 := mu0; rMax := 1.5
  rewardFn := fun _ _ => #[0, const (-0.5), -1, const (-1.5)]
  transitionFn := fun _ l =>
    let infected := const 0.81 * (stateMarginalD 2 2 l)[1]!
    #[1-infected, 1, const 0.3, const 0.3, infected, 0, const 0.7, const 0.7]

structure BeachBarConfig where
  T : Nat := 2
  n : Nat := 4
  barLoc : Nat := 2
  logEps : Float := 1e-20
  pStill : Float := 0.5
  mu0 : Option Vec := none
  deriving Repr, Lean.ToJson, Lean.FromJson

def beachBar (c : BeachBarConfig := {}) : Environment where
  name := "beach_bar"
  T := c.T; S := #[c.n]; A := #[3]; mu0 := initial c.n c.mu0; rMax := c.n.toFloat
  inputError := invalid (c.barLoc ≥ c.n || c.logEps ≤ 0 || c.pStill < 0 || c.pStill > 1 ||
    !allFinite #[c.logEps,c.pStill]) "invalid beach bar parameters"
  rewardFn := fun _ l =>
    let mu := stateMarginalD c.n 3 l
    tabulate (c.n * 3) fun i =>
      let s := i / 3
      let distance := min ((s + c.n - c.barLoc) % c.n) ((c.barLoc + c.n - s) % c.n);
      -const distance.toFloat - const (if i % 3 == 1 then 0 else 1 / c.n.toFloat) -
        (mu[s]! + const c.logEps).log
  transitionFn := fun _ _ =>
    tabulate (c.n * c.n * 3) fun i =>
      let dst := i / (c.n * 3)
      let s := i / 3 % c.n
      let a := i % 3
      Dual.sum (tabulate 3 fun noise =>
        if dst == clampIndex (Int.ofNat s + Int.ofNat a + Int.ofNat noise - 2) c.n
        then const (if noise == 1 then c.pStill else (1-c.pStill)/2) else 0)

structure BuildingEvacuationConfig where
  T : Nat := 3
  nFloor : Nat := 5
  floorL : Nat := 10
  floorW : Nat := 10
  logEps : Float := 1e-20
  eta : Float := 1
  evacR : Float := 10
  mu0 : Option Vec := none
  deriving Repr, Lean.ToJson, Lean.FromJson

def buildingEvacuation (c : BuildingEvacuationConfig := {}) : Environment :=
  let n := c.nFloor * c.floorL * c.floorW
  { name := "building_evacuation", T := c.T, S := #[c.nFloor, c.floorL, c.floorW], A := #[6]
    mu0 := initial n c.mu0, rMax := -c.eta * c.logEps.log + c.evacR
    inputError := invalid (c.logEps ≤ 0 || !allFinite #[c.logEps,c.eta,c.evacR]) "invalid building parameters"
    rewardFn := fun _ l =>
      let mu := stateMarginalD n 6 l
      tabulate (n * 6) fun i =>
        -const c.eta * (mu[i/6]!.clampMin c.logEps).log +
          const (if i/6 < c.floorL*c.floorW then c.evacR else 0)
    transitionFn := fun _ _ => deterministic n 6 fun s a =>
      let f := s / (c.floorL * c.floorW)
      let x := s / c.floorW % c.floorL
      let y := s % c.floorW
      let (f', x', y') := match a with
        | 0 => (f, min (x+1) (c.floorL-1), y)
        | 1 => (f, x-1, y)
        | 2 => (f, x, y-1)
        | 3 => (f, x, min (y+1) (c.floorW-1))
        | 4 => (if x == 0 && y == 0 then f-1 else f, x, y)
        | _ => (if x == c.floorL-1 && y == c.floorW-1 then min (f+1) (c.nFloor-1) else f, x, y)
      (f' * c.floorL + x') * c.floorW + y' }

structure TreasureConfig where
  T : Nat := 5
  n : Nat := 3
  r : Vec := #[1, 1, 1]
  c : Vec := #[1, 1, 1, 1, 1]
  mu0 : Option Vec := none
  deriving Repr, Lean.ToJson, Lean.FromJson

private def treasureDiff (n s : Nat) (l : Array Dual) : Dual :=
  Dual.sum (tabulate (n*n) fun i =>
    let d := l[i]! - if i == s*n+s then 1 else 0
    d*d)

def conservativeTreasureHunting (c : TreasureConfig := {}) : Environment where
  name := "conservative_treasure_hunting"
  T := c.T; S := #[c.n]; A := #[c.n]; mu0 := initial c.n c.mu0; rMax := maxEntry c.r
  inputError := invalid (c.r.size != c.n || c.c.size != c.T || !allFinite c.r ||
    !allFinite c.c || c.c.any (· < 0)) "invalid treasure coefficients"
  rewardFn := fun t l => tabulate (c.n*c.n) fun i =>
    if t == 0 || i / c.n != i % c.n then 0
    else const c.r[i/c.n]! * (1 - treasureDiff c.n (i/c.n) l / 2)
  transitionFn := fun t l => tabulate (c.n*c.n*c.n) fun i =>
    let dst := i / (c.n*c.n)
    let s := i / c.n % c.n
    let a := i % c.n
    if t == 0 then (if dst == a then 1 else 0) else
      let cd := const c.c[t-1]! * treasureDiff c.n s l
      (cd + if dst == a then 1 else 0) / (1 + const c.n.toFloat * cd)

structure CrowdMotionConfig where
  T : Nat := 3
  torusL : Nat := 20
  torusW : Nat := 20
  locChangeFreq : Nat := 2
  c : Float := 10
  logEps : Float := 1e-10
  pStill : Float := 0.5
  seed : Nat := 0
  mu0 : Option Vec := none
  /-- Optional explicit locations for interchange with another numerical backend. -/
  barLocations : Option (Array (Nat × Nat)) := none
  deriving Repr, Lean.ToJson, Lean.FromJson

def crowdBarLocations (c : CrowdMotionConfig) : Array (Nat × Nat) := Id.run do
  if let some locs := c.barLocations then return locs
  let mut g := MT19937.seed c.seed.toUInt32
  let mut loc := (c.torusL / 2, c.torusW / 2)
  let mut out := #[loc]
  for t in [:c.T + 1] do
    if (t+1) % c.locChangeFreq == 0 then
      let (x, g') := g.next
      let (y, g'') := g'.next
      g := g''
      let xx := Int.ofNat loc.1 + (if x % 2 == 0 then -1 else 1)
      let yy := Int.ofNat loc.2 + (if y % 2 == 0 then -1 else 1)
      if xx ≥ 0 && xx < c.torusL && yy ≥ 0 && yy < c.torusW then loc := (xx.toNat, yy.toNat)
    out := out.push loc
  return out

private def moves : Array (Int × Int) := #[(1,0), (-1,0), (0,1), (0,-1), (0,0)]

def crowdMotion (c : CrowdMotionConfig := {}) : Environment :=
  let n := c.torusL * c.torusW
  let locs := crowdBarLocations c
  { name := "crowd_motion", T := c.T, S := #[c.torusL, c.torusW], A := #[5]
    mu0 := initial n c.mu0, rMax := c.c - c.logEps.log
    inputError := invalid (c.locChangeFreq == 0 || c.logEps ≤ 0 || c.pStill < 0 || c.pStill > 1 ||
      !allFinite #[c.c,c.logEps,c.pStill] || locs.size < c.T+1 ||
      locs.any (fun xy => xy.1 ≥ c.torusL || xy.2 ≥ c.torusW)) "invalid crowd motion parameters"
    rewardFn := fun t l =>
      let mu := stateMarginalD n 5 l
      let (barX, barY) := locs[t]!
      tabulate (n*5) fun i =>
        let s := i/5
        let d := (Int.ofNat (s/c.torusW) - barX).natAbs + (Int.ofNat (s%c.torusW) - barY).natAbs
        const (c.c * (1 - d.toFloat / (c.torusL+c.torusW).toFloat)) - (mu[s]! + const c.logEps).log
    transitionFn := fun _ _ => tabulate (n*n*5) fun i =>
      let dst := i/(n*5)
      let s := i/5%n
      let (ax, ay) := moves[i%5]!
      Dual.sum (tabulate 5 fun noise =>
        let (dx, dy) := moves[noise]!
        let x := clampIndex (Int.ofNat (s/c.torusW) + ax + dx) c.torusL
        let y := clampIndex (Int.ofNat (s%c.torusW) + ay + dy) c.torusW
        if dst == x*c.torusW+y then const (if noise == 4 then c.pStill else (1-c.pStill)/4) else 0) }

structure EquilibriumPriceConfig where
  T : Nat := 4
  sInv : Nat := 3
  Q : Nat := 2
  H : Nat := 2
  d : Float := 1
  e0 : Float := 1
  sigma : Float := 1
  c : Vec := #[1, 1, 1, 1, 1]
  mu0 : Option Vec := none
  deriving Repr, Lean.ToJson, Lean.FromJson

def equilibriumPrice (c : EquilibriumPriceConfig := {}) : Environment :=
  let ns := c.sInv+1
  let na := (c.Q+1)*(c.H+1)
  { name := "equilibrium_price", T := c.T, S := #[ns], A := #[c.Q+1, c.H+1]
    mu0 := initial ns c.mu0
    inputError := invalid (c.c.size != 5 || !allFinite c.c || c.e0 ≤ 0 || c.sigma ≤ 0 ||
      c.d ≤ 0 || !allFinite #[c.d,c.e0,c.sigma]) "invalid equilibrium price parameters"
    rMax := (c.d/c.e0).pow (1/c.sigma) * c.Q.toFloat + c.c[0]! * c.Q.toFloat +
      c.c[1]! * (c.Q*c.Q).toFloat + c.c[2]! * c.H.toFloat +
      (c.c[2]!+c.c[3]!) * c.Q.toFloat + c.c[4]! * c.sInv.toFloat
    rewardFn := fun _ l =>
      let supply := Dual.sum (tabulate (ns*na) fun i => l[i]! * const (i/ (c.H+1) % (c.Q+1)).toFloat)
      let price := (const c.d / (supply + const c.e0)).pow (1/c.sigma)
      tabulate (ns*na) fun i =>
        let s := i/na
        let q := i/(c.H+1)%(c.Q+1)
        let h := i%(c.H+1)
        (price - const c.c[0]!) * const q.toFloat - const (c.c[1]! * (q*q).toFloat +
          c.c[2]! * h.toFloat + (c.c[2]!+c.c[3]!) * (q-s).toFloat + c.c[4]! * s.toFloat)
    transitionFn := fun _ _ => deterministic ns na fun s a =>
      min (s - min (a/(c.H+1)) s + a%(c.H+1)) c.sInv }

structure LinearQuadraticConfig where
  T : Nat := 3
  el : Nat := 5
  m : Nat := 2
  sigma : Float := 3
  delta : Float := 0.1
  k : Float := 1
  q : Float := 0.01
  kappa : Float := 0.5
  cTerm : Float := 1
  mu0 : Option Vec := none
  deriving Repr, Lean.ToJson, Lean.FromJson

private def lqMean (el na : Nat) (l : Array Dual) : Dual :=
  let mu := stateMarginalD (2*el+1) na l
  Dual.sum (tabulate (2*el+1) fun s => const (s.toFloat-el.toFloat) * mu[s]!)

def linearQuadratic (c : LinearQuadraticConfig := {}) : Environment :=
  let ns := 2*c.el+1
  let na := 2*c.m+1
  let noises := tabulate 7 fun i => (i.toFloat-3)*c.sigma
  let weights := normalize (noises.map fun x => (-0.5*x*x).exp)
  { name := "linear_quadratic", T := c.T, S := #[ns], A := #[na], mu0 := initial ns c.mu0
    inputError := invalid (c.delta < 0 || !allFinite #[c.sigma,c.delta,c.k,c.q,c.kappa,c.cTerm]) "invalid LQ parameters"
    rMax := (0.5*(c.m*c.m).toFloat + 2*c.q*(c.m*c.el).toFloat + 2*c.kappa*(c.el*c.el).toFloat)*c.delta
    rewardFn := fun t l =>
      let mean := lqMean c.el na l
      tabulate (ns*na) fun i =>
        let d := mean - const ((i/na).toFloat-c.el.toFloat)
        let a := (i%na).toFloat-c.m.toFloat
        if t == c.T then -const (0.5*c.cTerm)*d*d else
          (const (-0.5*a*a) + const (c.q*a)*d - const (0.5*c.kappa)*d*d)*const c.delta
    transitionFn := fun _ l =>
      let mean := (lqMean c.el na l).val
      tabulate (ns*ns*na) fun i =>
        let dst := i/(ns*na)
        let s := (i/na%ns).toFloat-c.el.toFloat
        let a := (i%na).toFloat-c.m.toFloat
        Dual.sum (tabulate 7 fun noise =>
          let next := roundEven (s + (c.k*(mean-s)+a)*c.delta + c.sigma*noises[noise]!*c.delta.sqrt)
          let next := (min c.el.toFloat (max (-c.el.toFloat) next) + c.el.toFloat).toUInt64.toNat
          if dst == next then const weights[noise]! else 0) }

structure RandomLinearCoefficients where
  r1 : Vec
  r2 : Vec
  p1 : Vec
  p2 : Vec
  deriving Repr, Lean.ToJson, Lean.FromJson

def randomLinearCoefficients (n : Nat) (m : Float) (seed : UInt32) : RandomLinearCoefficients :=
  let (r1, g) := (MT19937.seed seed).floats (n*n)
  let (r2, g) := g.floats (n*n)
  let (p1, g) := g.floats (n*n*n)
  let (p2, _) := g.floats (n*n*n)
  let scale := fun v : Vec => v.map (fun x => 2*m*x-m)
  ⟨scale r1, scale r2, scale p1, scale p2⟩

def randomLinear (T : Nat := 3) (n : Nat := 5) (m : Float := 10) (seed : UInt32 := 0)
    (mu0 : Option Vec := none) (coefficients : Option RandomLinearCoefficients := none) : Environment :=
  let c := coefficients.getD (randomLinearCoefficients n m seed)
  { name := "random_linear", T := T, S := #[n], A := #[n], mu0 := initial n mu0, rMax := 2*m
    inputError := invalid (c.r1.size != n*n || c.r2.size != n*n || c.p1.size != n*n*n ||
      c.p2.size != n*n*n || !allFinite (c.r1++c.r2++c.p1++c.p2)) "invalid random linear coefficients"
    rewardFn := fun _ l => tabulate (n*n) fun i =>
      const c.r2[i]! + Dual.sum (tabulate n fun k => const c.r1[i/n*n+k]! * l[k*n+i%n]!)
    transitionFn := fun _ l => Id.run do
      let logits := tabulate (n*n*n) fun i =>
        const c.p2[i]! + Dual.sum (tabulate n fun k => const c.p1[i/n*n+k]! * l[k*n+i%n]!)
      let mut out := Array.replicate (n*n*n) (0 : Dual)
      for i in [:n*n] do
        let ps := Dual.softmax (tabulate n fun dst => logits[dst*n*n+i]!)
        for dst in [:n] do out := out.set! (dst*n*n+i) ps[dst]!
      return out }

end LeanMFG.Computational.Environments
