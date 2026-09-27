# LeanMFG

**A Lean 4 counterpart to MFGLib's MFG workflow, extended with mathematical theory and verified algorithms.**

LeanMFG uses [MFGLib](https://github.com/radar-research-lab/MFGLib) as the functional baseline for finite MFGs: environments, policies, population evolution, scoring, solvers, and examples. LeanMFG adds formal definitions and proofs of mathematical properties, program correctness, and model invariants. The intended chain is:

> Model definitions → mathematical properties → algorithms → algorithm guarantees → application constraints.

The [native MFGLib port](docs/app/docs/computational/page.mdx) implements the general finite-horizon model, all ten environments, five solver families, scoring, and native tuning. It is checked against a pinned upstream version. [FloatLib-backed reductions](docs/app/docs/numerical/page.mdx) and [one-step population updates](docs/app/docs/numerical/population/page.mdx) have proved error bounds; whole-solver correctness remains future work. Other proved cases cover static rock-paper-scissors, a rational one-step Left/Right game, and classical HJB verification.

The [finite static model](docs/app/docs/model/static/page.mdx) supports any finite nonempty action type with rational probabilities and rewards. It includes a proved RPS adapter and congestion and single-action examples.

## Build

Install [elan](https://github.com/leanprover/elan), then run:

```sh
lake exe cache get
lake build
lake exe mfglib_check
lake exe mfglib left_right omd 20
```

Lean 4.34.0, mathlib, and FloatLib revisions are pinned. `lake build` checks the proofs and executable examples; `mfglib_check` checks numerical reference data and edge cases without Python.

To use LeanMFG from another Lake project, follow the [installation guide](docs/app/docs/getting-started/page.mdx). Pin a source commit and use its Lean toolchain and dependency revisions.

Library warnings are treated as errors, including unfinished proofs using `sorry`. The [Lean workflow](.github/workflows/lean.yml) checks pushes and pull requests using the pinned toolchain and dependencies.

## Documentation

Read the **[official documentation](https://varifold-lab.github.io/LeanMFG/)**.
The site is built from `main` and published automatically through GitHub Pages.

The Next.js + MDX source is in `docs/`. Use the Node version in `.node-version`:

```sh
cd docs
npm ci
npm run dev
```

Open `http://localhost:3000`. Run `npm run build` to check the pages and produce a static site. The [architecture](docs/app/docs/architecture/page.mdx) and [references](docs/app/docs/references/page.mdx) are maintained there.

## Checks and releases

PR checks cover Lean builds, axiom auditing, numerical reference tests, external installation, and documentation. See [verification scope](docs/app/docs/verification/page.mdx) for implemented, tested, and proved capabilities. [CHANGELOG.md](CHANGELOG.md) records changes; the [release guide](docs/app/docs/releases/page.mdx) describes candidate checks and publication from a fixed commit.

Contributions are welcome; see [CONTRIBUTING.md](CONTRIBUTING.md). LeanMFG is licensed under [Apache-2.0](LICENSE), with [third-party notices](NOTICE) for adapted material.
