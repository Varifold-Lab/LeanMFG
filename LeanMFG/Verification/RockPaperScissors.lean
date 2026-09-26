import LeanMFG.Algorithm.RockPaperScissors
import LeanMFG.Theory.RockPaperScissors

namespace LeanMFG.RPS

/-- Correctness of the executable, tie-breaking best-response procedure. -/
theorem reward_le_bestResponse (m : Distribution) (a : Action) :
    reward a m ≤ reward (bestResponse m) m := by
  unfold bestResponse
  split_ifs with hPR hSP hSR <;> cases a <;> simp_all <;> linarith

/-- No rational mixed strategy beats the action selected by the program. -/
theorem expectedReward_le_bestResponse (p m : Distribution) :
    expectedReward p m ≤ reward (bestResponse m) m := by
  let r := reward (bestResponse m) m
  have hR := mul_nonneg p.rock_nonneg
    (sub_nonneg.mpr (reward_le_bestResponse m .Rock))
  have hP := mul_nonneg p.paper_nonneg
    (sub_nonneg.mpr (reward_le_bestResponse m .Paper))
  have hS := mul_nonneg p.scissors_nonneg
    (sub_nonneg.mpr (reward_le_bestResponse m .Scissors))
  have hsum := congrArg (fun q : ℚ => q * r) p.sum_eq_one
  dsimp [expectedReward, r] at *
  nlinarith

theorem exploitability_nonneg (m : Distribution) :
    0 ≤ exploitability m := by
  unfold exploitability
  linarith [expectedReward_le_bestResponse m m]

/-- The executable Boolean result agrees exactly with rational ε-equilibrium. -/
theorem checkEpsilonEquilibrium_iff (m : Distribution) (ε : ℚ) :
    checkEpsilonEquilibrium m ε = true ↔ IsEpsilonEquilibrium m ε := by
  change (decide (0 ≤ ε ∧ exploitability m ≤ ε) = true) ↔
    (0 ≤ ε ∧ ∀ p : Distribution,
      expectedReward p m ≤ expectedReward m m + ε)
  rw [decide_eq_true_eq]
  constructor
  · rintro ⟨hε, hbound⟩
    refine ⟨hε, ?_⟩
    intro p
    have hp := expectedReward_le_bestResponse p m
    dsimp [exploitability] at hbound
    linarith
  · rintro ⟨hε, hall⟩
    refine ⟨hε, ?_⟩
    have hb := hall (pure (bestResponse m))
    simp only [expectedReward_pure] at hb
    dsimp [exploitability]
    linarith

end LeanMFG.RPS
