import { useState } from 'react'
import type { FormEvent, MouseEvent } from 'react'
import logo from './assets/logo.png'

type ApplyResult = {
  ok: boolean
  error?: string
}

declare global {
  interface Window {
    codexAPI: {
      apply: (apiKey: string) => Promise<ApplyResult>
      openExternal: (url: string) => Promise<void>
    }
  }
}

const PLATFORM_URL = 'https://api.intenext.ai'

export default function App() {
  const [apiKey, setApiKey] = useState('')
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState<ApplyResult | null>(null)

  const submit = async (e: FormEvent) => {
    e.preventDefault()
    if (!apiKey.trim() || loading) return

    setLoading(true)
    setResult(null)
    try {
      const res = await window.codexAPI.apply(apiKey)
      setResult(res)
    } catch (err) {
      setResult({ ok: false, error: err instanceof Error ? err.message : String(err) })
    } finally {
      setLoading(false)
    }
  }

  const openPlatform = (e: MouseEvent) => {
    e.preventDefault()
    window.codexAPI.openExternal(PLATFORM_URL)
  }

  return (
    <div className="container">
      <div className="bg-orbs" aria-hidden="true">
        <div className="orb orb-1" />
        <div className="orb orb-2" />
        <div className="orb orb-3" />
      </div>
      <div className="drag-region" />
      <header>
        <img src={logo} alt="Haivex" className="logo" />
      </header>

      <form onSubmit={submit}>
        <label className="field">
          <span>Key</span>
          <input
            type="password"
            value={apiKey}
            onChange={(e) => setApiKey(e.target.value)}
            placeholder="sk-..."
            disabled={loading}
            autoFocus
            spellCheck={false}
          />
        </label>

        <button type="submit" disabled={loading || !apiKey.trim()}>
          {loading ? '配置中…' : '保存配置'}
        </button>
      </form>

      {result && (
        <div className={`message ${result.ok ? 'success' : 'error'}`}>
          {result.ok ? (
            <div className="msg-title">✓ 配置完成</div>
          ) : (
            <>
              <div className="msg-title">✗ 配置失败</div>
              <div className="msg-detail">{result.error}</div>
            </>
          )}
        </div>
      )}

      <footer className="footer">
        <a href={PLATFORM_URL} onClick={openPlatform} className="ad">
          <span className="ad-tag">推广</span>
          <span className="ad-marquee">
            <span className="ad-marquee-track">
              {/* HTML 顺序倒过来:从上到下视觉滚动需要把"下一条"放在"当前条"的上方
                  显示顺序:1.1 折价 → 2.延迟低 → 3.生图 → 4.0 时差 → 5.注册礼 → 1(loop) */}
              <span className="ad-slide">Haivex 算力平台 · 主流大模型 1 折价 · 省 90%</span>
              <span className="ad-slide">Haivex 算力平台 · 注册即送 · 0 门槛试用</span>
              <span className="ad-slide">Haivex 算力平台 · 新模型与官方同步 0 时差上线</span>
              <span className="ad-slide">Haivex · GPT Image 2 · Nano Banana 生图全支持</span>
              <span className="ad-slide">Haivex 算力平台 · 直连节点 · 延迟比中转低 70%</span>
              <span className="ad-slide">Haivex 算力平台 · 主流大模型 1 折价 · 省 90%</span>
            </span>
          </span>
          <svg className="ad-arrow" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="M7 17 17 7" />
            <path d="M7 7h10v10" />
          </svg>
        </a>
      </footer>
    </div>
  )
}
