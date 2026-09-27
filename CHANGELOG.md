# Changelog

User-visible changes are recorded here before merge. An entry under Unreleased
is not a published release. The package currently prepares its first `0.1.0` release.

## [Unreleased]

### Added

- Automatic GitHub Pages publication of the MDX documentation from `main`.
- General rational finite static games with pure-deviation equilibrium
  characterization, a proved RPS adapter, and congestion/single-action examples.

- General finite-horizon MFGLib workflow: all ten environments, five solver
  families, population evolution, Bellman recursion, exploitability, tuning,
  JSON configuration, and the `mfglib` command.
- Pinned MFGLib reference fixtures and `mfglib_check`: 358 vectors, 43,352
  scalar comparisons, and additional edge/integration checks.
- Rational static rock-paper-scissors and one-step Left/Right examples, with
  equilibrium and mass-conservation proofs; a classical deterministic HJB
  verification theorem and worked control problem.
- FloatLib binary64 sums and dot products with rounding-error proofs, plus a
  checked population update with coordinate, L1, mass-drift, and input-error bounds.
- Next.js/MDX documentation, source links, and explicit verification scope.
- PR checks, an axiom-policy gate, a fresh external Git-installation test,
  version consistency checks, and a candidate/tag release workflow. Release
  documentation and evidence carry the same source commit.

### Changed

- Documentation now includes a runnable solver tutorial, source-derived API
  signatures, local search, copyable code, keyboard-accessible installation
  tabs, and page contents navigation.
- Lean moves from `4.34.0-rc2` to `4.34.0`; mathlib is pinned to
  `5ed2965256430c3649e86755f9576b54eca72435` and FloatLib to
  `5f8218dc571c01d6f8bd070c65bcd0de3a40b3c5`.
- Shared numerical reductions use FloatLib's explicit nearest-even operations.
  The solver's population update now rejects invalid dimensions or nonfinite
  intermediate arithmetic through the checked forward kernel.
- Release procedures and verification scope are maintained in the official MDX
  documentation; third-party license texts and attribution are collected in `NOTICE`.

### Fixed

- MDX internal links honor the GitHub Pages `/LeanMFG` base path.
- JSON serialization preserves finite binary64 values and small tolerances.
- The Lean port handles multidimensional Fictitious Play action rows and uses
  the represented population for custom MFOMO log-coordinate initialization.
- Existing Left/Right proofs are adjusted for the pinned mathlib upgrade.

### Compatibility and limitations

- Downstream projects must use the pinned Lean toolchain and compatible
  dependency revisions. No stable API or compatibility with the earlier rc2
  toolchain is promised for this initial release candidate.
- The numerical backend uses CPU binary64 arrays. GPU execution, arbitrary
  PyTorch optimizers, and Optuna persistence/TPE are not implemented. OMI uses
  a native Dykstra projection rather than OSQP.
- The numerical checks do not prove whole-solver correctness or convergence.
  Local error budgets are mathematical bounds, not executable interval certificates.
  See the [verification guide](docs/app/docs/verification/page.mdx) for the precise coverage.
