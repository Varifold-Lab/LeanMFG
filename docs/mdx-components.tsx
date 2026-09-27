import type { MDXComponents } from 'mdx/types'
import Link from 'next/link'

export function useMDXComponents(): MDXComponents {
  return {
    a: ({ href, children, ...props }) =>
      href?.startsWith('/') && !href.startsWith('//')
        ? <Link href={href} {...props}>{children}</Link>
        : <a href={href} {...props}>{children}</a>,
  }
}
