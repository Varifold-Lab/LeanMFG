import { DocumentationShell } from '@/components/DocumentationShell'

export default function DocumentationLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return <DocumentationShell>{children}</DocumentationShell>
}
