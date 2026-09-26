import LeanMFG.Model.RockPaperScissors

namespace LeanMFG.RPS

/-- Antisymmetry makes self-play have expected reward zero. -/
theorem expectedReward_self (m : Distribution) :
    expectedReward m m = 0 := by
  simp only [expectedReward, reward]
  ring

theorem uniform_equilibrium : IsEquilibrium uniform := by
  intro p
  simp [expectedReward, reward, uniform]

/-- The symmetric distribution is the only rational equilibrium. -/
theorem equilibrium_unique (m : Distribution) (hm : IsEquilibrium m) :
    m = uniform := by
  have hrock : reward .Rock m ≤ 0 := by
    have h := hm (pure .Rock)
    simpa [expectedReward_self] using h
  have hpaper : reward .Paper m ≤ 0 := by
    have h := hm (pure .Paper)
    simpa [expectedReward_self] using h
  have hscissors : reward .Scissors m ≤ 0 := by
    have h := hm (pure .Scissors)
    simpa [expectedReward_self] using h
  have hsum : reward .Rock m + reward .Paper m + reward .Scissors m = 0 := by
    simp only [reward]
    ring
  have hr : m.rock = 1 / 3 := by
    dsimp [reward] at hrock hpaper hscissors hsum
    linarith [m.sum_eq_one]
  have hp : m.paper = 1 / 3 := by
    dsimp [reward] at hrock hpaper hscissors hsum
    linarith [m.sum_eq_one]
  have hs : m.scissors = 1 / 3 := by
    dsimp [reward] at hrock hpaper hscissors hsum
    linarith [m.sum_eq_one]
  cases m with
  | mk r p s hnr hnp hns htotal =>
    dsimp at hr hp hs
    subst r
    subst p
    subst s
    rfl

end LeanMFG.RPS
