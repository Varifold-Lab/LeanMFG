import { readdirSync, readFileSync, writeFileSync } from 'node:fs'
import { join, relative } from 'node:path'

const pages = []
function visit(directory) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name)
    if (entry.isDirectory()) visit(path)
    else if (entry.name === 'page.mdx') {
      const source = readFileSync(path, 'utf8')
      const title = /^# (.+)$/m.exec(source)?.[1]
      if (!title) throw new Error(`Documentation page needs a title: ${path}`)
      const names = [...source.matchAll(/<Declaration\s+name="([^"]+)"/g)].map(match => match[1])
      const body = source.replace(/^(import|export) .*$/gm, '').replace(/<[^>]*>/g, ' ')
        .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1').replace(/[`#*|]/g, '').trim()
      const description = body.split('\n').map(line => line.trim()).find(line => line && line !== title) || title
      const route = relative('app', directory).replaceAll('\\', '/')
      pages.push({ title, href: route ? `/${route}` : '/', description, declarations: names,
        text: `${body} ${names.join(' ')}`.replace(/\s+/g, ' ') })
    }
  }
}
visit('app')
writeFileSync('lib/search-index.json', JSON.stringify(pages, null, 2) + '\n')
console.log(`Indexed ${pages.length} MDX pages for documentation search.`)
