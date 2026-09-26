import type { ReactNode } from 'react'

const repository = 'https://github.com/Varifold-Lab/LeanMFG'

export function SourceLink({ path, children }: { path: string; children: ReactNode }) {
  if (!path.startsWith('LeanMFG/') || !path.endsWith('.lean')) {
    throw new Error(`Invalid Lean source path: ${path}`)
  }
  return <a href={`${repository}/blob/main/${path}`}>{children}</a>
}
