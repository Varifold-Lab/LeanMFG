# Static rock-paper-scissors

For a worked, visual explanation, open the
[standalone HTML guide](rock-paper-scissors.html) in a browser.

This Lean example is inspired by the static rock-paper-scissors mean field game
in Section 2.1, Example 2 of [*Learning in Mean Field Games: A Survey*](https://arxiv.org/abs/2205.12944).
It uses the everyday win/loss convention: a win earns 1, a loss earns -1, and a
tie earns 0. The survey displays the opposite cyclic reward signs, so the
formulas below are **not** a transcription of its payoff formulas.

The action set is Rock, Paper, Scissors. A distribution stores three rational
probabilities, proofs that each is nonnegative, and a proof that their sum is 1.
Both the representative player's strategy `p` and the population distribution
`m` use this type. The population remains fixed when the individual deviates:

`reward Rock m = m(Scissors) - m(Paper)`

`reward Paper m = m(Rock) - m(Scissors)`

`reward Scissors m = m(Paper) - m(Rock)`

`expectedReward p m = ∑ a, p(a) * reward a m`

Exact equilibrium means `expectedReward p m ≤ expectedReward m m` for every
rational mixed strategy `p`. An ε-equilibrium additionally requires `ε ≥ 0`
and allows the deviator to improve by at most `ε`. Population consistency is
exact in both definitions, since the representative strategy is `m`.

The executable `bestResponse` maximizes pure-action reward. Its tie order is
Rock, then Paper, then Scissors. `exploitability m` is that maximum minus
`expectedReward m m`. The Boolean checker accepts exactly when `ε ≥ 0` and
`exploitability m ≤ ε`. The Lean proofs show that this equals the quantified
ε-equilibrium definition, including all rational mixed deviations.

Run `lake build` to check the proofs and the executable `#guard` examples in
`LeanMFG/Examples/RockPaperScissors.lean`. They cover the uniform population,
all Rock, the distribution `(1/2, 3/10, 1/5)`, both ε thresholds, ties, and
negative ε. The uniform distribution is proved to be the unique exact
equilibrium among rational distributions.

This example certifies best responses and equilibria in a three-action static
game. It does not implement an iterative equilibrium solver or establish
convergence of an iteration, and it does not cover dynamic MFGs.
