import { existsSync, readdirSync, readFileSync } from 'node:fs'
import { join, resolve } from 'node:path'

const app = resolve('app')
const repository = resolve('..')
let count = 0

function inspect(directory) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const file = join(directory, entry.name)
    if (entry.isDirectory()) {
      inspect(file)
    } else if (entry.name.endsWith('.mdx')) {
      const content = readFileSync(file, 'utf8')
      for (const [, source] of content.matchAll(/<SourceLink\s+path="([^"]+)"/g)) {
        if (!source.startsWith('LeanMFG/') || !source.endsWith('.lean')) {
          throw new Error(`Invalid source link in ${file}: ${source}`)
        }
        if (!existsSync(join(repository, source))) {
          throw new Error(`Missing Lean module linked from ${file}: ${source}`)
        }
        count += 1
      }
    }
  }
}

inspect(app)
console.log(`Checked ${count} Lean source links in MDX pages.`)
