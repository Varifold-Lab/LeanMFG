import LeanMFG
import Lean.Util.CollectAxioms

/-! Fail the check when a declaration in an imported LeanMFG module depends on
an axiom outside the project's documented trust policy. This includes private
declarations and transitive dependencies, not just names in a public namespace. -/
open Lean in
run_cmd do
  let env ← getEnv
  let allowed := #[``propext, ``Classical.choice, ``Quot.sound]
  let mut count : Nat := 0
  for (name, _) in env.constants do
    if let some idx := env.getModuleIdxFor? name then
      if (`LeanMFG).isPrefixOf env.header.moduleNames[idx.toNat]! then
        count := count + 1
        for ax in ← collectAxioms name do
          unless allowed.contains ax do
            throwError "{name} depends on forbidden axiom {ax}"
  if count == 0 then throwError "No LeanMFG declarations were audited"
  logInfo m!"PASS: axiom audit of {count} LeanMFG declarations"
