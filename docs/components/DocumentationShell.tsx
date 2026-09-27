import type { ReactNode } from 'react'
import { DocNavigation, MobileNavigation, OnThisPage } from './DocNavigation'
import buildInfo from '@/lib/build-info.json'

export function DocumentationShell({ children }: { children: ReactNode }) {
  return <div className="documentation-shell">
    <aside className="sidebar"><p className="sidebar-version">{buildInfo.tag || `${buildInfo.version} · development`}</p>
      <div className="desktop-navigation"><DocNavigation /></div>
      <MobileNavigation />
    </aside>
    <main id="main-content" className="article-column"><article className="prose">{children}</article></main>
    <aside className="contents-column"><OnThisPage /></aside>
  </div>
}
