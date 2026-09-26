# LeanMFG

**Mean field games in Lean 4: models, mathematics, executable algorithms, and verified examples.**

LeanMFG connects these layers through a proof chain:

> Model definitions → mathematical properties → algorithms → algorithm guarantees → application constraints.

The library is in early development. Its current cases are a [static rock-paper-scissors game](docs/app/docs/examples/rock-paper-scissors/page.mdx), a [one-step finite-state game](docs/app/docs/examples/finite-state-left-right/page.mdx) with a mass-conserving population update, and a [classical HJB verification example](docs/app/docs/examples/hjb/page.mdx) for deterministic control. These examples establish specific results under stated assumptions; they do not yet form a general MFG solver.

## Build

Install [elan](https://github.com/leanprover/elan), then run:

```sh
lake exe cache get
lake build
```

The Lean toolchain and mathlib revision are pinned in this repository. `lake build` checks the proofs and executable `#guard` examples.

## Documentation

The official documentation is a Next.js + MDX site in `docs/`:

```sh
cd docs
npm ci
npm run dev
```

Open `http://localhost:3000`. Run `npm run build` to check the pages and produce a static site. The [architecture](docs/app/docs/architecture/page.mdx) and [references](docs/app/docs/references/page.mdx) are maintained there.

Contributions are welcome; see [CONTRIBUTING.md](CONTRIBUTING.md). LeanMFG is licensed under [Apache-2.0](LICENSE).
