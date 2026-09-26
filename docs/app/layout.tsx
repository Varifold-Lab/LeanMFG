import type { Metadata } from 'next'
import Link from 'next/link'
import 'katex/dist/katex.min.css'
import './globals.css'

export const metadata: Metadata = {
  title: {
    default: 'LeanMFG Documentation',
    template: '%s · LeanMFG',
  },
  description:
    'Mean field games in Lean 4: models, mathematical theory, executable algorithms, and machine-checked verification.',
}

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>
        <header className="site-header">
          <div className="header-inner">
            <Link className="brand" href="/" aria-label="LeanMFG documentation home">
              <span className="brand-mark" aria-hidden="true">λ</span>
              <span>LeanMFG</span>
              <span className="brand-suffix">/ docs</span>
            </Link>
            <div className="header-links">
              <Link href="/docs/architecture">Documentation</Link>
              <a href="https://github.com/Varifold-Lab/LeanMFG">GitHub ↗</a>
            </div>
          </div>
        </header>
        {children}
        <footer className="site-footer">
          <span>LeanMFG · Machine-checked mean field games</span>
          <a href="https://github.com/Varifold-Lab/LeanMFG/blob/main/LICENSE">Apache-2.0</a>
        </footer>
      </body>
    </html>
  )
}
