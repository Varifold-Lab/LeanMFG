import FloatLib.Floats.Formats.IEEE754.Native
import FloatLib.Floats.Formats.BinaryInterchange.Configured.Rounding.Runtime

/-! Binary64 arithmetic with explicit nearest-even rounding. Each product is rounded
before the left-to-right sum; no fused multiply-add or reassociation is used. -/
namespace LeanMFG.Numerical.Binary64

open FloatLib.Floats

abbrev Value := ExecFloat.Binary 11 52
def zero : Value := ExecFloat.Binary.zero false
def add (x y : Value) : Value := ExecFloat.Binary.addWithRounding x y .nearestEven
def mul (x y : Value) : Value := ExecFloat.Binary.mulWithRounding x y .nearestEven
abbrev ofFloat := ExecFloat.Binary.ofFloat
abbrev toFloat := ExecFloat.Binary.toFloat
abbrev isFinite (x : Value) := ExecFloat.Binary.isFinite x

/-- A left fold, starting with the supplied accumulator. -/
def sumFrom (acc : Value) : List Value → Value
  | [] => acc
  | x :: xs => sumFrom (add acc x) xs

/-- Checks every input and every intermediate accumulator, including the result. -/
def sumFinite (acc : Value) : List Value → Bool
  | [] => isFinite acc
  | x :: xs => isFinite acc && isFinite x && sumFinite (add acc x) xs

def sum (xs : List Value) : Value := sumFrom zero xs
def products (xs : List (Value × Value)) : List Value := xs.map fun p => mul p.1 p.2
def dot (xs : List (Value × Value)) : Value := sum (products xs)

def dotFinite (xs : List (Value × Value)) : Bool :=
  xs.all (fun p => isFinite p.1 && isFinite p.2 && isFinite (mul p.1 p.2)) &&
    sumFinite zero (products xs)

/-- Failure means a nonfinite input or intermediate result. -/
def checkedSum (xs : List Value) : Option Value :=
  if sumFinite zero xs then some (sum xs) else none

/-- Includes checks of both operands, rounded products, and every partial sum. -/
def checkedDot (xs : List (Value × Value)) : Option Value :=
  if dotFinite xs then some (dot xs) else none

def sumFloat (xs : Array Float) : Float := toFloat (sum (xs.toList.map ofFloat))

/-- Like `Array.zipWith`, this unchecked primitive uses the shorter input length. -/
def dotFloat (xs ys : Array Float) : Float :=
  toFloat (dot ((xs.toList.zip ys.toList).map fun p => (ofFloat p.1, ofFloat p.2)))

/-- The checked array interface also rejects mismatched dimensions. -/
def checkedDotFloat (xs ys : Array Float) : Option Value :=
  if xs.size == ys.size then
    checkedDot ((xs.toList.zip ys.toList).map fun p => (ofFloat p.1, ofFloat p.2))
  else none

end LeanMFG.Numerical.Binary64
