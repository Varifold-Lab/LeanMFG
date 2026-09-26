import LeanMFG.Verification.Static.RockPaperScissors

namespace LeanMFG.RPS

/-- Everyone in the population plays Rock. -/
def allRock : Distribution := pure .Rock

/-- Population masses (Rock, Paper, Scissors) = (1/2, 3/10, 1/5). -/
def skew : Distribution :=
  ⟨1 / 2, 3 / 10, 1 / 5,
    by norm_num, by norm_num, by norm_num, by norm_num⟩

/-- Paper and Scissors have equal maximal reward; Paper wins the tie. -/
def paperScissorsTie : Distribution :=
  ⟨1 / 3, 2 / 3, 0,
    by norm_num, by norm_num, by norm_num, by norm_num⟩

-- The numerical zero-gain condition also identifies the unique population equilibrium.
example (m : Distribution) (h : exploitability m = 0) : m = uniform := by
  exact equilibrium_unique m ((exploitability_eq_zero_iff m).mp h)

-- These guards evaluate the actual algorithm during compilation.
#guard exploitability uniform == (0 : ℚ)
#guard bestResponse allRock == .Paper
#guard exploitability allRock == (1 : ℚ)
#guard bestResponse skew == .Paper
#guard exploitability skew == (3 / 10 : ℚ)
#guard checkEpsilonEquilibrium skew (3 / 10)
#guard !checkEpsilonEquilibrium skew (1 / 5)
#guard bestResponse uniform == .Rock
#guard bestResponse paperScissorsTie == .Paper
#guard !checkEpsilonEquilibrium uniform (-1)

end LeanMFG.RPS
