import LeanMFG.Verification.Numerical.Binary64

/-! Executable regression checks; the general guarantees are in Verification. -/
namespace LeanMFG.Numerical.Binary64

#guard sumFloat #[] == 0
#guard dotFloat #[] #[] == 0
#guard sumFloat #[0.25, 0.5, 0.25] == 1
#guard dotFloat #[0.25, 0.75] #[2, 4] == 3.5
-- This schedule rounds away the middle 1. Reassociation would change the answer.
#guard sumFloat #[1e16, 1, -1e16] == 0
-- The midpoint above 1 rounds back to the even significand.
#guard sumFloat #[1, Float.ofBits 0x3ca0000000000000] == 1
-- Gradual underflow: two minimum subnormals add exactly.
#guard (sumFloat #[Float.ofBits 1, Float.ofBits 1]).toBits == 2
#guard checkedSum [ofFloat (Float.ofBits 1), ofFloat (Float.ofBits 1)] |>.isSome
#guard checkedDotFloat #[Float.ofBits 1] #[0.5] |>.isSome
#guard (dotFloat #[Float.ofBits 1] #[0.5]).toBits == 0
#guard checkedSum [] |>.isSome
#guard checkedDotFloat #[] #[] |>.isSome
#guard checkedDotFloat #[0.25, 0.75] #[2, 4] |>.isSome
#guard checkedSum [ofFloat Float.nan] |>.isNone
#guard checkedSum [ofFloat Float.inf] |>.isNone
#guard checkedSum [ofFloat 1e308, ofFloat 1e308, ofFloat (-1e308)] |>.isNone
#guard checkedDotFloat #[1e308] #[2] |>.isNone
#guard checkedDotFloat #[Float.inf] #[0] |>.isNone
#guard checkedDotFloat #[Float.nan] #[1] |>.isNone
#guard checkedDotFloat #[1, 2] #[3] |>.isNone

-- Kernel trust audit: only the usual Lean/mathlib axioms should appear.
#print axioms add_error
#print axioms mul_error
#print axioms sumFloat_error
#print axioms dotFloat_error
#print axioms checkedSum_sound
#print axioms checkedDotFloat_sound

end LeanMFG.Numerical.Binary64
