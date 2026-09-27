import Mathlib.Data.Rat.Defs
import Mathlib.Tactic

/-!
# One-step finite-state mean field games

This is a small executable dynamic model. The population starts in `initial`,
uses a mixed policy, and moves through a stochastic transition kernel. A
single player's deviation changes her policy while the induced population
distribution stays fixed.
-/

namespace LeanMFG.FiniteState

/-- A rational distribution on a finite type. -/
structure Distribution (α : Type*) [Fintype α] where
  prob : α → ℚ
  nonneg : ∀ a, 0 ≤ prob a
  total : (∑ a, prob a) = 1

namespace Distribution

variable {α β : Type*} [Fintype α] [Fintype β]

/-- A deterministic distribution, used for pure actions and states. -/
def pure [DecidableEq α] (a : α) : Distribution α where
  prob := fun b => if b = a then 1 else 0
  nonneg := by intro b; split <;> norm_num
  total := by simp

/-- Expected value of a rational function under a finite distribution. -/
def expect (p : Distribution α) (f : α → ℚ) : ℚ :=
  ∑ a, p.prob a * f a

/-- A deterministic distribution evaluates a function at its chosen point. -/
@[simp] theorem expect_pure [DecidableEq α] (a : α) (f : α → ℚ) :
    (pure a).expect f = f a := by
  simp [expect, pure]

theorem expect_const (p : Distribution α) (c : ℚ) :
    p.expect (fun _ => c) = c := by
  unfold expect
  rw [← Finset.sum_mul, p.total, one_mul]

/-- Push a finite distribution through a stochastic kernel. -/
def bind (p : Distribution α) (f : α → Distribution β) : Distribution β where
  prob := fun b => ∑ a, p.prob a * (f a).prob b
  nonneg := by
    intro b
    exact Finset.sum_nonneg fun a _ => mul_nonneg (p.nonneg a) ((f a).nonneg b)
  total := by
    calc
      (∑ b, ∑ a, p.prob a * (f a).prob b) =
          ∑ a, ∑ b, p.prob a * (f a).prob b := Finset.sum_comm
      _ = ∑ a, p.prob a * (∑ b, (f a).prob b) := by
        simp_rw [Finset.mul_sum]
      _ = ∑ a, p.prob a := by simp [Distribution.total]
      _ = 1 := p.total

end Distribution

/-- Environment data for one decision and one state transition. Rewards may
depend on the population's terminal distribution. -/
structure Game (State Action : Type*) [Fintype State] [Fintype Action] where
  initial : Distribution State
  transition : State → Action → Distribution State
  stageReward : State → Action → Distribution State → ℚ
  terminalReward : State → Distribution State → ℚ

/-- A stationary mixed policy for the single decision time. -/
abbrev Policy (State Action : Type*) [Fintype Action] :=
  State → Distribution Action

variable {State Action : Type*} [Fintype State] [Fintype Action]

/-- One closed-population update for any policy and stochastic transition
kernel. The proofs in `Distribution.bind` establish normalization of each
component of this actual update. -/
def update (m : Distribution State) (transition : State → Action → Distribution State)
    (π : Policy State Action) : Distribution State :=
  m.bind (fun s => (π s).bind (fun a => transition s a))

/-- Iterate the population update under an arbitrary sequence of policies. -/
def evolve (m₀ : Distribution State) (transition : State → Action → Distribution State)
    (π : ℕ → Policy State Action) : ℕ → Distribution State
  | 0 => m₀
  | n + 1 => update (evolve m₀ transition π n) transition (π n)

/-- The population's next-state law when all agents use `π`. -/
def inducedTerminal (G : Game State Action) (π : Policy State Action) :
    Distribution State :=
  update G.initial G.transition π

/-- One player's value of choosing action `a` in state `s`, against fixed
population distribution `m`. -/
def actionValue (G : Game State Action) (m : Distribution State)
    (s : State) (a : Action) : ℚ :=
  G.stageReward s a m +
    (G.transition s a).expect (fun s' => G.terminalReward s' m)

/-- Expected payoff for an individual's policy `π` while `m` is fixed. -/
def value (G : Game State Action) (π : Policy State Action)
    (m : Distribution State) : ℚ :=
  G.initial.expect (fun s => (π s).expect (actionValue G m s))

/-- Exact consistency is built into this equilibrium definition by evaluating
deviations against the distribution induced by the candidate policy. -/
def IsEquilibrium (G : Game State Action) (π : Policy State Action) : Prop :=
  ∀ π' : Policy State Action,
    value G π' (inducedTerminal G π) ≤ value G π (inducedTerminal G π)

/-- A nonnegative tolerance bounds every unilateral improvement. -/
def IsEpsilonEquilibrium (G : Game State Action) (π : Policy State Action)
    (ε : ℚ) : Prop :=
  0 ≤ ε ∧ ∀ π' : Policy State Action,
    value G π' (inducedTerminal G π) ≤ value G π (inducedTerminal G π) + ε

end LeanMFG.FiniteState
