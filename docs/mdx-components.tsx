import type { MDXComponents } from 'mdx/types'
import Link from 'next/link'
import { isValidElement } from 'react'
import { CodeBlock } from '@/components/CodeBlock'
import { headingId, textContent } from '@/lib/headings'

export function useMDXComponents(): MDXComponents {
  return {
    h2: ({ children, id, ...props }) => <h2 id={id || headingId(textContent(children))} {...props}>{children}</h2>,
    h3: ({ children, id, ...props }) => <h3 id={id || headingId(textContent(children))} {...props}>{children}</h3>,
    pre: ({ children }) => {
      const code = isValidElement<{ className?: string; children?: React.ReactNode }>(children) ? children.props : null
      return <CodeBlock language={code?.className?.replace('language-', '')} code={textContent(code?.children ?? children).replace(/\n$/, '')} />
    },
    a: ({ href, children, ...props }) =>
      href?.startsWith('/') && !href.startsWith('//')
        ? <Link href={href} {...props}>{children}</Link>
        : <a href={href} {...props}>{children}</a>,
  }
}
