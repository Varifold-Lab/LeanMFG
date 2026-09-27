import LeanMFG.Computational

open LeanMFG.Computational

def main : IO Unit := do
  let env := Environments.leftRight
  let .ok result ← (OnlineMirrorDescent.solve { alpha := 0.2 } env none
    { maxIter := 20, atol := none, rtol := none }).run
    | throw (IO.userError "solver failed")
  let best := result.bestIndex
  IO.println s!"Policy shape: {env.policyShape}"
  IO.println s!"Stored policies: {result.policies.size}"
  IO.println s!"Initial exploitability: {result.exploitabilities[0]!}"
  IO.println s!"Best iteration: {best}"
  IO.println s!"Best exploitability: {result.exploitabilities[best]!}"
