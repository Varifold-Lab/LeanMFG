'use client'

import Link from 'next/link'
import { useEffect, useRef, useState } from 'react'
import searchIndex from '@/lib/search-index.json'

export function DocSearch() {
  const dialog = useRef<HTMLDialogElement>(null)
  const input = useRef<HTMLInputElement>(null)
  const [query, setQuery] = useState('')
  function open() { dialog.current?.showModal(); input.current?.focus() }
  useEffect(() => {
    function shortcut(event: KeyboardEvent) {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
        event.preventDefault(); dialog.current?.open ? dialog.current.close() : open()
      }
    }
    window.addEventListener('keydown', shortcut)
    return () => window.removeEventListener('keydown', shortcut)
  }, [])
  const terms = query.toLowerCase().trim().split(/\s+/).filter(Boolean)
  const rank = (page: typeof searchIndex[number]) =>
    Number(terms.every(term => page.title.toLowerCase().includes(term))) * 2 +
    Number(page.declarations.some(name => terms.every(term => name.toLowerCase().includes(term))))
  const results = terms.length ? searchIndex.filter(page => terms.every(term => `${page.title} ${page.text}`.toLowerCase().includes(term)))
    .sort((a, b) => rank(b) - rank(a)) : []
  return <>
    <button className="search-trigger" type="button" onClick={open}>Search documentation <kbd>⌘ K</kbd></button>
    <dialog className="search-dialog" ref={dialog} aria-label="Search documentation" onClick={event => { if (event.target === dialog.current) dialog.current.close() }}>
      <div className="search-input-row"><label className="sr-only" htmlFor="docs-search">Search documentation</label>
        <input id="docs-search" ref={input} value={query} onChange={event => setQuery(event.target.value)} placeholder="Search pages, definitions, or examples" type="search" />
        <button type="button" onClick={() => dialog.current?.close()}>Close</button>
      </div>
      <div className="search-results" aria-live="polite">
        {!terms.length ? <p>Try “exploitability”, “HJB”, or “SolveOptions”.</p> : results.length ? <ul>{results.slice(0, 12).map(page => <li key={page.href}>
          <Link href={page.href} onClick={() => dialog.current?.close()}><strong>{page.title}</strong><span>{page.description}</span></Link>
        </li>)}</ul> : <p>No matching pages.</p>}
      </div>
    </dialog>
  </>
}
