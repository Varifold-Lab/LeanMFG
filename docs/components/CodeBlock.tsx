'use client'

import { useState } from 'react'

export function CodeBlock({ code, language = '', caption }: { code: string; language?: string; caption?: string }) {
  const [state, setState] = useState<'Copy' | 'Copied' | 'Select code to copy'>('Copy')
  async function copy() {
    try {
      await navigator.clipboard.writeText(code)
      setState('Copied')
      setTimeout(() => setState('Copy'), 1800)
    } catch { setState('Select code to copy') }
  }
  return (
    <figure className="code-block">
      <figcaption><span>{caption || language || 'Code'}</span><button type="button" onClick={copy} aria-label="Copy code">{state}</button></figcaption>
      <pre><code className={language ? `language-${language}` : undefined}>{code}</code></pre>
      <span className="sr-only" role="status">{state === 'Copied' ? 'Code copied to clipboard' : ''}</span>
    </figure>
  )
}
