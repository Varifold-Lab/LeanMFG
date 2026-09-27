# Contributing to LeanMFG

LeanMFG welcomes focused models, proofs, algorithms, examples, documentation, and bug fixes.

## Getting started

Install [elan](https://github.com/leanprover/elan), then run `lake exe cache get` and `lake build` from the repository root. The repository pins Lean, mathlib, and FloatLib. Use the Node version in `.node-version` for documentation and Python 3.11+ for maintainer checks; the solvers themselves do not require Python.

## Organizing a change

Put definitions in `Model/`, mathematical results in `Theory/`, executable code in `Algorithm/`, proofs about programs and invariants in `Verification/`, and concrete cases in `Examples/`. Within a layer, use a setting such as `Static/`, `FiniteState/`, or `Continuous/`. See the [architecture guide](docs/app/docs/architecture/page.mdx).

The native MFGLib port lives in `LeanMFG/Computational/`, with its general environment, policy, scoring, solver, and tuning interfaces. Changes there must also pass `lake exe mfglib_check`. Keep numerical testing claims distinct from formal proofs. Preserve the upstream attribution in `NOTICE`; the [port guide](docs/app/docs/computational/page.mdx) documents the pinned baseline and deliberate differences.

Reusable floating-point operations live in `LeanMFG/Numerical/`, with their proofs in `Verification/Numerical/` and executable guards in `Examples/Numerical/`. Record the format, rounding mode, reduction order, and finiteness conditions. Changing these requires revisiting the error proofs and MFGLib checks. The [numerical guide](docs/app/docs/numerical/page.mdx) states the current boundary.

State assumptions and the domain of quantification in theorem statements and documentation. Connect algorithm proofs to the executable definitions they certify. Use `#guard` for concrete executable examples; it does not replace a general proof. Please do not introduce `sorry`, `admit`, or new axioms to bypass a proof in library modules.

Keep documentation links and imports current when moving modules. The documentation source is in `docs/app/`; after editing MDX, run `npm ci` once in `docs/` and then `npm run build`. The documentation build checks links to Lean source files. A new application example should identify the agents, states, actions, population law, and objective, and should distinguish invariants from equilibrium conditions.

When adding a capability inspired by MFGLib, document which MFGLib concept it corresponds to, the assumptions and data representation used in Lean, and any deliberate difference. Update the [capability map](docs/app/docs/architecture/page.mdx) only after the implementation and its claimed guarantees are checked.

## Proposing changes

Develop on a branch and submit a focused pull request. Include the mathematical or program claim, changed interfaces, check results, and assumptions. Keep code, examples, documentation, the [verification scope](docs/app/docs/verification/page.mdx), and [changelog](CHANGELOG.md) synchronized. Mark breaking API, theorem-hypothesis, toolchain, and numerical changes explicitly.

The **CI gate** requires all Lean builds, the axiom audit, numerical reference checks, a fresh downstream installation, release metadata checks, and documentation checks to pass. The exact local commands are in the [verification guide](docs/app/docs/verification/page.mdx). `scripts/check_downstream.py` rebuilds the current working tree in a temporary Git-dependent project; it never commits this repository. CI installs the exact checked commit.

Merge only after the gate passes. Maintainers configure the required GitHub branch rules and publish fixed commits according to the [release guide](docs/app/docs/releases/page.mdx). A manual release-candidate run validates a proposed version without publishing it.

## License

The repository is licensed under [Apache License 2.0](LICENSE). Contributions intentionally submitted for inclusion are subject to its contribution terms, unless you explicitly state otherwise. Include required attribution for third-party material.
