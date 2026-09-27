import LeanMFG.Verification.Numerical.Population

/-! Regression checks of the same array update used by `meanFieldFromPolicy`. -/
namespace LeanMFG.Numerical.Population

-- Two states, two actions: flattened source masses and destination-major kernel.
private def occupancy : Array Float := #[0.125, 0.375, 0.25, 0.25]
private def kernel : Array Float := #[1, 0.5, 0, 0.25, 0, 0.5, 1, 0.75]

#guard checkedForward 2 4 occupancy kernel == some #[0.375, 0.625]
#guard checkedForward 2 2 #[0.25, 0.75] #[1, 0, 0, 1] == some #[0.25, 0.75]
#guard checkedForward 2 2 #[0.25, 0.75] #[0, 1, 1, 0] == some #[0.75, 0.25]
#guard checkedForward 1 1 #[1] #[1] == some #[1]
#guard checkedForward 2 2 #[0, 0] #[1, 0, 0, 1] == some #[0, 0]
-- Non-stochastic finite inputs are allowed by this arithmetic checker.
#guard checkedForward 1 1 #[1] #[0.5] == some #[0.5]
-- Subnormal values and underflow are covered by the absolute error theorem.
#guard (forward 1 1 #[Float.ofBits 1] #[1])[0]!.toBits == 1
#guard checkedForward 1 1 #[Float.ofBits 1] #[0.5] == some #[0]
-- No silent dimension truncation at the checked interface.
#guard (checkedForward 2 4 #[1] kernel).isNone
#guard (checkedForward 2 4 occupancy #[1]).isNone
#guard (checkedForward 2 4 occupancy (kernel.push 0)).isNone
#guard (checkedForward 0 1 #[1] #[]).isNone
#guard (checkedForward 1 0 #[] #[]).isNone
#guard (checkedForward 1 1 #[Float.nan] #[1]).isNone
#guard (checkedForward 1 1 #[1] #[Float.inf]).isNone
#guard (checkedForward 1 1 #[1e308] #[2]).isNone
#guard (checkedForward 1 2 #[1e308, 1e308] #[1, 1]).isNone

#print axioms update_error
#print axioms update_l1_error
#print axioms update_mass_error
#print axioms update_mass_error_of_normalized
#print axioms update_error_with_input
#print axioms checkedForward_sound
#print axioms checkedForward_mass_error

end LeanMFG.Numerical.Population
