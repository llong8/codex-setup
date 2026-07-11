import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'

const MANAGED_TOP_KEYS = [
  'model_provider',
  'model',
  'review_model',
  'model_reasoning_effort',
  'disable_response_storage',
  'network_access',
  'windows_wsl_setup_acknowledged',
]

const MANAGED_SECTION = 'model_providers.OpenAI'

const MANAGED_TOP_BLOCK = `model_provider = "OpenAI"
model = "gpt-5.6-sol"
review_model = "gpt-5.6-sol"
model_reasoning_effort = "medium"
disable_response_storage = true
network_access = "enabled"
windows_wsl_setup_acknowledged = true`

const MANAGED_SECTION_BLOCK = `[model_providers.OpenAI]
name = "OpenAI"
base_url = "https://api.haivex.ai/v1"
wire_api = "responses"
requires_openai_auth = true`

export type ApplyResult =
  | {
      ok: true
      configPath: string
      authPath: string
      configAction: 'created' | 'appended' | 'replaced'
      authAction: 'created' | 'merged'
    }
  | { ok: false; error: string }

/**
 * 把 toml 拆成「首个 section 之前」+「首个 section 起的所有 section」两段,
 * 同时移除我方管理的顶层 key 和 [model_providers.OpenAI] section。
 *
 * 关键:顶层 key 必须放在所有 [section] 之前,否则会被解析为某 section 的子 key。
 */
const splitAndStrip = (toml: string): { topPart: string; sectionPart: string } => {
  const lines = toml.split('\n')
  const topLines: string[] = []
  const sectionLines: string[] = []

  let inManagedSection = false
  let beforeAnySection = true

  for (const line of lines) {
    const trimmed = line.trim()
    const sectionMatch = trimmed.match(/^\[([^\]]+)\]/)

    if (sectionMatch) {
      beforeAnySection = false
      inManagedSection = sectionMatch[1].trim() === MANAGED_SECTION
      if (inManagedSection) continue
      sectionLines.push(line)
      continue
    }

    if (inManagedSection) continue

    if (beforeAnySection) {
      // 顶层区:剥离我们管理的顶层 key
      const keyMatch = trimmed.match(/^([A-Za-z_][\w-]*)\s*=/)
      if (keyMatch && MANAGED_TOP_KEYS.includes(keyMatch[1])) continue
      topLines.push(line)
    } else {
      sectionLines.push(line)
    }
  }

  const trimEnd = (arr: string[]) => {
    while (arr.length > 0 && arr[arr.length - 1].trim() === '') arr.pop()
    return arr
  }

  return {
    topPart: trimEnd(topLines).join('\n'),
    sectionPart: trimEnd(sectionLines).join('\n'),
  }
}

export const applyCodexConfig = async (apiKey: string): Promise<ApplyResult> => {
  const trimmed = apiKey?.trim()
  if (!trimmed) {
    return { ok: false, error: 'API Key 不能为空' }
  }

  const codexDir = path.join(os.homedir(), '.codex')

  if (!fs.existsSync(codexDir)) {
    return {
      ok: false,
      error: '未检测到 ~/.codex 目录,请先安装 Codex 客户端再运行此工具。',
    }
  }

  const configPath = path.join(codexDir, 'config.toml')
  const authPath = path.join(codexDir, 'auth.json')

  // ── 1. config.toml:重组顺序确保顶层 key 真的是顶层 ──
  const existing = fs.existsSync(configPath) ? fs.readFileSync(configPath, 'utf-8') : ''
  const { topPart, sectionPart } = splitAndStrip(existing)

  // 拼接:[顶层用户自有] + [我方顶层 key] + [所有 section] + [我方 section]
  const parts: string[] = []
  if (topPart) parts.push(topPart)
  parts.push(MANAGED_TOP_BLOCK)
  if (sectionPart) parts.push(sectionPart)
  parts.push(MANAGED_SECTION_BLOCK)

  const nextContent = parts.join('\n\n') + '\n'

  let configAction: 'created' | 'appended' | 'replaced'
  if (existing.length === 0) {
    configAction = 'created'
  } else if (
    existing.includes('[model_providers.OpenAI]') ||
    MANAGED_TOP_KEYS.some((k) => new RegExp(`^${k}\\s*=`, 'm').test(existing))
  ) {
    configAction = 'replaced'
  } else {
    configAction = 'appended'
  }

  fs.writeFileSync(configPath, nextContent, 'utf-8')

  // ── 2. auth.json:存在则合并 ──
  let authObj: Record<string, unknown> = {}
  let authAction: 'created' | 'merged' = 'created'

  if (fs.existsSync(authPath)) {
    authAction = 'merged'
    try {
      const raw = fs.readFileSync(authPath, 'utf-8')
      const parsed = JSON.parse(raw)
      if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) {
        authObj = parsed as Record<string, unknown>
      }
    } catch {
      authAction = 'created'
      authObj = {}
    }
  }

  authObj.OPENAI_API_KEY = trimmed
  fs.writeFileSync(authPath, JSON.stringify(authObj, null, 2) + '\n', 'utf-8')

  return { ok: true, configPath, authPath, configAction, authAction }
}
