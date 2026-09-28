# LeanMFG

[![Documentation](https://img.shields.io/badge/docs-LeanMFG-blue)](https://varifold-lab.github.io/LeanMFG/)
[![Release](https://img.shields.io/github/v/release/Varifold-Lab/LeanMFG)](https://github.com/Varifold-Lab/LeanMFG/releases/latest)

LeanMFG is a Lean 4 library for mean field games, covering mathematical models,
theory, algorithms, and formal verification.

## Version compatibility

LeanMFG has its own version number. Each release is tested with one pinned Lean
toolchain and dependency set:

| LeanMFG release | Lean | mathlib revision | FloatLib revision |
| --- | --- | --- | --- |
| [v0.1.0](https://github.com/Varifold-Lab/LeanMFG/releases/tag/v0.1.0) | `4.34.0` | [`5ed2965`](https://github.com/leanprover-community/mathlib4/commit/5ed2965256430c3649e86755f9576b54eca72435) | [`5f8218d`](https://github.com/lean-dojo/FloatLib/commit/5f8218dc571c01d6f8bd070c65bcd0de3a40b3c5) |

Use the selected release's `lean-toolchain` and locked dependencies together.
Release titles show both versions, for example **LeanMFG v0.1.0 — Lean 4.34.0**.
See the [version policy](https://varifold-lab.github.io/LeanMFG/docs/releases/#version-policy)
for toolchain upgrades and compatibility changes.

## Build

Install [elan](https://github.com/leanprover/elan), then build the `v0.1.0` release:

```sh
git clone --branch v0.1.0 https://github.com/Varifold-Lab/LeanMFG.git
cd LeanMFG
lake exe cache get
lake build
```

The Lean toolchain and dependencies are pinned in the repository.
Release notes, verification evidence, and versioned documentation are available
on the [release page](https://github.com/Varifold-Lab/LeanMFG/releases/tag/v0.1.0).
For ongoing development, check out `main` instead.
See the [documentation](https://varifold-lab.github.io/LeanMFG/) for usage and
[CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

## References

- Jean-Michel Lasry and Pierre-Louis Lions. [*Mean Field Games*](https://doi.org/10.1007/s11537-007-0657-8), 2007.
- Pierre Cardaliaguet. [*A Short Course on Mean Field Games*](https://www.ceremade.dauphine.fr/~cardaliaguet/MFGcours2018.pdf), 2018.
- Mathieu Laurière et al. [*Learning in Mean Field Games: A Survey*](https://arxiv.org/abs/2205.12944), 2022.
- Xin Guo et al. [*MFGLib: A Library for Mean-Field Games*](https://arxiv.org/abs/2304.08630), 2023. [Code](https://github.com/radar-research-lab/MFGLib).

Further references are listed in the [documentation](https://varifold-lab.github.io/LeanMFG/docs/references/).

## Development plans

- [From Chapter 3 to a computational MFG example](plans/chapter-3-computational-mfg.md):
  a staged proposal for distribution distances, particle simulation, and solver guarantees.
  See [tracking issue #7](https://github.com/Varifold-Lab/LeanMFG/issues/7) for tasks and contribution coordination.
