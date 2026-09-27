import LeanMFG.Computational.Environments
import LeanMFG.Computational.Tuning

/-! Differential checks against unmodified MFGLib. This is executable testing,
not a collection of formal correctness claims. -/
namespace LeanMFG.Computational.Checks
open scoped LeanMFG.Computational
open Environments

def environments : Array Environment := #[
  leftRight, rockPaperScissors 2, susceptibleInfected 3,
  beachBar { T := 2, n := 4, barLoc := 1, pStill := 0.3 },
  buildingEvacuation { T := 2, nFloor := 2, floorL := 2, floorW := 2 },
  conservativeTreasureHunting { T := 2, n := 3, r := #[1,2,3], c := #[0.7,1.2] },
  crowdMotion { T := 3, torusL := 3, torusW := 4, seed := 17 },
  equilibriumPrice { T := 2, sInv := 2, Q := 1, H := 2, sigma := 1.3 },
  linearQuadratic { T := 2, el := 2, m := 1 },
  randomLinear 2 3 2 17 ]

def samplePolicy (e : Environment) : Policy := Id.run do
  let raw := tabulate e.policySize fun i => (1+(i*7+3)%11).toFloat
  let mut out := #[]
  for row in [:(e.T+1)*e.nStates] do out := out ++ normalize (slice raw (row*e.nActions) e.nActions)
  return out

def sampleMeanField (e : Environment) : MeanField := Id.run do
  let raw := tabulate e.policySize fun i => (1+(i*3+1)%7).toFloat
  let mut out := #[]
  for t in [:e.T+1] do out := out ++ normalize (slice raw (t*e.sliceSize) e.sliceSize)
  return out

def snapshots : ExceptT String IO (Array (String × Vec)) := do
  let mut out := #[]
  for seed in #[0,17] do
    out := out.push (s!"rng/{seed}", ((MT19937.seed seed).floats 700).1)
  let coefficients := randomLinearCoefficients 3 2 17
  for (key,v) in #[("r1",coefficients.r1),("r2",coefficients.r2),("p1",coefficients.p1),("p2",coefficients.p2)] do
    out := out.push ("random_coeff/"++key,v)
  for e in environments do
    let name := e.name
    let n := e.policySize
    let pi := samplePolicy e
    let l := sampleMeanField e
    let induced ← checked (meanFieldFromPolicy e pi)
    out := out.push (name++"/policy",pi)
    out := out.push (name++"/mean_field",induced)
    out := out.push (name++"/recovered",← checked (policyFromMeanField e induced))
    for t in [:e.T+1] do
      let lt := slice l (t*e.sliceSize) e.sliceSize
      checked (e.validateAt t lt)
      out := out.push (s!"{name}/reward/{t}",e.reward t lt)
      if t < e.T then out := out.push (s!"{name}/prob/{t}",e.prob t lt)
    out := out.push (name++"/q_optimal",← checked (QFn.optimal e l))
    out := out.push (name++"/q_policy",← checked (QFn.forPolicy e l pi))
    out := out.push (name++"/greedy",← checked (greedyPolicyGivenMeanField e l))
    out := out.push (name++"/score",#[← checked (exploitabilityScore e pi)])
    let params ← checked (mfOMOParams e l)
    out := out.push (name++"/params/b",params.b)
    out := out.push (name++"/params/A",params.A)
    out := out.push (name++"/params/c",params.c)
    let (some z, y) ← checked (hatInitialization e l false) | throw "missing hat z"
    out := out.push (name++"/hat/z",z)
    out := out.push (name++"/hat/y",y)
    let mut solvers : Array (String × Algorithm) := #[
      ("fp",.fictitiousPlay {}), ("fp_constant",.fictitiousPlay {alpha := 0.3}),
      ("omd",.onlineMirrorDescent {alpha := 0.2}), ("pd",.priorDescent {eta := 0.7}),
      ("pd_inner",.priorDescent {eta := 0.7,nInner := some 2})]
    if #["left_right","susceptible_infected","random_linear"].contains name then
      solvers := solvers ++ #[
        ("omi",.occupationMeasureInclusion {alpha := 0.03,projection := {atol := 1e-10,rtol := 1e-10}}),
        ("mfomo",.mfomo {}), ("mfomo_parameterized",.mfomo {parameterize := true}),
        ("mfomo_sgd",.mfomo {loss := .l2,hatInit := false,rbFreq := some 2,optimizer := {kind := .sgd,lr := 0.01,momentum := 0.3}})]
      for parameterize in #[false,true] do
        let nz := n + if parameterize then 1 else 0
        let zv := tabulate nz fun i => i.toFloat/(nz+1).toFloat+0.1
        let yw := tabulate ((e.T+1)*e.nStates) fun i => i.toFloat/13-0.3
        let lu := if parameterize then l.map Float.log else l
        let x := lu ++ zv ++ yw
        for (key,loss) in #[("l1",OMOLoss.l1),("l2",OMOLoss.l2),("l1_l2",OMOLoss.l1L2)] do
          let cfg : MFOMO := { loss := loss,c1 := 1.2,c2 := 0.7,c3 := 0.4,parameterize := parameterize }
          let label := s!"{name}/objective/{if parameterize then 1 else 0}/{key}"
          out := out.push (label,#[mfOMOObjective cfg e x])
          out := out.push (label++"/gradient",mfOMOGradient cfg e x)
        let (v,w) ← checked (hatInitialization e l parameterize)
        let label := s!"{name}/hat/{if parameterize then 1 else 0}"
        -- Log coordinates amplify harmless roundoff at zero. Compare the
        -- represented softmax probabilities for parameterized initialization.
        let vv := v.getD #[]
        out := out.push (label++"/v",if parameterize && !vv.isEmpty then softmax vv else vv)
        out := out.push (label++"/w",w)
      let constraints ← checked (mfOMOConstraints e ((l.map (fun x => x*4-0.1)) ++
        (z.map (fun x => x*100-1)) ++ (y.map (· * 100))))
      out := out.push (name++"/constraints",constraints)
      let (c1,c2) := mfOMOResidualBalancing {} e (l++z++y)
      out := out.push (name++"/balancing",#[c1,c2])
      let projection ← checked (projectOccupation (l.zipWith (fun l c => l-0.03*c) params.c) params
        {atol := 1e-10,rtol := 1e-10})
      out := out.push (name++"/projection",projection.x)
    for (key,solver) in solvers do
      -- Pinned upstream FP raises a shape error for multidimensional actions.
      if e.A.size > 1 && (key == "fp" || key == "fp_constant") then continue
      let result ← solver.solve e (some pi) {maxIter := 3,atol := none,rtol := none}
      out := out.push (s!"{name}/solver/{key}/policies",result.policies.flatten)
      out := out.push (s!"{name}/solver/{key}/scores",result.exploitabilities)
  for radius in #[0,1,2] do
    out := out.push (s!"simplex/{radius}",← checked (projectSimplex #[-2,0.3,1.2,3] radius.toFloat))
  return out

private def assertTrue (condition : Bool) (message : String) : Except String Unit :=
  if condition then .ok () else .error message

private def failed (result : Except String α) : Bool :=
  match result with | .error _ => true | .ok _ => false

def edgeChecks : ExceptT String IO Unit := do
  let e := leftRight
  let uniform := Policy.uniform e
  checked (assertTrue (((← checked (exploitabilityScore e uniform)) - 0.25).abs < 1e-12) "left/right uniform score")
  let equilibrium := uniform.set! 0 (2/3) |>.set! 1 (1/3)
  checked (assertTrue ((← checked (exploitabilityScore e equilibrium)).abs < 1e-12) "left/right equilibrium")
  let stopped ← (OnlineMirrorDescent.mk 0.2).solve e (some equilibrium)
  checked (assertTrue (stopped.stoppedEarly && stopped.policies.size == 1) "initial early stopping")
  let allLeft := uniform.set! 0 1 |>.set! 1 0
  let allRight := uniform.set! 0 0 |>.set! 1 1
  let scores ← checked (exploitabilityScores e #[allLeft,allRight])
  checked (assertTrue (scores == #[1,2]) "pure policy exploitability")
  let tieL := sampleMeanField e
  let greedy ← checked (greedyPolicyGivenMeanField e tieL)
  checked (assertTrue ((slice greedy e.sliceSize e.sliceSize).all (· == 0.5)) "terminal tied actions")
  let recovered ← checked (policyFromMeanField e (Array.replicate e.policySize 0))
  checked (assertTrue (recovered == uniform) "unreachable states use uniform policy")
  let post ← checked (Policy.postprocess e (Array.replicate e.policySize (-1)))
  checked (assertTrue (post == uniform) "zero rows after clipping")
  for invalid in #[#[],uniform.set! 0 (-1),uniform.set! 0 (0/0),uniform.set! 0 (1/0)] do
    checked (assertTrue (failed (Policy.build e invalid)) "invalid policy accepted")
  checked (assertTrue (failed (beachBar {n := 0} |>.validate)) "empty state space")
  checked (assertTrue (failed (conservativeTreasureHunting {T := 2} |>.validate)) "bad treasure coefficient shape")
  checked (assertTrue (failed (projectSimplex #[1,2] (-1))) "negative simplex radius")
  checked (assertTrue (failed (MFOMO.init {parameterize := true} e allLeft)) "log zero initialization")
  let omo ← (MFOMO.solve {parameterize := true,hatInit := false} e none {maxIter := 2,atol := none,rtol := none})
  checked (assertTrue (omo.policies.size == 3) "parameterization without hat initialization")
  for env in environments do
    let result ← (OccupationMeasureInclusion.solve {alpha := 0.01} env none {maxIter := 2,atol := none,rtol := none})
    checked (assertTrue (result.policies.size == 3 && allFinite result.exploitabilities) "OMI smoke check")
  let multi ← FictitiousPlay.solve {} (equilibriumPrice {T := 2,sInv := 2,Q := 1,H := 2}) none
    {maxIter := 3,atol := none,rtol := none}
  checked (assertTrue (multi.policies.size == 4) "multidimensional action FP")
  let candidates : Array Algorithm := #[.onlineMirrorDescent {alpha := 0.1},.onlineMirrorDescent {alpha := 0.5}]
  let study ← tune candidates #[⟨e,none⟩] (.geometricMean .exploitability 1e-6) {maxIter := 4,atol := none,rtol := none}
  let best ← checked study.bestAlgorithm
  let json := Lean.toJson best
  let restored : Algorithm ← checked (Lean.fromJson? json)
  checked (assertTrue ((Lean.toJson restored).compress == json.compress) "algorithm serialization")
  let fr ← checked ((Metric.failureRate .iterations (some 1)).evaluate #[stopped])
  checked (assertTrue (fr == 0) "failure rate metric")
  for x in #[(0 : Float), 1/3, 1e-20, -1e-200, Float.ofBits 1,
      Float.ofBits 0x7fefffffffffffff] do
    let restored : Float ← checked ((Lean.Json.parse (floatJson x).compress >>= Lean.fromJson?).mapError
      (fun err => s!"float JSON {x.toBits}: {err}; encoded={(floatJson x).compress}"))
    checked (assertTrue (restored.toBits == x.toBits) "float JSON lost precision")
  let cfg : MFOMO := {optimizer := {eps := 1e-12},L := some equilibrium}
  let restored : MFOMO ← checked (Lean.Json.parse (Lean.toJson cfg).compress >>= Lean.fromJson?)
  checked (assertTrue (restored.optimizer.eps == cfg.optimizer.eps && restored.L == cfg.L)
    "saved numerical configuration lost precision")
  return ()

def run (referencePath : System.FilePath := "tests/mfglib/reference.json") : ExceptT String IO Unit := do
  let text ← IO.FS.readFile referencePath
  let json ← checked (Lean.Json.parse text)
  let pin : String ← checked (json.getObjValAs? String "upstream")
  if pin != "d4adccf134e88ad47e0a517af5175edaec15a30f" then throw "unexpected upstream fixture version"
  let vectors ← checked (json.getObjVal? "vectors")
  let actual ← snapshots
  let mut compared := 0
  let mut failures := #[]
  for (key,values) in actual do
    let expected : Vec ← checked (vectors.getObjValAs? Vec key)
    if expected.size != values.size then throw s!"{key}: size {values.size}, expected {expected.size}"
    let mut error := 0.0
    for i in [:values.size] do
      if !values[i]!.isFinite || !expected[i]!.isFinite then throw s!"{key}[{i}]: non-finite comparison"
      let tolerance := 2e-7 + 2e-7 * expected[i]!.abs
      if (values[i]!-expected[i]!).abs > tolerance then
        error := max error (values[i]!-expected[i]!).abs
    if error > 0 then failures := failures.push s!"{key}: max absolute error {error}"
    compared := compared + values.size
  let expectedCount := (← checked vectors.getObj?).size
  if expectedCount != actual.size then throw s!"missing reference vectors: expected {expectedCount}, got {actual.size}"
  if !failures.isEmpty then throw ("differential checks failed:\n" ++ String.intercalate "\n" failures.toList)
  edgeChecks
  IO.println s!"PASS: {actual.size} MFGLib reference vectors ({compared} scalars); edge/integration checks."

end LeanMFG.Computational.Checks
