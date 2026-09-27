import LeanMFG.Computational.Checks

def main (args : List String) : IO UInt32 := do
  let result ← (LeanMFG.Computational.Checks.run (args.headD "tests/mfglib/reference.json")).run
  match result with
  | .ok _ => return 0
  | .error message => IO.eprintln message; return 1
