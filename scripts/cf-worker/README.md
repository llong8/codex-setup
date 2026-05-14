# Cloudflare Worker 部署

把 `install.sh`(Bash 版)和 `install.ps1`(PowerShell 版)通过 Cloudflare Worker 同时挂到 `api.intenext.ai`,**不依赖任何自建服务器**:

| URL | 给谁用 |
|---|---|
| `https://api.intenext.ai/install` | macOS / Linux (bash) |
| `https://api.intenext.ai/install.ps1` | Windows (PowerShell) |

## 一次性部署

### 1. 构建 Worker bundle

```bash
bun run build:worker
```

产物:`scripts/cf-worker/dist-worker.js`(install.sh + install.ps1 都内联进去,~22 KB)。

### 2. 在 Cloudflare 创建 Worker

1. 登录 Cloudflare → **Workers & Pages** → **Create application** → **Workers** 标签 → **Create Worker**
2. 起个名字,建议 **`intenext-install`**(跟最终 URL 对应,日后管理清晰)
3. 进入 Worker 编辑器(右上角 `</> Edit code`),**全选清空默认代码**,把 `dist-worker.js` 全部内容粘进去
4. 点 **Save and Deploy**

### 3. 绑定两条路由

到 Worker 详情页 → **Settings → Domains & Routes**,**加两条 Route**(不是 Custom Domain):

```
Route 1:  api.intenext.ai/install        Zone: intenext.ai
Route 2:  api.intenext.ai/install.ps1    Zone: intenext.ai
```

> ⚠ **Route ≠ Custom Domain**
> - **Custom Domain**:整个域名归 Worker 接管 → 会把 api.intenext.ai 的 LLM API 流量也吃掉
> - **Route**:只拦特定路径,其他流量该去哪去哪 ← 选这个

### 4. 验证

```bash
# 验证 bash 版能拉到
curl -fsSL https://api.intenext.ai/install | head -5

# 验证 PowerShell 版也能拉到(Mac 上 curl 一下看看就行,别 pipe 给 bash)
curl -fsSL https://api.intenext.ai/install.ps1 | head -5

# 健康检查
curl -s https://api.intenext.ai/install/healthz
# → ok
```

部署完后,真实命令:

```bash
# macOS / Linux 用户
curl -fsSL https://api.intenext.ai/install | bash
```

```powershell
# Windows 用户
iex (irm https://api.intenext.ai/install.ps1)
```

---

## 后续更新

改了 `install.sh` 或 `install.ps1` 之后,**三步走**:

```bash
bun run build:worker
# 1. 打开 CF Worker 编辑器
# 2. 全选清空旧代码
# 3. 粘新 dist-worker.js 内容 → Deploy
```

Worker 改动**秒级全球生效**(CF 边缘节点),不需要等 CDN 刷新。

---

## 为什么用 Worker 而不是 Pages / R2

| 方案 | 痛点 |
|---|---|
| **CF Pages** | 要建 git 仓库 + 接入 Pages,流程长,改一次要 push commit |
| **R2 + Worker** | 多一个 R2 桶要管,增加心智负担 |
| **Worker 内联(本方案)** | 两份脚本加起来 ~22 KB,内联进 Worker 完全没问题。改一次贴一次,**3 分钟生效** |

Worker 免费额度:**每天 100k 请求**,这种安装脚本场景永远用不完。

---

## 路径设计

Worker 只匹配三个路径,其他全部返回 404 不接管:

| 路径 | 用途 | Content-Type |
|---|---|---|
| `/install` | 返回 install.sh(Bash) | `text/plain` |
| `/install.ps1` | 返回 install.ps1(PowerShell) | `text/plain` |
| `/install/healthz` | 健康检查 | `text/plain` |

`api.intenext.ai` 下的其他路径(LLM API)**Worker 不会拦**,继续走原本的路由(你的 LLM 代理 / 后端)。

---

## 文件清单

```
scripts/cf-worker/
├── build.ts           # 生成 dist-worker.js(内联 sh + ps1)
├── dist-worker.js     # 给 CF 用的最终 Worker JS(.gitignore 不入库)
└── README.md          # 本文件
```
