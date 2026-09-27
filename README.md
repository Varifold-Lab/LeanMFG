# LeanMFG

[![Documentation](https://img.shields.io/badge/docs-LeanMFG-blue)](https://varifold-lab.github.io/LeanMFG/)

LeanMFG is a Lean 4 library for mean field games, covering mathematical models,
theory, algorithms, and formal verification.

## Build

Install [elan](https://github.com/leanprover/elan), then run:

```sh
git clone https://github.com/Varifold-Lab/LeanMFG.git
cd LeanMFG
lake exe cache get
lake build
```

The Lean toolchain and dependencies are pinned in the repository.
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
