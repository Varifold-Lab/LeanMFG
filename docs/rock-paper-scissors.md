# Static rock-paper-scissors

For a worked visual explanation, open the
[standalone HTML guide](rock-paper-scissors.html) in a browser.

This Lean example is inspired by the static rock-paper-scissors mean field game
in §2.1, Example 2 of
[*Learning in Mean Field Games: A Survey*](https://arxiv.org/abs/2205.12944).
We use the everyday convention: a win earns $1$, a loss earns $-1$, and a tie
earns $0$. The survey displays the opposite cyclic reward signs, so the
formulas here are **not** transcribed from its payoff formulas.

## Model

The action set is $A=\{R,P,S\}$. A distribution stores rational probabilities
with proof fields enforcing

$$
m_R,m_P,m_S\in\mathbb{Q}_{\geq 0},
\qquad m_R+m_P+m_S=1.
$$

The representative player's mixed strategy $p$ and the population distribution
$m$ have the same type but distinct roles. When one player deviates, $p$ changes
while $m$ stays fixed. The pure-action rewards are

$$
\begin{aligned}
r(R,m)&=m_S-m_P,\\
r(P,m)&=m_R-m_S,\\
r(S,m)&=m_P-m_R.
\end{aligned}
$$

The player's expected reward is the finite sum

$$
J(p;m)=\sum_{a\in A}p_a\,r(a,m).
$$

An exact equilibrium satisfies

$$
\forall p,\quad J(p;m)\leq J(m;m).
$$

An $\varepsilon$-equilibrium requires $\varepsilon\geq 0$ and

$$
\forall p,\quad J(p;m)\leq J(m;m)+\varepsilon.
$$

The quantifier ranges over **rational** mixed strategies. Population
consistency is exact in both definitions because the representative strategy
being certified is $m$ itself.

## Algorithm and proofs

The executable bestResponse compares the three pure rewards and returns a
maximizer; ties favor Rock, then Paper, then Scissors. Exploitability is

$$
\operatorname{exploitability}(m)
=r(\operatorname{bestResponse}(m),m)-J(m;m).
$$

The Boolean checkEpsilonEquilibrium accepts exactly when $\varepsilon\geq 0$
and $\operatorname{exploitability}(m)\leq\varepsilon$. Lean proves that
bestResponse maximizes reward over pure actions, that no rational mixed
strategy beats it, that exploitability is nonnegative, and that the Boolean
check is equivalent to the quantified $\varepsilon$-equilibrium definition.
Lean also proves that $(1/3,1/3,1/3)$ is the unique exact equilibrium.

The theorem `exploitability_eq_zero_iff` connects the numerical gain directly
to exact equilibrium:

```lean
exploitability m = 0 ↔ IsEquilibrium m
```

In the forward direction, every mixed strategy earns at most the best-response
reward. If that best response gains zero over the population strategy, no
unilateral deviation can improve the reward. In the reverse direction, an
equilibrium rules out improvement even by the pure best response, so
exploitability is at most zero. Its nonnegativity then gives equality.
The population distribution `m` stays fixed in both directions; only the
representative player's strategy changes.

Combining this equivalence with `equilibrium_unique` shows that any population
with zero exploitability must be `uniform`. The example module includes this
use of the theorem.

Run **lake build** to verify these proofs and the executable checks in
[the example module](../LeanMFG/Examples/RockPaperScissors.lean). They cover
the uniform population (exploitability $0$), all Rock (best response Paper,
exploitability $1$), and $(1/2,3/10,1/5)$ (best response Paper,
exploitability $3/10$). The last distribution is accepted at
$\varepsilon=3/10$ and rejected at $\varepsilon=1/5$. Further checks cover
ties and negative $\varepsilon$.

This example certifies best responses and equilibria in a three-action static
game. It does not implement an iterative equilibrium solver, prove iteration
convergence, or cover dynamic MFGs.
