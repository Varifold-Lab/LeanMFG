# LeanMFG

**Mean field games: formal theory and verified algorithms in Lean 4.**

LeanMFG aims to formalize the mathematics of mean field games and connect executable algorithms with machine-checked proofs. Its scope includes models, equilibrium concepts, and the correctness and convergence of numerical methods.

The project is in early development. The Lean project builds on mathlib and
currently contains module boundaries but no formalized MFG results yet.

## Quick start

Install [elan](https://github.com/leanprover/elan), then run:

```sh
lake build
```

The Lean version and mathlib revision are pinned in `lean-toolchain` and
`lakefile.toml`.

## Code organization

The layout follows the separation of models, algorithms, and proofs used by
[LeanSort](https://github.com/Varifold-Lab/LeanSort), with a separate layer for
mathematical MFG theory:

| Directory | Responsibility |
| --- | --- |
| `LeanMFG/Model/` | Shared definitions: games, strategies, distributions, and equilibria |
| `LeanMFG/Theory/` | Mathematical results such as existence and uniqueness |
| `LeanMFG/Algorithm/` | Executable solvers and numerical methods |
| `LeanMFG/Verification/` | Algorithm correctness and convergence proofs |

`LeanMFG.lean` imports every current module. New modules should be imported
there so `lake build` checks the whole library. The `Basic.lean` files mark
module boundaries; their comments describe intended scope, not established
theorems. Concrete modules should import the mathlib files they need directly.

## References

- Pierre Cardaliaguet. [*A Short Course on Mean Field Games*](https://www.ceremade.dauphine.fr/~cardaliaguet/MFGcours2018.pdf). March 31, 2018.
- Jean-Michel Lasry and Pierre-Louis Lions. [*Mean Field Games*](https://doi.org/10.1007/s11537-007-0657-8). Japanese Journal of Mathematics, 2, 229–260, 2007.
- René Carmona and François Delarue. [*Probabilistic Theory of Mean Field Games with Applications I: Mean Field FBSDEs, Control, and Games*](https://doi.org/10.1007/978-3-319-58920-6). Springer, 2018.
- Yves Achdou and Italo Capuzzo-Dolcetta. [*Mean Field Games: Numerical Methods*](https://doi.org/10.1137/090758477). SIAM Journal on Numerical Analysis, 48(3), 1136–1162, 2010.
- Saeed Hadikhanloo and Francisco J. Silva. [*Finite Mean Field Games: Fictitious Play and Convergence to a First Order Continuous Mean Field Game*](https://arxiv.org/abs/1805.05940). Journal de Mathématiques Pures et Appliquées, 132, 369–397, 2019.
- Mathieu Laurière et al. [*Learning in Mean Field Games: A Survey*](https://arxiv.org/abs/2205.12944). arXiv:2205.12944, 2022.
