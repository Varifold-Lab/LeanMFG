import LeanMFG.Model.Continuous.DeterministicControl
import Mathlib.Analysis.Calculus.ContDiff.Operations
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Tactic

/-!
# A classical HJB solution for deterministic control

For the running cost `a² / 2 + F(t, x)` and dynamics `x' = a`, the
minimizing Hamiltonian is `F(t, x) - (∂ₓu)² / 2`. The HJB equation is

`∂ₜu - (∂ₓu)² / 2 + F = 0`, with terminal condition `u(1, x) = g(x)`.

This file only states the equation and checks an explicit smooth solution.
The connection to optimal costs requires a separate verification theorem.
-/

namespace LeanMFG.ContinuousControl.HJB

open Set

/-- A jointly `C¹` value candidate with certified partial derivatives,
satisfying the HJB equation and terminal condition on the time interval.
The functions are defined on all of `ℝ` so ordinary two-sided derivatives
are available at the interval endpoints. -/
structure ClassicalSolution (P : Problem) where
  value : ℝ → ℝ → ℝ
  timeDerivative : ℝ → ℝ → ℝ
  spaceDerivative : ℝ → ℝ → ℝ
  smooth : ∀ t ∈ Icc (0 : ℝ) 1, ∀ x : ℝ,
    ContDiffAt ℝ 1 (fun z : ℝ × ℝ => value z.1 z.2) (t, x)
  hasTimeDerivative : ∀ t ∈ Icc (0 : ℝ) 1, ∀ x : ℝ,
    HasDerivAt (fun s => value s x) (timeDerivative t x) t
  hasSpaceDerivative : ∀ t ∈ Icc (0 : ℝ) 1, ∀ x : ℝ,
    HasDerivAt (fun y => value t y) (spaceDerivative t x) x
  equation : ∀ t ∈ Icc (0 : ℝ) 1, ∀ x : ℝ,
    timeDerivative t x - (spaceDerivative t x) ^ 2 / 2 + P.potential t x = 0
  terminal : ∀ x : ℝ, value 1 x = P.terminalCost x

/-- The zero-potential problem with quadratic terminal cost. -/
noncomputable def quadraticProblem : Problem where
  potential := fun _ _ => 0
  terminalCost := fun x => x ^ 2 / 2

/-- Explicit solution for the quadratic problem, on the time slab `0 ≤ t ≤ 1`. -/
noncomputable def quadraticValue (t x : ℝ) : ℝ :=
  x ^ 2 / (2 * (2 - t))

private theorem two_sub_ne_zero {t : ℝ} (ht : t ≤ 1) : 2 - t ≠ 0 := by
  linarith

private theorem quadratic_smooth (t : ℝ) (ht : t ∈ Icc (0 : ℝ) 1) (x : ℝ) :
    ContDiffAt ℝ 1 (fun z : ℝ × ℝ => quadraticValue z.1 z.2) (t, x) := by
  unfold quadraticValue
  have h : (2 : ℝ) * (2 - t) ≠ 0 := mul_ne_zero (by norm_num) (two_sub_ne_zero ht.2)
  fun_prop

private theorem quadratic_time_deriv (t : ℝ) (ht : t ∈ Icc (0 : ℝ) 1) (x : ℝ) :
    HasDerivAt (fun s => quadraticValue s x) (x ^ 2 / (2 * (2 - t) ^ 2)) t := by
  unfold quadraticValue
  have h : (2 : ℝ) * (2 - t) ≠ 0 := mul_ne_zero (by norm_num) (two_sub_ne_zero ht.2)
  have hc : HasDerivAt (fun _ : ℝ => x ^ 2) 0 t := hasDerivAt_const t _
  have hsub : HasDerivAt (fun s : ℝ => 2 - s) (-1) t := by
    exact (hasDerivAt_id t).const_sub 2
  have hd : HasDerivAt (fun s : ℝ => 2 * (2 - s)) (-2) t := by
    simpa using HasDerivAt.const_mul 2 hsub
  have hdiv := hc.fun_div hd h
  have heq : (0 * (2 * (2 - t)) - x ^ 2 * (-2)) / (2 * (2 - t)) ^ 2 =
      x ^ 2 / (2 * (2 - t) ^ 2) := by
    field_simp [two_sub_ne_zero ht.2]
    ring
  rw [heq] at hdiv
  exact hdiv

private theorem quadratic_space_deriv (t : ℝ) (ht : t ∈ Icc (0 : ℝ) 1) (x : ℝ) :
    HasDerivAt (fun y => quadraticValue t y) (x / (2 - t)) x := by
  unfold quadraticValue
  have hp : HasDerivAt (fun y : ℝ => y ^ 2) (2 * x) x := by
    simpa using hasDerivAt_pow 2 x
  have hq := hp.div_const (2 * (2 - t))
  have heq : (2 * x) / (2 * (2 - t)) = x / (2 - t) := by
    field_simp [two_sub_ne_zero ht.2]
  rw [heq] at hq
  exact hq

/-- The quadratic candidate is a classical solution of the HJB equation.
This is an equation check; optimality is not asserted here. -/
noncomputable def quadraticClassicalSolution : ClassicalSolution quadraticProblem where
  value := quadraticValue
  timeDerivative := fun t x => x ^ 2 / (2 * (2 - t) ^ 2)
  spaceDerivative := fun t x => x / (2 - t)
  smooth := quadratic_smooth
  hasTimeDerivative := quadratic_time_deriv
  hasSpaceDerivative := quadratic_space_deriv
  equation := by
    intro t ht x
    have h := two_sub_ne_zero ht.2
    simp only [quadraticProblem]
    field_simp
    ring
  terminal := by
    intro x
    norm_num [quadraticValue, quadraticProblem]

/-- The explicit function satisfies the HJB equation throughout the time slab. -/
theorem quadraticValue_hjb (t : ℝ) (ht : t ∈ Icc (0 : ℝ) 1) (x : ℝ) :
    x ^ 2 / (2 * (2 - t) ^ 2) - (x / (2 - t)) ^ 2 / 2 +
      quadraticProblem.potential t x = 0 :=
  quadraticClassicalSolution.equation t ht x

/-- The explicit function has the prescribed terminal value. -/
theorem quadraticValue_terminal (x : ℝ) :
    quadraticValue 1 x = quadraticProblem.terminalCost x :=
  quadraticClassicalSolution.terminal x

end LeanMFG.ContinuousControl.HJB
