# Contributing to LeanMFG

LeanMFG welcomes focused models, proofs, algorithms, examples, documentation, and bug fixes.

## Getting started

Install [elan](https://github.com/leanprover/elan), then run `lake exe cache get` and `lake build` from the repository root. The repository pins its Lean toolchain and mathlib revision. Please run `lake build` before proposing a change.

## Organizing a change

Put definitions in `Model/`, mathematical results in `Theory/`, executable code in `Algorithm/`, proofs about programs and invariants in `Verification/`, and concrete cases in `Examples/`. Within a layer, use a setting such as `Static/`, `FiniteState/`, or `Continuous/`. See the [architecture guide](docs/app/docs/architecture/page.mdx).

State assumptions and the domain of quantification in theorem statements and documentation. Connect algorithm proofs to the executable definitions they certify. Use `#guard` for concrete executable examples; it does not replace a general proof. Please do not introduce `sorry`, `admit`, or new axioms to bypass a proof in library modules.

Keep documentation links and imports current when moving modules. The documentation source is in `docs/app/`; after editing MDX, run `npm ci` once in `docs/` and then `npm run build`. The documentation build checks links to Lean source files. A new application example should identify the agents, states, actions, population law, and objective, and should distinguish invariants from equilibrium conditions.

## Proposing changes

Open an issue to discuss a broad design change, or submit a pull request for a focused change. Include a short description of the mathematical claim, the Lean modules changed, and the result of `lake build`. Report any assumptions or limitations that a reader might otherwise miss.

## License

The repository is licensed under [Apache License 2.0](LICENSE). Contributions intentionally submitted for inclusion are subject to its contribution terms, unless you explicitly state otherwise. Include required attribution for third-party material.
