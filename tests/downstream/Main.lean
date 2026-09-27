import LeanMFG

-- Check that downstream clients can use both the theorem API and executable API.
example : LeanMFG.RPS.IsEquilibrium LeanMFG.RPS.uniform :=
  LeanMFG.RPS.uniform_equilibrium

open LeanMFG.Computational

def main : IO Unit := do
  let e := Environments.leftRight
  let .ok result ← (OnlineMirrorDescent.solve { alpha := 0.2 } e none
    { maxIter := 20, atol := none, rtol := none }).run
    | throw (IO.userError "downstream solver failed")
  unless result.policies.size == 21 && result.exploitabilities.size == 21 do
    throw (IO.userError "incomplete downstream solve trace")
  let best := result.bestIndex
  unless result.exploitabilities[best]! < result.exploitabilities[0]! do
    throw (IO.userError "downstream example did not improve")
  let .ok population := meanFieldFromPolicy e result.policies[best]!
    | throw (IO.userError "downstream population update failed")
  unless population.size == e.policySize && population.all Float.isFinite do
    throw (IO.userError "invalid downstream population")
  IO.println "PASS: external import, equilibrium theorem, solver, scoring, and population update"
