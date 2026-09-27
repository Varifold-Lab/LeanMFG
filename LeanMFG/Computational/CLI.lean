import LeanMFG.Computational.Environments
import LeanMFG.Computational.Tuning

namespace LeanMFG.Computational
open scoped LeanMFG.Computational

inductive EnvironmentSpec where
  | leftRight (mu0 : Vec := #[1,0,0])
  | rockPaperScissors (T : Nat := 1) (mu0 : Vec := #[1,0,0,0])
  | susceptibleInfected (T : Nat := 50) (mu0 : Vec := #[0.4,0.6])
  | beachBar (config : Environments.BeachBarConfig := {})
  | buildingEvacuation (config : Environments.BuildingEvacuationConfig := {})
  | conservativeTreasureHunting (config : Environments.TreasureConfig := {})
  | crowdMotion (config : Environments.CrowdMotionConfig := {})
  | equilibriumPrice (config : Environments.EquilibriumPriceConfig := {})
  | linearQuadratic (config : Environments.LinearQuadraticConfig := {})
  | randomLinear (T : Nat := 3) (n : Nat := 5) (m : Float := 10) (seed : Nat := 0)
      (mu0 : Option Vec := none) (coefficients : Option Environments.RandomLinearCoefficients := none)
  deriving Repr, Lean.ToJson, Lean.FromJson

def EnvironmentSpec.build : EnvironmentSpec → Environment
  | .leftRight mu => Environments.leftRight mu
  | .rockPaperScissors t mu => Environments.rockPaperScissors t mu
  | .susceptibleInfected t mu => Environments.susceptibleInfected t mu
  | .beachBar cfg => Environments.beachBar cfg
  | .buildingEvacuation cfg => Environments.buildingEvacuation cfg
  | .conservativeTreasureHunting cfg => Environments.conservativeTreasureHunting cfg
  | .crowdMotion cfg => Environments.crowdMotion cfg
  | .equilibriumPrice cfg => Environments.equilibriumPrice cfg
  | .linearQuadratic cfg => Environments.linearQuadratic cfg
  | .randomLinear t n m seed mu coefficients => Environments.randomLinear t n m seed.toUInt32 mu coefficients

def environmentNames : Array String := #["left_right","rock_paper_scissors","susceptible_infected",
  "beach_bar","building_evacuation","conservative_treasure_hunting","crowd_motion",
  "equilibrium_price","linear_quadratic","random_linear"]

def environmentByName (name : String) : Except String EnvironmentSpec := match name with
  | "left_right" => .ok .leftRight
  | "rock_paper_scissors" => .ok .rockPaperScissors
  | "susceptible_infected" => .ok .susceptibleInfected
  | "beach_bar" => .ok .beachBar
  | "building_evacuation" => .ok .buildingEvacuation
  | "conservative_treasure_hunting" => .ok .conservativeTreasureHunting
  | "crowd_motion" => .ok .crowdMotion
  | "equilibrium_price" => .ok .equilibriumPrice
  | "linear_quadratic" => .ok .linearQuadratic
  | "random_linear" => .ok .randomLinear
  | _ => .error s!"unknown environment: {name}"

def algorithmByName (name : String) : Except String Algorithm := match name with
  | "fp" => .ok (.fictitiousPlay {})
  | "omd" => .ok (.onlineMirrorDescent {})
  | "pd" => .ok (.priorDescent {})
  | "mfomo" => .ok (.mfomo {})
  | "omi" => .ok (.occupationMeasureInclusion {})
  | _ => .error s!"unknown algorithm: {name}; choose fp, omd, pd, mfomo, omi"

structure RunConfig where
  environment : EnvironmentSpec := .leftRight
  algorithm : Algorithm := .onlineMirrorDescent {}
  options : SolveOptions := {}
  pi0 : Option Policy := none
  deriving Repr, Lean.ToJson, Lean.FromJson

structure TuneConfig where
  environments : Array EnvironmentSpec
  candidates : Array Algorithm
  metric : Metric := .geometricMean .exploitability 1e-8
  options : SolveOptions := {}
  deriving Repr, Lean.ToJson, Lean.FromJson

def readConfig [Lean.FromJson α] (path : System.FilePath) : ExceptT String IO α := do
  let text ← IO.FS.readFile path
  checked (Lean.Json.parse text >>= Lean.fromJson?)

def runConfig (cfg : RunConfig) : ExceptT String IO Unit := do
  let e := cfg.environment.build
  let result ← cfg.algorithm.solve e cfg.pi0 cfg.options
  IO.println ((Lean.Json.mkObj [
    ("environment",Lean.toJson e.name), ("shape",Lean.toJson e.policyShape),
    ("bestIndex",Lean.toJson result.bestIndex), ("result",Lean.toJson result)]).compress)

def cli (args : List String) : ExceptT String IO Unit := do
  match args with
  | ["--list"] => IO.println (String.intercalate "\n" environmentNames.toList)
  | ["--write-config",path] => IO.FS.writeFile path ((Lean.toJson ({} : RunConfig)).pretty ++ "\n")
  | ["--config",path] => runConfig (← readConfig path)
  | ["--tune",path] =>
    let cfg : TuneConfig ← readConfig path
    let study ← tune cfg.candidates (cfg.environments.map fun e => ⟨e.build,none⟩) cfg.metric cfg.options
    IO.println ((Lean.toJson study).pretty)
  | [environment,algorithm] => runConfig {
      environment := ← checked (environmentByName environment)
      algorithm := ← checked (algorithmByName algorithm) }
  | [environment,algorithm,maxIter] =>
    let some n := maxIter.toNat? | throw "maxIter must be a nonnegative integer"
    let env ← checked (environmentByName environment)
    let alg ← checked (algorithmByName algorithm)
    runConfig { environment := env, algorithm := alg, options := {maxIter := n} }
  | _ => throw "usage: lake exe mfglib ENVIRONMENT ALGORITHM [MAX_ITER]\n       lake exe mfglib --list | --write-config FILE | --config FILE | --tune FILE"

end LeanMFG.Computational

def main (args : List String) : IO UInt32 := do
  match ← (LeanMFG.Computational.cli args).run with
  | .ok _ => return 0
  | .error err => IO.eprintln err; return 1
