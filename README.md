# LeanMFG

[![Documentation](https://img.shields.io/badge/docs-LeanMFG-blue)](https://varifold-lab.github.io/LeanMFG/)
[![Release](https://img.shields.io/github/v/release/Varifold-Lab/LeanMFG)](https://github.com/Varifold-Lab/LeanMFG/releases/latest)

LeanMFG is a Lean 4 library for mean field games, covering mathematical models,
theory, algorithms, and formal verification.

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
