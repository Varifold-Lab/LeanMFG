import LeanMFG.Computational.Json
import LeanMFG.Numerical.Binary64

/-! Executable numerical support for the MFGLib port. All arrays use row-major order.
The dual numbers below carry one directional derivative; they are used by MFOMO.
See NOTICE for the upstream attribution. -/

namespace LeanMFG.Computational

abbrev Vec := Array Float

def tabulate (n : Nat) (f : Nat → α) : Array α := (Array.range n).map f
def sum (v : Vec) : Float := Numerical.Binary64.sumFloat v
def dot (x y : Vec) : Float := Numerical.Binary64.dotFloat x y
def norm (x : Vec) : Float := (dot x x).sqrt
def maxEntry (x : Vec) : Float := x.foldl max (-1/0)
def minEntry (x : Vec) : Float := x.foldl min (1/0)
def allFinite (x : Vec) : Bool := x.all Float.isFinite
def uniformVec (n : Nat) : Vec := Array.replicate n (1 / n.toFloat)
def slice (x : Array α) (start len : Nat) : Array α := x.extract start (start + len)

def softmax (x : Vec) : Vec :=
  let m := maxEntry x
  let y := x.map fun a => (a - m).exp
  let z := sum y
  y.map (· / z)

def normalize (x : Vec) : Vec :=
  let s := sum x
  if s == 0 then uniformVec x.size else x.map (· / s)

/-- Euclidean projection onto the nonnegative simplex of total mass `radius`. -/
def projectSimplex (x : Vec) (radius : Float := 1) : Except String Vec := do
  if x.isEmpty || !allFinite x || !radius.isFinite || radius < 0 then
    throw "simplex projection requires a nonempty finite vector and nonnegative radius"
  if radius == 0 then return Array.replicate x.size 0
  let sorted := x.toList.mergeSort (fun a b => a ≥ b)
  let mut total := 0.0
  let mut theta := 0.0
  let mut count := 0
  for v in sorted do
    count := count + 1
    total := total + v
    let candidate := (total - radius) / count.toFloat
    if v > candidate then theta := candidate
  let p := x.map fun v => max (v - theta) 0
  let mass := sum p
  return if mass == 0 then (uniformVec x.size).map (· * radius)
    else p.map (fun v => v / mass * radius)

/-- A value and its derivative in one seed direction. No finite differences. -/
structure Dual where
  val : Float
  tangent : Float := 0
  deriving Inhabited, Repr

namespace Dual
def const (v : Float) : Dual := ⟨v, 0⟩
instance : OfNat Dual n := ⟨const n.toFloat⟩
instance : Add Dual := ⟨fun x y => ⟨x.val + y.val, x.tangent + y.tangent⟩⟩
instance : Neg Dual := ⟨fun x => ⟨-x.val, -x.tangent⟩⟩
instance : Sub Dual := ⟨fun x y => ⟨x.val - y.val, x.tangent - y.tangent⟩⟩
instance : Mul Dual := ⟨fun x y =>
  ⟨x.val * y.val, x.tangent * y.val + x.val * y.tangent⟩⟩
instance : Div Dual := ⟨fun x y =>
  ⟨x.val / y.val, (x.tangent * y.val - x.val * y.tangent) / (y.val * y.val)⟩⟩
def exp (x : Dual) : Dual := ⟨x.val.exp, x.tangent * x.val.exp⟩
def log (x : Dual) : Dual := ⟨x.val.log, x.tangent / x.val⟩
def sin (x : Dual) : Dual := ⟨x.val.sin, x.tangent * x.val.cos⟩
def pow (x : Dual) (p : Float) : Dual :=
  ⟨x.val.pow p, x.tangent * p * x.val.pow (p - 1)⟩
/-- PyTorch's subgradient convention: abs has derivative zero at zero. -/
def abs (x : Dual) : Dual :=
  ⟨x.val.abs, if x.val > 0 then x.tangent else if x.val < 0 then -x.tangent else 0⟩
def clampMin (x : Dual) (lo : Float) : Dual := if x.val < lo then const lo else x
def sum (x : Array Dual) : Dual := x.foldl (· + ·) 0
def softmax (x : Array Dual) : Array Dual :=
  let m := const (maxEntry (x.map (·.val)))
  let y := x.map fun a => (a - m).exp
  let z := sum y
  y.map (· / z)
end Dual

/-- Round ties to even, as in torch.round (Lean's Float.round uses a different rule). -/
def roundEven (x : Float) : Float :=
  let lo := x.floor
  let frac := x - lo
  if frac < 0.5 then lo else if frac > 0.5 then lo + 1
  else if lo.abs.toUInt64.toNat % 2 == 0 then lo else lo + 1

def clampIndex (x : Int) (n : Nat) : Nat := (max 0 (min x (Int.ofNat n - 1))).toNat

/-- Small deterministic generator. Its sequence is explicitly not PyTorch's RNG. -/
def randomFloats (seed : UInt64) (n : Nat) : Vec × UInt64 := Id.run do
  let mut state := seed
  let mut out := #[]
  for _ in [:n] do
    state := state * 6364136223846793005 + 1442695040888963407
    out := out.push ((state >>> 11).toNat.toFloat / 9007199254740992)
  return (out, state)

end LeanMFG.Computational
