import type { Metadata } from 'next'
import Link from 'next/link'
import buildInfo from '@/lib/build-info.json'
import { DocSearch } from '@/components/DocSearch'
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
        <a className="skip-link" href="#main-content">Skip to content</a>
        <header className="site-header">
          <div className="header-inner">
            <Link className="brand" href="/" aria-label="LeanMFG documentation home">
              <span>LeanMFG</span>
              <span className="brand-suffix">documentation</span>
            </Link>
            <div className="header-links">
              <DocSearch />
              <a href="https://github.com/Varifold-Lab/LeanMFG">GitHub ↗</a>
            </div>
          </div>
        </header>
        {children}
        <footer className="site-footer">
          <span>LeanMFG · {buildInfo.tag || `${buildInfo.version}-dev`} · {buildInfo.commit.slice(0, 8)}{buildInfo.dirty ? ' · local changes' : ''}</span>
          <a href={`https://github.com/Varifold-Lab/LeanMFG/blob/${buildInfo.commit}/LICENSE`}>Apache-2.0</a>
        </footer>
      </body>
    </html>
  )
}
