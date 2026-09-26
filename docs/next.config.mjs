import createMDX from '@next/mdx'

/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  pageExtensions: ['ts', 'tsx', 'mdx'],
  trailingSlash: true,
  basePath: process.env.NEXT_PUBLIC_BASE_PATH || '',
  turbopack: { root: process.cwd() },
}

const withMDX = createMDX({
  options: {
    remarkPlugins: ['remark-gfm', 'remark-math'],
    rehypePlugins: ['rehype-katex'],
  },
})

export default withMDX(nextConfig)
