/**
 * 把 install.sh + install.ps1 都内联到一份 Cloudflare Worker JS,产出 dist-worker.js。
 *
 * 部署方式:
 *   1. bun scripts/cf-worker/build.ts  → 生成 scripts/cf-worker/dist-worker.js
 *   2. CF 控制台 → Workers & Pages → 创 Worker
 *   3. 把 dist-worker.js 全部内容粘到 Worker 编辑器,部署
 *   4. Settings → Domains & Routes 加路由:api.intenext.ai/install
 *      (其他路径不会被拦截,api.intenext.ai 原有 LLM API 不受影响)
 *      ※ 注:Route 只能填一个,但 Worker 内部会同时匹配 /install 和 /install.ps1。
 *      想让 PowerShell 命令也走这台 Worker,加一条路由 api.intenext.ai/install.ps1
 *
 * 改 install.sh / install.ps1 后重跑 build.ts,把新 dist-worker.js 粘回即可。
 */

import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const ROOT = path.resolve(__dirname, '../..')

const installSh  = fs.readFileSync(path.join(ROOT, 'scripts/install.sh'),  'utf-8')
const installPs1 = fs.readFileSync(path.join(ROOT, 'scripts/install.ps1'), 'utf-8')

const worker = `// Cloudflare Worker — InteNext.ai install script host
// 自动生成,请勿手改。改 install.sh / install.ps1 后重跑 bun scripts/cf-worker/build.ts

const INSTALL_SH  = ${JSON.stringify(installSh)};
const INSTALL_PS1 = ${JSON.stringify(installPs1)};

const headers = (ct) => ({
  'content-type': ct + '; charset=utf-8',
  'cache-control': 'public, max-age=300',
  'x-content-type-options': 'nosniff',
});

export default {
  async fetch(request) {
    const url = new URL(request.url);

    if (url.pathname === '/install') {
      return new Response(INSTALL_SH, { headers: headers('text/plain') });
    }

    if (url.pathname === '/install.ps1') {
      return new Response(INSTALL_PS1, { headers: headers('text/plain') });
    }

    if (url.pathname === '/install/healthz') {
      return new Response('ok\\n', { headers: headers('text/plain') });
    }

    // 其他路径不归本 Worker 管 —— 透传交给 api.intenext.ai 原本的路由
    return new Response('Not Found', { status: 404 });
  },
};
`

const outPath = path.join(__dirname, 'dist-worker.js')
fs.writeFileSync(outPath, worker, 'utf-8')

const sizeKB = (worker.length / 1024).toFixed(1)
console.log(`✓ Worker bundle: ${outPath} (${sizeKB} KB)`)
console.log(`  install.sh  inlined: ${(installSh.length  / 1024).toFixed(1)} KB`)
console.log(`  install.ps1 inlined: ${(installPs1.length / 1024).toFixed(1)} KB`)
console.log(`\n部署:粘 dist-worker.js 到 CF Worker 编辑器`)
console.log(`     路由 1:api.intenext.ai/install        (curl | bash)`)
console.log(`     路由 2:api.intenext.ai/install.ps1    (iex (irm ...))`)
