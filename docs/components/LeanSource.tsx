import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import type { ReactNode } from 'react'
import { CodeBlock } from './CodeBlock'
import { RepositoryLink } from './SourceLink'
import { headingId } from '@/lib/headings'

function readSource(path: string, start?: string, endBefore?: string) {
  if (!/^(LeanMFG|docs\/examples|tests)\//.test(path) || !path.endsWith('.lean') || path.split('/').includes('..')) {
    throw new Error(`Invalid Lean source path: ${path}`)
  }
  let text = readFileSync(resolve(process.cwd(), '..', path), 'utf8')
  if (start) {
    const first = text.indexOf(start)
    if (first < 0 || text.indexOf(start, first + 1) >= 0) throw new Error(`Source marker must be unique: ${path}: ${start}`)
    text = text.slice(first)
  }
  if (endBefore) {
    const end = text.indexOf(endBefore)
    if (end < 0) throw new Error(`Missing source end marker: ${path}: ${endBefore}`)
    text = text.slice(0, end)
  }
  return text.trimEnd()
}

type SourceProps = { path: string; start?: string; endBefore?: string }

export function LeanSnippet({ path, start, endBefore }: SourceProps) {
  return <CodeBlock language="lean" code={readSource(path, start, endBefore)} caption={path.split('/').at(-1)} />
}

export function Declaration({ name, path, start, endBefore, children }: SourceProps & { name: string; children: ReactNode }) {
  const id = headingId(name)
  return <section className="declaration">
    <div className="declaration-title"><h2 id={id}><code>{name}</code></h2><RepositoryLink path={path}>Source</RepositoryLink></div>
    <CodeBlock language="lean" code={readSource(path, start, endBefore)} />
    {children}
  </section>
}
