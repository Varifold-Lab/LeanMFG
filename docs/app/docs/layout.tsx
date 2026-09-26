import Link from 'next/link'
import { documentation } from '@/lib/navigation'

export default function DocumentationLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <div className="documentation-shell">
      <aside className="sidebar" aria-label="Documentation navigation">
        <p className="sidebar-kicker">Documentation</p>
        {documentation.map((group) => (
          <nav key={group.title} aria-label={group.title} className="nav-group">
            <h2>{group.title}</h2>
            {group.items.map((item) => (
              <Link key={item.href} href={item.href}>{item.title}</Link>
            ))}
          </nav>
        ))}
      </aside>
      <main className="article-column">
        <article className="prose">{children}</article>
      </main>
    </div>
  )
}
