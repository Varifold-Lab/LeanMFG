export const documentation = [
  { title: 'Getting started', items: [
    { title: 'Overview', href: '/' },
    { title: 'Installation', href: '/docs/getting-started' },
    { title: 'First solver', href: '/docs/quickstart' },
  ] },
  { title: 'Using LeanMFG', items: [
    { title: 'Finite-horizon games', href: '/docs/computational' },
    { title: 'Solver API', href: '/docs/reference' },
    { title: 'Mathematical models', href: '/docs/model' },
    { title: 'Theorems', href: '/docs/theory' },
    { title: 'Best responses and checkers', href: '/docs/algorithm' },
    { title: 'Floating-point arithmetic', href: '/docs/numerical' },
  ] },
  { title: 'Examples', items: [
    { title: 'Rock-paper-scissors', href: '/docs/examples/rock-paper-scissors' },
    { title: 'Finite static games', href: '/docs/model/static' },
    { title: 'Left/Right', href: '/docs/examples/finite-state-left-right' },
    { title: 'Classical HJB', href: '/docs/examples/hjb' },
    { title: 'Population error bounds', href: '/docs/numerical/population' },
  ] },
  { title: 'Development', items: [
    { title: 'Community', href: '/docs/community' },
    { title: 'Module organization', href: '/docs/architecture' },
    { title: 'Verification and tests', href: '/docs/verification' },
    { title: 'Contributing', href: '/docs/contributing' },
    { title: 'Releases', href: '/docs/releases' },
    { title: 'References', href: '/docs/references' },
  ] },
] as const
