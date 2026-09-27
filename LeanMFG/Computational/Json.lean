import Lean

namespace LeanMFG.Computational

/-- Serialize the exact dyadic value, avoiding Lean's six-decimal diagnostic
Float display. This matters for small tolerances and saved probability rows.
The scope is local to the numerical API; it does not replace Lean's global instance. -/
def floatJson (x : Float) : Lean.Json :=
  if !x.isFinite then Lean.Float.toJson x else
  if x == 0 then .num 0 else
  let bits := x.toBits.toNat
  let exponent := bits / 2^52 % 2048
  let significand := bits % 2^52 + if exponent == 0 then 0 else 2^52
  let shift : Int := if exponent == 0 then -1074 else Int.ofNat exponent - 1075
  let negative := bits / 2^63 != 0
  let (coefficient, places) := if shift ≥ 0 then
      (significand * 2^shift.toNat, 0)
    else (significand * 5^(-shift).toNat, (-shift).toNat)
  .num ⟨if negative then -Int.ofNat coefficient else Int.ofNat coefficient, places⟩

scoped instance exactFloatToJson : Lean.ToJson Float := ⟨floatJson⟩

end LeanMFG.Computational
