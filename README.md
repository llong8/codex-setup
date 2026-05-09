# Haivex Codex Setup

一键把 Codex CLI 接到 Haivex API 的 Electron 桌面工具。

## 它做什么

输入一个 OpenAI API Key,点保存,自动:

1. **追加 / 更新** `~/.codex/config.toml` —— 配置 model、provider、base_url
2. **合并写入** `~/.codex/auth.json` —— 写入 `OPENAI_API_KEY`,保留其他字段

幂等:重复运行只会覆盖管理块(`# === haivex-codex-setup BEGIN/END ===` 之间),不会重复堆积。

如果 `~/.codex/` 不存在,会提示先安装 Codex 客户端。

## 开发

```bash
bun i
bun dev
```

## 打包(后续)

暂未配置 electron-builder。需要发布安装包时再加。
