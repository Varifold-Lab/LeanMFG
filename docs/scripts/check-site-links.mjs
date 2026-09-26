import { existsSync, readdirSync, readFileSync } from 'node:fs'
import { join, resolve } from 'node:path'

const output = resolve('out')
const basePath = process.env.NEXT_PUBLIC_BASE_PATH || ''
let checked = 0

function inspect(directory) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const file = join(directory, entry.name)
    if (entry.isDirectory()) {
      inspect(file)
    } else if (entry.name.endsWith('.html')) {
      for (const [, href] of readFileSync(file, 'utf8').matchAll(/href="([^"]+)"/g)) {
        if (!href.startsWith('/')) continue
        let pathname = new URL(href.replaceAll('&amp;', '&'), 'http://docs.local').pathname
        if (basePath) {
          if (!pathname.startsWith(`${basePath}/`) && pathname !== basePath) {
            throw new Error(`Link outside site base path in ${file}: ${href}`)
          }
          pathname = pathname.slice(basePath.length) || '/'
        }
        const destination = join(output, decodeURIComponent(pathname))
        if (!existsSync(destination) && !existsSync(join(destination, 'index.html'))) {
          throw new Error(`Broken internal link in ${file}: ${href}`)
        }
        checked += 1
      }
    }
  }
}

inspect(output)
console.log(`Checked ${checked} internal links in static HTML.`)
