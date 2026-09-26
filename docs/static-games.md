# Finite static games

`LeanMFG.Model.Static.Basic` uses a finite action type, rational probabilities, and
rational rewards. A `Distribution Action` contains a probability function and
proofs that its entries are nonnegative and sum to one. The finite sums and
their algebraic properties come from mathlib. This representation keeps exact
evaluation executable; it is not mathlib's real-valued `PMF` representation.

A `Game Action` requires a nonempty action type and provides
`reward : Action → Distribution Action → ℚ`. Rewards may depend on the whole
population and need not be linear in that population.

For individual strategy `p` and population `m`, expected reward is
`∑ a, p.prob a * g.reward a m`. Deviations change only `p`. An equilibrium
requires every deviation's expected reward to be at most the reward from `m`
against itself. An ε-equilibrium additionally permits a nonnegative tolerance
ε; a negative tolerance is rejected by definition.

The model proves that pure-action bounds imply mixed-strategy bounds, that
checking all pure deviations characterizes equilibrium, and that zero-tolerance
equilibrium is exact equilibrium. It does not yet select a best response or
provide a general executable equilibrium checker, and does not assert existence
of rational equilibria.

## RPS compatibility

`LeanMFG.Model.Static.RockPaperScissorsAdapter` defines `RPS.staticGame` and conversions
`RPS.Distribution.toStatic` and `RPS.Distribution.ofStatic`. Both round trips
are proved to be identities. Expected rewards agree, and
`RPS.isEquilibrium_iff_static` and `RPS.isEpsilonEquilibrium_iff_static` transfer
the original predicates in both directions. Existing RPS algorithms keep their
current tie-breaking rules; generic best-response selection is a later step.

## Examples and validation

`LeanMFG.Examples.Static.Congestion` proves that the balanced population in a two-action
congestion game is an equilibrium and that a concentrated population is not.
It also checks a single-action game with negative rewards, exclusion of negative
ε, and the original RPS uniform equilibrium through the adapter. `#guard` checks
evaluate concrete expected rewards using exact rational arithmetic.

Run `lake build` to check all modules, including these examples and the existing
HJB development. The library's `warningAsError` setting rejects `sorry` warnings.
The GitHub workflow uses [Lean Action](https://github.com/leanprover/lean-action)
to obtain the pinned environment, fetch the mathlib cache, and build the library.
Remote workflow success must be checked after pushing; adding this file does not
configure branch protection.
