export const documentation = [
  {
    title: 'Start',
    items: [
      { title: 'Overview', href: '/' },
      { title: 'Getting started', href: '/docs/getting-started' },
      { title: 'Architecture', href: '/docs/architecture' },
      { title: 'MFGLib in Lean', href: '/docs/computational' },
    ],
  },
  {
    title: 'Library layers',
    items: [
      { title: 'Model', href: '/docs/model' },
      { title: 'Theory', href: '/docs/theory' },
      { title: 'Algorithm', href: '/docs/algorithm' },
      { title: 'Numerical foundation', href: '/docs/numerical' },
      { title: 'Verification', href: '/docs/verification' },
    ],
  },
  {
    title: 'Worked cases',
    items: [
      { title: 'Rock · Paper · Scissors', href: '/docs/examples/rock-paper-scissors' },
      { title: 'Finite-state Left/Right', href: '/docs/examples/finite-state-left-right' },
      { title: 'Classical HJB', href: '/docs/examples/hjb' },
      { title: 'Numerical population update', href: '/docs/numerical/population' },
    ],
  },
  {
    title: 'Project',
    items: [
      { title: 'Development and releases', href: '/docs/releases' },
      { title: 'References', href: '/docs/references' },
    ],
  },
] as const
