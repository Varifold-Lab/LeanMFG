# Contributing to LeanMFG

LeanMFG welcomes focused models, proofs, algorithms, examples, documentation, and bug fixes.

## Getting started

Install [elan](https://github.com/leanprover/elan), then run `lake exe cache get` and `lake build` from the repository root. The repository pins Lean, mathlib, and FloatLib. Use the Node version in `.node-version` for documentation and Python 3.11+ for maintainer checks; the solvers themselves do not require Python.

## Organizing a change

Put definitions in `Model/`, mathematical results in `Theory/`, executable code in `Algorithm/`, proofs about programs and invariants in `Verification/`, and concrete cases in `Examples/`. Within a layer, use a setting such as `Static/`, `FiniteState/`, or `Continuous/`. See the [architecture guide](docs/app/docs/architecture/page.mdx).

The finite-horizon numerical layer lives in `LeanMFG/Computational/`, with environment, policy, scoring, solver, and tuning interfaces. Changes there must also pass `lake exe mfglib_check`. Keep numerical testing claims distinct from formal proofs. Preserve attribution for adapted implementations in `NOTICE`; the [numerical guide](docs/app/docs/computational/page.mdx) documents the pinned MFGLib comparisons and deliberate differences.

Reusable floating-point operations live in `LeanMFG/Numerical/`, with their proofs in `Verification/Numerical/` and executable guards in `Examples/Numerical/`. Record the format, rounding mode, reduction order, and finiteness conditions. Changing these requires revisiting the error proofs and MFGLib checks. The [numerical guide](docs/app/docs/numerical/page.mdx) states the current boundary.

State assumptions and the domain of quantification in theorem statements and documentation. Connect algorithm proofs to the executable definitions they certify. Use `#guard` for concrete executable examples; it does not replace a general proof. Please do not introduce `sorry`, `admit`, or new axioms to bypass a proof in library modules.

Keep documentation links and imports current when moving modules. The documentation source is in `docs/app/`; after editing MDX, run `npm ci` once in `docs/` and then `npm run build`. The documentation build checks source and internal links. Use the shared MDX components for source-derived declarations and runnable examples; the [documentation authoring guide](docs/app/docs/contributing/page.mdx) describes the conventions. A new application example should identify the agents, states, actions, population law, and objective, and should distinguish invariants from equilibrium conditions.

For implementations based on published algorithms or other libraries, cite the source and document assumptions, data representation, and deliberate differences. Update the [capability map](docs/app/docs/computational/page.mdx) only after the implementation and its claimed guarantees are checked.

## Proposing changes

Develop on a branch and submit a focused pull request. Include the mathematical or program claim, changed interfaces, check results, and assumptions. Keep code, examples, documentation, the [verification scope](docs/app/docs/verification/page.mdx), and [changelog](CHANGELOG.md) synchronized. Mark breaking API, theorem-hypothesis, toolchain, and numerical changes explicitly.

The **CI gate** requires library changes to pass Lean builds, the axiom audit, numerical reference checks, a fresh downstream installation, release metadata checks, and documentation checks. Documentation-only PRs build the library and documentation and run the documented Lean program; unchanged numerical executables and downstream installation are checked again on `main` and in release runs. The exact local commands are in the [verification guide](docs/app/docs/verification/page.mdx). `scripts/check_downstream.py` rebuilds the current working tree in a temporary Git-dependent project; it never commits this repository. CI installs the exact checked commit.

Merge only after the gate passes. Maintainers configure the required GitHub branch rules and publish fixed commits according to the [release guide](docs/app/docs/releases/page.mdx). A manual release-candidate run validates a proposed version without publishing it.

## License

The repository is licensed under [Apache License 2.0](LICENSE). Contributions intentionally submitted for inclusion are subject to its contribution terms, unless you explicitly state otherwise. Include required attribution for third-party material.
