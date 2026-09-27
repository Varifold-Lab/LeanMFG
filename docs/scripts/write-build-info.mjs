import { execFileSync } from 'node:child_process'
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs'

const git = (...args) => execFileSync('git', args, { encoding: 'utf8' }).trim()
const commit = git('rev-parse', 'HEAD')
const dirty = git('status', '--porcelain', '--untracked-files=normal') !== ''
const version = JSON.parse(readFileSync('package.json', 'utf8')).version
const tag = process.env.LEANMFG_DOCS_TAG || null
if (process.env.LEANMFG_SOURCE_REV && process.env.LEANMFG_SOURCE_REV !== commit) {
  throw new Error('Documentation source revision does not match checkout')
}
if (tag && (tag !== `v${version}` || dirty)) {
  throw new Error('Release documentation needs a matching version and clean checkout')
}
const info = { version, tag, commit, dirty }
mkdirSync('public', { recursive: true })
for (const path of ['lib/build-info.json', 'public/build-info.json']) {
  writeFileSync(path, JSON.stringify(info, null, 2) + '\n')
}
console.log(`Documentation: ${tag || `${version}-dev`} at ${commit}${dirty ? ' (local changes)' : ''}`)
