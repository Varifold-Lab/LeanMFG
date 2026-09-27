import LeanMFG.Computational.Numeric

namespace LeanMFG.Computational

/-- MT19937 with the scalar CPU sampling convention used by PyTorch.
See the MT19937 notice in NOTICE. -/
structure MT19937 where
  words : Array UInt32
  index : Nat := 624

namespace MT19937
def seed (s : UInt32) : MT19937 := Id.run do
  let mut v := #[s]
  for i in [1:624] do
    let prev := v[i-1]!
    v := v.push ((1812433253 : UInt32) * (prev ^^^ (prev >>> 30)) + i.toUInt32)
  return ⟨v, 624⟩

def next (g : MT19937) : UInt32 × MT19937 := Id.run do
  let mut v := g.words
  let mut index := g.index
  if index == 624 then
    for i in [:624] do
      let y := (v[i]! &&& 0x80000000) ||| (v[(i+1)%624]! &&& 0x7fffffff)
      v := v.set! i (v[(i+397)%624]! ^^^ (y >>> 1) ^^^
        (if y &&& 1 == 0 then 0 else 0x9908b0df))
    index := 0
  let mut y := v[index]!
  y := y ^^^ (y >>> 11)
  y := y ^^^ ((y <<< 7) &&& 0x9d2c5680)
  y := y ^^^ ((y <<< 15) &&& 0xefc60000)
  y := y ^^^ (y >>> 18)
  return (y, ⟨v, index + 1⟩)

def floats (g : MT19937) (n : Nat) : Vec × MT19937 := Id.run do
  let mut g := g
  let mut out := #[]
  for _ in [:n] do
    let (v, g') := g.next
    g := g'
    out := out.push ((v &&& 0xffffff).toNat.toFloat / 16777216)
  return (out, g)
end MT19937

end LeanMFG.Computational
