/**
 * 一键打包 macOS + Windows 三件套到 release/<version>/:
 *   - Codex Setup-<version>-arm64.dmg   (Apple Silicon)
 *   - Codex Setup-<version>.dmg          (Intel)
 *   - Codex Setup-<version>-win-x64.zip  (Windows)
 *
 * 跳过 Wine —— 通过 signAndEditExecutable=false + dir target,
 * 不走 rcedit 给 .exe 嵌图标(Win 用户看 .exe 文件本身是默认 Electron 图标,
 * 但运行后窗口里的图标是 haivex logo,在 macOS 上 arm64 也能跑)。
 */

import { spawnSync } from 'node:child_process'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const ROOT = path.resolve(__dirname, '..')
const pkg = JSON.parse(fs.readFileSync(path.join(ROOT, 'package.json'), 'utf-8'))
const VERSION: string = pkg.version
const RELEASE_DIR = path.join(ROOT, 'release', VERSION)

const run = (cmd: string, args: string[]) => {
  const r = spawnSync(cmd, args, { stdio: 'inherit', cwd: ROOT })
  if (r.status !== 0) {
    console.error(`✗ ${cmd} ${args.join(' ')}  failed (exit ${r.status})`)
    process.exit(r.status ?? 1)
  }
}

// 1. Vite build
console.log('\n▸ Vite build')
run('bun', ['run', 'build'])

// 2. macOS 包(arm64 + x64 dmg)
console.log('\n▸ Pack macOS (arm64 + x64 dmg)')
run('bunx', ['electron-builder', '--mac', '--config', 'electron-builder.json'])

// 3. Windows 包(dir + 手动 zip,绕开 Wine)
console.log('\n▸ Pack Windows (dir → zip)')
run('bunx', ['electron-builder', '--win', '--config', 'electron-builder.json'])

const winUnpacked = path.join(RELEASE_DIR, 'win-unpacked')
const winZip = path.join(RELEASE_DIR, `Codex Setup-${VERSION}-win-x64.zip`)
if (fs.existsSync(winUnpacked)) {
  if (fs.existsSync(winZip)) fs.rmSync(winZip)
  console.log(`  → zipping win-unpacked → ${path.basename(winZip)}`)
  run('ditto', ['-c', '-k', '--sequesterRsrc', '--keepParent', winUnpacked, winZip])
  fs.rmSync(winUnpacked, { recursive: true, force: true })
}

// 4. 清理 electron-builder 的中间产物 / auto-update 文件
const removeIfExists = (p: string) => {
  if (fs.existsSync(p)) fs.rmSync(p, { recursive: true, force: true })
}

const exactNames = [
  'latest-mac.yml',
  'builder-debug.yml',
  'builder-effective-config.yaml',
  '.icon-icns',
  '.icon-ico',
  'mac',
  'mac-arm64',
]
for (const name of exactNames) removeIfExists(path.join(RELEASE_DIR, name))

for (const name of fs.readdirSync(RELEASE_DIR)) {
  if (name.endsWith('.blockmap')) removeIfExists(path.join(RELEASE_DIR, name))
}

// 5. 列出最终产出
console.log('\n✓ Done. Artifacts in', RELEASE_DIR)
const files = fs
  .readdirSync(RELEASE_DIR)
  .map((name) => {
    const stat = fs.statSync(path.join(RELEASE_DIR, name))
    const sizeMB = (stat.size / 1024 / 1024).toFixed(1)
    return `  ${name.padEnd(48)} ${sizeMB} MB`
  })
console.log(files.join('\n'))
