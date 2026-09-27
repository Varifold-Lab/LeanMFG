'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { useEffect, useRef, useState } from 'react'
import { documentation } from '@/lib/navigation'

export function DocNavigation({ onNavigate }: { onNavigate?: () => void } = {}) {
  const pathname = usePathname().replace(/\/$/, '') || '/'
  return <nav aria-label="Documentation">
    {documentation.map(group => <section className="nav-group" key={group.title}>
      <h2>{group.title}</h2>
      {group.items.map(item => <Link href={item.href} key={item.href} onClick={onNavigate}
        aria-current={pathname === item.href ? 'page' : undefined}>{item.title}</Link>)}
    </section>)}
  </nav>
}

export function MobileNavigation() {
  const details = useRef<HTMLDetailsElement>(null)
  return <details ref={details} className="mobile-navigation">
    <summary>Browse documentation</summary>
    <DocNavigation onNavigate={() => { if (details.current) details.current.open = false }} />
  </details>
}

export function OnThisPage() {
  const pathname = usePathname()
  const [headings, setHeadings] = useState<{ id: string; title: string; level: string }[]>([])
  useEffect(() => {
    setHeadings(Array.from(document.querySelectorAll('article h2[id], article h3[id]'))
      .filter(element => !element.closest('[hidden]'))
      .map(element => ({ id: element.id, title: element.textContent || '', level: element.tagName })))
  }, [pathname])
  if (!headings.length) return null
  return <nav aria-label="On this page" className="page-contents">
    <p>On this page</p>
    {headings.map((heading, i) => <a key={`${heading.id}-${i}`} href={`#${heading.id}`} className={heading.level === 'H3' ? 'subheading' : undefined}>{heading.title}</a>)}
  </nav>
}
