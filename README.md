# InteNext API Setup

一键把本地 Codex CLI 切到 **InteNext.ai 算力平台** —— 主流大模型 API 1 折价。

---

## 怎么用

### 🍎 macOS / Linux

在终端粘贴这条命令:

```bash
curl -fsSL https://api.intenext.ai/install | bash
```

### 🪟 Windows

在 **PowerShell** 粘贴这条命令(开始菜单 → 搜 "PowerShell" → 回车):

```powershell
iex (irm https://api.intenext.ai/install.ps1)
```

> 注意:**两个 URL 别搞混了** ——
> - macOS / Linux 用 `/install`(给 bash 跑的)
> - Windows 用 `/install.ps1`(给 PowerShell 跑的)

---

## 运行后会发生什么

无论 Mac 还是 Windows,脚本启动后看到的界面**完全一样**:

```
  ┌────────────────────────────────────────────────────────────────────────┐
  │                                                                        │
  │  InteNext AI (下一代 AI 算力平台)                                      │
  │  主流大模型 API · 1 折价开箱即用                                       │
  │                                                                        │
  │  ▸  主流大模型 1 折价 · 省 90% 成本                                    │
  │  ▸  推理 10× 加速 · 1s 出图 · 100ms 语音                               │
  │  ▸  语言:GPT-5.5 / Claude 4.7 / Gemini 3.1 / DeepSeek                  │
  │  ▸  创作:Veo 3.1 / GPT Image 2 / SD 3.5                                │
  │  ▸  新模型 0 时差上线                                                  │
  │  ▸  注册即送 · 0 门槛试用                                              │
  │  ▸  支持 10000+ 并发 · 企业级定制详询淘宝旗舰店                        │
  │                                                                        │
  │  算力平台    →  https://api.intenext.ai                                │
  │  淘宝旗舰店  →  https://item.taobao.com/item.htm?ft=t&id=1046050759606 │
  │                                                                        │
  └────────────────────────────────────────────────────────────────────────┘

  请粘贴你的 API Key,然后按回车

  ────────────────────────────────────────────────────────────────────────
  ›  ▮                                                                      ← 粘 key,回车
  ────────────────────────────────────────────────────────────────────────

  正在配置 …

  ✓ 配置完成
  打开 Codex 即可开始使用。
```

实际终端里**方框的边框是蓝紫粉金青真彩色渐变**(每个 ─ 字符自己一个颜色,平滑过渡),品牌名也是渐变字母,关键数字(`1 折价` / `10000+` / `0 时差` / `0 门槛`)按主题色加粗高亮。

3 步走完:**粘命令 → 粘 key → 回车**。整个过程 5 秒。

---

## 高级用法

### 直接传 key(免交互,适合自动化 / 脚本 / CI)

```bash
# macOS / Linux
curl -fsSL https://api.intenext.ai/install | bash -s -- sk-yourkey

# Windows PowerShell
$env:INTENEXT_KEY = "sk-yourkey"; iex (irm https://api.intenext.ai/install.ps1)
```

### 本地脚本(开发 / 离线分发)

```bash
./scripts/install.sh sk-yourkey         # macOS / Linux / Git Bash
.\scripts\install.ps1                   # Windows PowerShell
```

---

## 完全不想动终端

下载图形界面安装包,打开输入 key 点保存:

- 🍎 macOS Apple Silicon → `release/<version>/Codex Setup-<version>-arm64.dmg`
- 🪟 Windows x64 → `release/<version>/Codex Setup-<version>-win-x64.zip`(解压跑里面的 .exe)

本地开发:

```bash
bun i      # 装依赖
bun dev    # 启动 Electron 开发服务器
```

打包:

```bash
bun run dist:mac    # 只出 mac dmg
bun run dist:all    # mac dmg + windows zip 一起出
```

---

## 它具体做了什么

**1. 在 `~/.codex/config.toml` 的真正顶层(任何 `[section]` 之前)写入 7 个 key:**

```toml
model_provider = "OpenAI"
model = "gpt-5.4"
review_model = "gpt-5.4"
model_reasoning_effort = "medium"
disable_response_storage = true
network_access = "enabled"
windows_wsl_setup_acknowledged = true
```

**2. 在文件末尾追加 / 更新这个 section:**

```toml
[model_providers.OpenAI]
name = "OpenAI"
base_url = "https://api.haivex.ai/v1"
wire_api = "responses"
requires_openai_auth = true
```

**3. 在 `~/.codex/auth.json` 写入 `OPENAI_API_KEY`(合并模式,保留其他字段)。**

---

## 反复执行会怎样

**完全幂等。** 跑 100 次的产物和跑 1 次完全一致(实测 diff 为空)。

实现策略:

- 每次运行先**剥离**文件里我方管理的 7 个顶层 key + `[model_providers.OpenAI]` 整段
- 用户其他配置(注释、空行、其他顶层 key、其他 section)**原样保留**
- 然后按正确顺序重写:`[用户顶层 key] → [我方顶层 key] → [所有 section] → [我方 section]`

不依赖注释 marker —— 靠 TOML 结构判断,文件最终干净,没有任何 `# === managed ===` 之类的标记。

---

## 已有 Codex 配置会被破坏吗

**不会(除了一个例外)。** 下面这些都**完整保留**:

| 用户配置 | 是否保留 |
|---|---|
| 注释 `# my comment` | ✅ |
| 用户自己加的顶层 key(`theme = "dark"`)| ✅ |
| `[marketplaces.*]`(Codex 自己写的) | ✅ |
| `[plugins.*]` | ✅ |
| `[projects.*]` | ✅ |
| `[model_providers.OtherProvider]`(其他第三方 provider)| ✅ |
| `auth.json` 里的其他字段(`existing_token` 等) | ✅(合并)|

**唯一会被覆盖**:如果之前在 `[model_providers.OpenAI]` 里手动改过 `base_url` 等字段,会被重置成 InteNext 的版本。这个 section 由本工具托管。

---

## 智能"重启提示"

写完配置后,脚本会**检测 Codex 是否正在运行**:

| 状态 | 用户看到的提示 |
|---|---|
| 没在跑 | `打开 Codex 即可开始使用。` |
| 正在跑 | `提示:Codex 正在运行,请关闭并重新打开 Codex 即可生效。` |

**不自动 kill 用户进程** —— Codex 是交互式工具,可能正在对话中,强杀会丢上下文。把"关闭并重开"的决定权留给用户。

---

## 安全兜底

每次执行前自动备份:

```
~/.codex/config.toml.bak
~/.codex/auth.json.bak
```

不满意一秒回滚:

```bash
mv ~/.codex/config.toml.bak ~/.codex/config.toml
mv ~/.codex/auth.json.bak   ~/.codex/auth.json
```

(下次再跑 `install.sh` 会覆盖 `.bak`,只保留**最近一次**的备份。)

---

## 失败场景

| 报错 | 原因 | 解决 |
|---|---|---|
| `没检测到 Codex(找不到 ~/.codex 目录)` | 还没装 Codex | 先安装 Codex 再跑此命令 |
| `API Key 不能为空` | 没传参数,或粘贴时没东西 | 检查 key 是否粘进去 |
| `当前环境无法交互输入` | 在没有 TTY 的容器/CI 里跑 | 直接把 key 当参数传入 |

---

## 部署:把脚本挂到 api.intenext.ai

走 Cloudflare Worker,**不依赖任何自建服务器**,bash + PowerShell 同一个 Worker 服务:

```bash
bun run build:worker
# scripts/cf-worker/dist-worker.js 已内联 install.sh + install.ps1(~22 KB)
# 粘到 CF Worker 编辑器 → Deploy
# 绑两条路由:
#   api.intenext.ai/install        ← Bash 脚本
#   api.intenext.ai/install.ps1    ← PowerShell 脚本
```

完整步骤见 [`scripts/cf-worker/README.md`](scripts/cf-worker/README.md)。

只拦 `/install` 和 `/install.ps1` 这两个路径,api.intenext.ai 上其他路径(LLM API)完全不受影响。Worker 免费额度每天 100k 请求,这种安装脚本场景永远用不完。

---

## 用户依赖

**不需要装任何东西**,开箱即用。

### macOS / Linux(bash 脚本)

| 工具 | 用途 | 自带情况 |
|---|---|---|
| `bash` | 解释脚本 | ✅ macOS / Linux 自带 |
| `curl` | 拉脚本 | ✅ 自带 |
| `awk` | 改 config.toml | ✅ 自带 |
| `python3` | 合并 auth.json | ✅ 几乎都有(Linux 默认,macOS 装过 Xcode CLT 就有) |

`python3` 缺失时三层兜底:`python3` → `jq` → 直接重写(`OPENAI_API_KEY` 永远写入,差别只在保不保留 auth.json 其他字段)。

### Windows(PowerShell 脚本)

**Windows 10 / 11 全部自带 PowerShell + curl**,无需安装任何依赖。Worker 路径 `/install.ps1` 返回的脚本里:
- JSON 合并用 PowerShell 内置 `ConvertFrom-Json` / `ConvertTo-Json`
- TOML 操作用正则 + 字符串拼接
- ANSI 真彩色在 **Windows Terminal**(默认终端)、**PowerShell 7+** 完整支持
- 老版 PowerShell 5(Win 10 自带):颜色可能降级显示,功能不影响

### 不想用终端的 Windows 用户

直接下载**桌面客户端**(.zip),解压跑 `Codex Setup.exe`,输入 key 点保存 —— 零终端介入。

---

## 开发

技术栈:Electron + Vite + React + TypeScript + electron-builder

```
.
├── electron/                 # 主进程 / preload / 配置逻辑
│   ├── main.ts
│   ├── preload.ts
│   └── codex-config.ts       # 配置写入核心(与 install.sh 等价)
├── src/                      # React 渲染进程 UI
├── scripts/
│   ├── install.sh            # Bash 安装脚本(macOS / Linux,curl|bash 本体)
│   ├── install.ps1           # PowerShell 安装脚本(Windows)
│   ├── dist-all.ts           # 一键打包 mac + win
│   └── cf-worker/            # Cloudflare Worker 部署
│       ├── build.ts          # 把 install.sh + install.ps1 内联成 Worker JS
│       └── README.md
├── build/                    # 应用图标
├── electron-builder.json     # 打包配置
└── vite.config.ts
```
