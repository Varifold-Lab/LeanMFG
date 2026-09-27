import type { ReactNode } from 'react'
import buildInfo from '@/lib/build-info.json'

const repository = 'https://github.com/Varifold-Lab/LeanMFG'

export function RepositoryLink({ path, children }: { path: string; children: ReactNode }) {
  if (path.startsWith('/') || path.split('/').includes('..')) {
    throw new Error(`Invalid repository path: ${path}`)
  }
  return <a href={`${repository}/blob/${buildInfo.commit}/${path}`}>{children}</a>
}

export function SourceLink({ path, children }: { path: string; children: ReactNode }) {
  if (!path.startsWith('LeanMFG/') || !path.endsWith('.lean')) {
    throw new Error(`Invalid Lean source path: ${path}`)
  }
  return <RepositoryLink path={path}>{children}</RepositoryLink>
}
