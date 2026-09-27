import LeanMFG.Computational.Algorithms.MFOMO

namespace LeanMFG.Computational
open scoped LeanMFG.Computational

inductive Algorithm where
  | fictitiousPlay (config : FictitiousPlay)
  | onlineMirrorDescent (config : OnlineMirrorDescent)
  | priorDescent (config : PriorDescent)
  | mfomo (config : MFOMO)
  | occupationMeasureInclusion (config : OccupationMeasureInclusion)
  deriving Repr, Lean.ToJson, Lean.FromJson

def Algorithm.solve (a : Algorithm) (e : Environment) (pi0 : Option Policy := none)
    (options : SolveOptions := {}) : ExceptT String IO SolveResult :=
  match a with
  | .fictitiousPlay c => c.solve e pi0 options
  | .onlineMirrorDescent c => c.solve e pi0 options
  | .priorDescent c => c.solve e pi0 options
  | .mfomo c => c.solve e pi0 options
  | .occupationMeasureInclusion c => c.solve e pi0 options

/-- Portable native JSON configuration; not a Python pickle or torch checkpoint. -/
def Algorithm.save (a : Algorithm) (path : System.FilePath) : IO Unit :=
  IO.FS.writeFile path ((Lean.toJson a).pretty ++ "\n")

def Algorithm.load (path : System.FilePath) : ExceptT String IO Algorithm := do
  let text ← IO.FS.readFile path
  checked (Lean.Json.parse text >>= Lean.fromJson?)

/-- Native seeded random search using the upstream tuning ranges. Callers can
freeze named fields (camelCase Lean names). This is not Optuna's adaptive TPE. -/
def randomCandidates (template : Algorithm) (count : Nat) (seed : UInt64 := 0)
    (frozen : Array String := #[]) : Array Algorithm := Id.run do
  let (values,_) := randomFloats seed (count*12)
  let mut out := #[]
  for trial in [:count] do
    let u := fun i => values[trial*12+i]!
    let logUniform := fun i lo hi => (lo.log + u i * (hi.log-lo.log)).exp
    let pick := fun {α : Type} (name : String) (old fresh : α) => if frozen.contains name then old else fresh
    let alg := match template with
      | .fictitiousPlay c => .fictitiousPlay { c with alpha := pick "alpha" c.alpha (u 0) }
      | .onlineMirrorDescent c => .onlineMirrorDescent { c with alpha := pick "alpha" c.alpha (logUniform 0 1e-5 1e5) }
      | .priorDescent c => .priorDescent { c with
          eta := pick "eta" c.eta (logUniform 0 1e-5 1e5)
          nInner := pick "nInner" c.nInner (if u 1 < 0.5 then none else some (1+5*(u 2*21).toUInt64.toNat)) }
      | .occupationMeasureInclusion c => .occupationMeasureInclusion { c with
          alpha := pick "alpha" c.alpha (logUniform 0 1e-10 1e3) }
      | .mfomo c => .mfomo { c with
          loss := pick "loss" c.loss (if u 0 < 1/3 then .l1 else if u 0 < 2/3 then .l2 else .l1L2)
          c1 := pick "c1" c.c1 (logUniform 1 1e-2 1e2)
          c2 := pick "c2" c.c2 (logUniform 2 1e-2 1e2)
          rbFreq := pick "rbFreq" c.rbFreq (if u 3 < 0.5 then none else some (1+10*(u 4*21).toUInt64.toNat))
          m1 := pick "m1" c.m1 (if u 5 < 0.5 then 10 else 100)
          m2 := pick "m2" c.m2 (if u 6 < 0.5 then 2 else 4)
          m3 := pick "m3" c.m3 (0.01+0.09*(u 7*12).floor)
          parameterize := pick "parameterize" c.parameterize (u 8 < 0.5)
          hatInit := pick "hatInit" c.hatInit (u 9 < 0.5)
          optimizer := pick "optimizer" c.optimizer {lr := logUniform 10 1e-3 1e3, kind := if u 11 < 0.5 then .adam else .sgd} }
    out := out.push alg
  return out

inductive Statistic where
  | iterations | runtime | exploitability
  deriving BEq, Repr, Lean.ToJson, Lean.FromJson

inductive Metric where
  | failureRate (statistic : Statistic := .exploitability) (threshold : Option Float := none)
  | geometricMean (statistic : Statistic := .exploitability) (shift : Float := 0)
  deriving Repr, Lean.ToJson, Lean.FromJson

def Statistic.value (s : Statistic) (r : SolveResult) : Float := match s with
  | .iterations => (r.policies.size-1).toFloat
  | .runtime => r.runtimes.back!
  | .exploitability => minEntry r.exploitabilities

def Metric.evaluate (metric : Metric) (results : Array SolveResult)
    (options : SolveOptions := {}) : Except String Float := do
  if results.isEmpty || results.any (fun r => r.exploitabilities.isEmpty || r.runtimes.isEmpty || r.policies.isEmpty) then
    throw "metrics require nonempty solution traces"
  match metric with
  | .failureRate stat threshold =>
    let threshold ← match threshold with
      | some x => pure x
      | none => match stat with
        | .iterations => pure options.maxIter.toFloat
        | .runtime => throw "runtime failure rate needs an explicit threshold"
        | .exploitability => match options.atol with
          | some x => pure x
          | none => throw "exploitability failure rate needs threshold or atol"
    return (results.filter (fun r => stat.value r ≥ threshold)).size.toFloat / results.size.toFloat
  | .geometricMean stat shift =>
    let values := results.map (fun r => stat.value r + shift)
    if values.any (· < 0) || !allFinite values then throw "invalid shifted geometric mean inputs"
    if values.contains 0 then return -shift
    return (sum (values.map Float.log) / values.size.toFloat).exp-shift

structure TuningTarget where
  environment : Environment
  pi0 : Option Policy := none

structure Trial where
  algorithm : Algorithm
  score : Option Float
  error : Option String := none
  deriving Repr, Lean.ToJson, Lean.FromJson

structure Study where
  trials : Array Trial
  bestIndex : Nat
  deriving Repr, Lean.ToJson, Lean.FromJson

def Study.bestAlgorithm (s : Study) : Except String Algorithm := do
  let some trial := s.trials[s.bestIndex]? | throw "study has no best trial"
  if trial.score.isNone then throw "study has no successful trial"
  return trial.algorithm

/-- Evaluate a caller-supplied grid or sample of candidates over all targets.
This native tuner does not implement Optuna's TPE sampler or storage API. -/
def tune (candidates : Array Algorithm) (targets : Array TuningTarget)
    (metric : Metric := .geometricMean) (options : SolveOptions := {}) : ExceptT String IO Study := do
  if candidates.isEmpty || targets.isEmpty then throw "tuning needs candidates and targets"
  let mut trials := #[]
  let mut best := 0
  let mut bestScore := (1/0 : Float)
  for algorithm in candidates do
    let run : ExceptT String IO Float := do
      let mut results := #[]
      for target in targets do
        results := results.push (← algorithm.solve target.environment target.pi0 options)
      let score ← checked (metric.evaluate results options)
      if !score.isFinite then throw "non-finite tuning metric"
      return score
    let trialResult : Except String Float ← ExceptT.mk (do return .ok (← run.run))
    match trialResult with
    | .ok score =>
      if score < bestScore then best := trials.size; bestScore := score
      trials := trials.push ⟨algorithm,some score,none⟩
    | .error err => trials := trials.push ⟨algorithm,none,some err⟩
  if !bestScore.isFinite then throw "all tuning trials failed"
  return ⟨trials,best⟩

end LeanMFG.Computational
