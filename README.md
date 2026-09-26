# LeanMFG

**Mean field games in Lean 4: models, mathematics, executable algorithms, and verified examples.**

LeanMFG connects these layers through a proof chain:

> Model definitions → mathematical properties → algorithms → algorithm guarantees → application constraints.

The library is in early development. Its current cases are a [static rock-paper-scissors game](docs/app/docs/examples/rock-paper-scissors/page.mdx), a [one-step finite-state game](docs/app/docs/examples/finite-state-left-right/page.mdx) with a mass-conserving population update, and a [classical HJB verification example](docs/app/docs/examples/hjb/page.mdx) for deterministic control. These examples establish specific results under stated assumptions; they do not yet form a general MFG solver.

The [finite static model](LeanMFG/Model/Static/Basic.lean) defines rational distributions, population-dependent rewards, and exact and approximate equilibria for any finite nonempty action type. The [RPS adapter](LeanMFG/Model/Static/RockPaperScissorsAdapter.lean) proves agreement with the original equilibrium definitions. [Additional examples](LeanMFG/Examples/Static/Congestion.lean) cover congestion and a single-action game; see the [static model guide](docs/static-games.md).

## Build

Install [elan](https://github.com/leanprover/elan), then run:

```sh
lake exe cache get
lake build
```

The Lean toolchain and mathlib revision are pinned in this repository. `lake build` checks the proofs and executable `#guard` examples.

Library warnings are treated as errors, including unfinished proofs using `sorry`. The [Lean workflow](.github/workflows/lean.yml) checks pushes and pull requests using the pinned toolchain and dependencies.

## Documentation

The official documentation is a Next.js + MDX site in `docs/`:

```sh
cd docs
npm ci
npm run dev
```

Open `http://localhost:3000`. Run `npm run build` to check the pages and produce a static site. The [architecture](docs/app/docs/architecture/page.mdx) and [references](docs/app/docs/references/page.mdx) are maintained there.

Contributions are welcome; see [CONTRIBUTING.md](CONTRIBUTING.md). LeanMFG is licensed under [Apache-2.0](LICENSE).
