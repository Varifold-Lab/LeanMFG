import type { Metadata } from 'next'
import Link from 'next/link'

export const metadata: Metadata = {
  title: 'LeanMFG Documentation',
}

const cases = [
  {
    eyebrow: 'Static · rational',
    title: 'Rock · Paper · Scissors',
    summary: 'A complete finite game: executable best response, exact and approximate equilibrium certificates, and uniqueness.',
    href: '/docs/examples/rock-paper-scissors',
  },
  {
    eyebrow: 'Finite state · one step',
    title: 'Left / Right',
    summary: 'Policies, population updates, a certified best response, and conservation of probability mass.',
    href: '/docs/examples/finite-state-left-right',
  },
  {
    eyebrow: 'Continuous · deterministic',
    title: 'Classical HJB',
    summary: 'A smooth solution, verification theorem, and an explicit optimal feedback path.',
    href: '/docs/examples/hjb',
  },
]

export default function Home() {
  return (
    <main>
      <section className="home-hero">
        <div className="home-hero-inner">
          <p className="eyebrow">Formal methods for mean field games</p>
          <h1>From model to machine-checked guarantee.</h1>
          <p className="home-lede">
            LeanMFG builds a formal counterpart to MFGLib's MFG workflow and adds
            machine-checked theory and correctness proofs. Each result states the assumptions that make it true.
          </p>
          <div className="hero-actions">
            <Link className="button button-primary" href="/docs/computational">Run MFGLib in Lean <span aria-hidden="true">→</span></Link>
            <a className="button button-secondary" href="https://github.com/Varifold-Lab/LeanMFG">View source ↗</a>
          </div>
          <div className="proof-chain" aria-label="LeanMFG proof chain">
            <span>Model</span><b>→</b><span>Theory</span><b>→</b><span>Algorithm</span><b>→</b><span>Verification</span><b>→</b><span>Application constraints</span>
          </div>
        </div>
      </section>
      <section className="home-section">
        <p>The numerical library provides all ten MFGLib environments and five solver families. <Link href="/docs/computational">Read the port guide</Link> for tested coverage, backend differences, and the current proof boundary.</p>
        <div className="section-heading">
          <p className="eyebrow">Verified now</p>
          <h2>Start with a complete case</h2>
          <p>These cases have source modules and proofs today. The library is still in early development.</p>
        </div>
        <div className="case-grid">
          {cases.map((item) => (
            <Link className="case-card" href={item.href} key={item.href}>
              <span className="case-eyebrow">{item.eyebrow}</span>
              <h3>{item.title}</h3>
              <p>{item.summary}</p>
              <span className="case-arrow">Read the case →</span>
            </Link>
          ))}
        </div>
      </section>
    </main>
  )
}
