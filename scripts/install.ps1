# InteNext.ai 算力平台 — Codex 配置脚本(PowerShell 版)
#
# 用法:
#   iex (irm https://api.intenext.ai/install.ps1)
#   $env:INTENEXT_KEY = "sk-yourkey"; iex (irm https://api.intenext.ai/install.ps1)
#
# 行为与 install.sh 完全等价:
#   1. 幂等更新 %USERPROFILE%\.codex\config.toml(剥离旧管理块 + 重排顶层 key)
#   2. 合并写入 %USERPROFILE%\.codex\auth.json 的 OPENAI_API_KEY
#   3. 写入前备份原文件到 .bak,失败可一秒回滚

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# ─── 颜色定义 ──────────────────────────────────────────
$ESC = [char]27
try { $useColor = $Host.UI.SupportsVirtualTerminal } catch { $useColor = $true }

function c { param($code) if ($useColor) { return "${ESC}[${code}m" } else { return '' } }
function tc { param($r, $g, $b) if ($useColor) { return "${ESC}[38;2;${r};${g};${b}m" } else { return '' } }

$OFF = c '0';  $DIM = c '2';  $BLD = c '1'
$RED = c '31'; $GRN = c '32'; $YEL = c '33'
$BLU = c '38;5;75';  $CYN = c '38;5;87'
$PUR = c '38;5;141'; $PNK = c '38;5;213'; $GLD = c '38;5;220'
$UND = c '4'

# 5 色品牌渐变站(蓝→紫→粉→金→青)
$STOPS = @(
    @(74, 158, 255),    # blue
    @(154,  74, 255),   # purple
    @(255,  74, 154),   # pink
    @(255, 170,  74),   # gold
    @( 74, 220, 255)    # cyan
)

function Get-GradientColor {
    param([double]$t)
    if ($t -le 0) { return $STOPS[0] }
    if ($t -ge 1) { return $STOPS[-1] }
    $pos = $t * ($STOPS.Count - 1)
    $i = [Math]::Floor($pos)
    $f = $pos - $i
    $a = $STOPS[$i]; $b = $STOPS[$i + 1]
    return @(
        [int]($a[0] + ($b[0] - $a[0]) * $f),
        [int]($a[1] + ($b[1] - $a[1]) * $f),
        [int]($a[2] + ($b[2] - $a[2]) * $f)
    )
}

function Get-VisualWidth {
    param([string]$s)
    # 剥 ANSI 后逐字符计算显示宽度(CJK 全宽 = 2,其余 = 1)
    $plain = $s -replace "$ESC\[[0-9;]*m", ''
    $w = 0
    foreach ($ch in $plain.ToCharArray()) {
        $code = [int]$ch
        if (($code -ge 0x1100 -and $code -le 0x115F) -or
            ($code -ge 0x2E80 -and $code -le 0x9FFF) -or
            ($code -ge 0xA000 -and $code -le 0xA4CF) -or
            ($code -ge 0xAC00 -and $code -le 0xD7A3) -or
            ($code -ge 0xF900 -and $code -le 0xFAFF) -or
            ($code -ge 0xFE30 -and $code -le 0xFE4F) -or
            ($code -ge 0xFF00 -and $code -le 0xFF60) -or
            ($code -ge 0xFFE0 -and $code -le 0xFFE6)) {
            $w += 2
        } else {
            $w += 1
        }
    }
    return $w
}

function Get-Brand {
    $text = 'InteNext AI'
    $out = $BLD
    for ($i = 0; $i -lt $text.Length; $i++) {
        $ch = $text[$i]
        if ($ch -eq ' ') {
            $out += $ch
        } else {
            $rgb = Get-GradientColor ($i / ($text.Length - 1))
            $out += (tc $rgb[0] $rgb[1] $rgb[2]) + $ch
        }
    }
    $out += "$OFF $DIM(下一代 AI 算力平台)$OFF"
    return $out
}

# ─── 通用渐变方框渲染器 ────────────────────────────────
function Show-GradientBox {
    param([string[]]$Lines, [int]$Width = 50)

    $gradBorder = {
        param($cornerL, $fill, $cornerR)
        $startRgb = Get-GradientColor 0
        $endRgb   = Get-GradientColor 1
        $s = (tc $startRgb[0] $startRgb[1] $startRgb[2]) + $cornerL
        for ($i = 0; $i -lt $Width; $i++) {
            $rgb = Get-GradientColor ($i / ($Width - 1))
            $s += (tc $rgb[0] $rgb[1] $rgb[2]) + $fill
        }
        $s += "$OFF$(tc $endRgb[0] $endRgb[1] $endRgb[2])$cornerR$OFF"
        return $s
    }

    $total = $Lines.Count

    Write-Host ''
    Write-Host "  $(& $gradBorder '┌' '─' '┐')"
    for ($i = 0; $i -lt $total; $i++) {
        $line = $Lines[$i]
        $w = Get-VisualWidth $line
        $pad = $Width - 2 - $w
        if ($pad -lt 0) { $pad = 0 }
        $leftRgb = Get-GradientColor ($i / [Math]::Max($total - 1, 1))
        $rightIdx = ($i + [Math]::Floor($total / 2)) % $total
        $rightRgb = Get-GradientColor ($rightIdx / [Math]::Max($total - 1, 1))
        $sideL = tc $leftRgb[0]  $leftRgb[1]  $leftRgb[2]
        $sideR = tc $rightRgb[0] $rightRgb[1] $rightRgb[2]
        $spaces = ' ' * $pad
        Write-Host "  ${sideL}│${OFF}  $line${spaces}${sideR}│${OFF}"
    }
    Write-Host "  $(& $gradBorder '└' '─' '┘')"
    Write-Host ''
}

# ─── 头部 ── 渐变方框,行间留呼吸 ──────────────────────
function Show-Header {
    $brand = Get-Brand
    Show-GradientBox -Lines @(
        '',
        $brand,
        '',
        "${CYN}${UND}https://api.intenext.ai${OFF}",
        '',
        "${DIM}主流大模型 API · 1 折价开箱即用${OFF}",
        ''
    ) -Width 72
}

# ─── 营销面板(渐变边框)── 品牌 + 卖点 + CTA 一框搞定 ──
function Show-Promo {
    $brand = Get-Brand
    Show-GradientBox -Lines @(
        '',
        $brand,
        "${DIM}主流大模型 API · 1 折价开箱即用${OFF}",
        '',
        "${BLU}▸${OFF}  主流大模型 ${GLD}${BLD}1 折价${OFF} · 省 ${GLD}${BLD}90%${OFF} 成本",
        "${BLU}▸${OFF}  推理 ${CYN}${BLD}10×${OFF} 加速 · ${CYN}${BLD}1s${OFF} 出图 · ${CYN}${BLD}100ms${OFF} 语音",
        "${BLU}▸${OFF}  语言:GPT-5.5 / Claude 4.7 / Gemini 3.1 / DeepSeek",
        "${BLU}▸${OFF}  创作:Veo 3.1 / GPT Image 2 / SD 3.5",
        "${BLU}▸${OFF}  新模型 ${GRN}${BLD}0 时差上线${OFF}",
        "${BLU}▸${OFF}  注册即送 · ${GLD}${BLD}0 门槛试用${OFF}",
        "${BLU}▸${OFF}  支持 ${GLD}${BLD}10000+${OFF} 并发 · ${BLD}企业级定制${OFF}详询淘宝旗舰店",
        '',
        # 算力平台 4 字 + 4 sp vs 淘宝旗舰店 5 字 + 2 sp,→ 箭头垂直对齐
        "算力平台    →  ${CYN}${UND}https://api.intenext.ai${OFF}",
        "淘宝旗舰店  →  ${CYN}${UND}https://item.taobao.com/item.htm?ft=t&id=1046050759606${OFF}",
        ''
    ) -Width 72
}

# ─── 开始:一个营销面板把品牌 + 卖点 + CTA 全装下 ────────
Show-Promo

$codexDir   = Join-Path $env:USERPROFILE '.codex'
$configFile = Join-Path $codexDir 'config.toml'
$authFile   = Join-Path $codexDir 'auth.json'

if (-not (Test-Path $codexDir)) {
    Write-Host "  ${RED}✗${OFF} 没检测到 Codex(找不到 $codexDir)" -ErrorAction Continue
    Write-Host "  ${DIM}请先安装 Codex 后再运行此命令。${OFF}`n"
    exit 1
}

# ─── 获取 API Key ─────────────────────────────────────
$ApiKey = $env:INTENEXT_KEY
if (-not $ApiKey) {
    Write-Host "  ${CYN}请粘贴你的 API Key,然后按回车${OFF}`n"
    $cols = try { $Host.UI.RawUI.WindowSize.Width } catch { 80 }
    $wid  = [Math]::Min(78, $cols - 4)
    $line = '─' * $wid

    # 先画上下两条线,然后光标上移到中间打字位
    Write-Host "  ${DIM}${line}${OFF}"
    Write-Host "  ${CYN}›${OFF}  "
    Write-Host "  ${DIM}${line}${OFF}"
    # 光标上移 2 行 + 右移 5 列(刚好在 "  ›  " 之后)
    [Console]::Write("${ESC}[2A${ESC}[5C")
    $ApiKey = [Console]::ReadLine()
    # 输入完成后下移 1 行,让后续输出落在下线之下
    [Console]::Write("${ESC}[1B")
}

if (-not $ApiKey) {
    Write-Host "`n  ${RED}✗${OFF} API Key 不能为空`n"
    exit 1
}

Write-Host "`n  ${DIM}正在配置 …${OFF}"

# ─── 备份现有配置 ─────────────────────────────────────
if (Test-Path $configFile) { Copy-Item $configFile "${configFile}.bak" -Force }
if (Test-Path $authFile)   { Copy-Item $authFile   "${authFile}.bak"   -Force }

# ─── 写 config.toml:剥离 + 重排,保证顶层 key 真在顶层 ─
$managedTopKeys = @(
    'model_provider','model','review_model','model_reasoning_effort',
    'disable_response_storage','network_access','windows_wsl_setup_acknowledged'
)
$managedTopBlock = @(
    'model_provider = "OpenAI"',
    'model = "gpt-5.4"',
    'review_model = "gpt-5.4"',
    'model_reasoning_effort = "medium"',
    'disable_response_storage = true',
    'network_access = "enabled"',
    'windows_wsl_setup_acknowledged = true'
) -join "`n"
$managedSectionBlock = @(
    '[model_providers.OpenAI]',
    'name = "OpenAI"',
    'base_url = "https://api.haivex.ai/v1"',
    'wire_api = "responses"',
    'requires_openai_auth = true'
) -join "`n"

$topPart  = New-Object System.Collections.Generic.List[string]
$restPart = New-Object System.Collections.Generic.List[string]
$beforeSection = $true
$inManaged     = $false

if (Test-Path $configFile) {
    $managedKeyPattern = '^\s*(' + ($managedTopKeys -join '|') + ')\s*='
    foreach ($line in Get-Content $configFile) {
        if ($line -match '^\[model_providers\.OpenAI\]\s*$') {
            $inManaged = $true
            $beforeSection = $false
            continue
        }
        if ($line -match '^\[') {
            $inManaged = $false
            $beforeSection = $false
            $restPart.Add($line)
            continue
        }
        if ($inManaged) { continue }
        if ($beforeSection) {
            if ($line -match $managedKeyPattern) { continue }
            $topPart.Add($line)
        } else {
            $restPart.Add($line)
        }
    }
}

# 去尾部空行
while ($topPart.Count -gt 0  -and -not $topPart[$topPart.Count - 1].Trim())   { $topPart.RemoveAt($topPart.Count - 1) }
while ($restPart.Count -gt 0 -and -not $restPart[$restPart.Count - 1].Trim()) { $restPart.RemoveAt($restPart.Count - 1) }

$chunks = New-Object System.Collections.Generic.List[string]
if ($topPart.Count -gt 0)  { $chunks.Add(($topPart  -join "`n")) }
$chunks.Add($managedTopBlock)
if ($restPart.Count -gt 0) { $chunks.Add(($restPart -join "`n")) }
$chunks.Add($managedSectionBlock)
$newContent = ($chunks -join "`n`n") + "`n"

# 写 UTF-8 无 BOM
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($configFile, $newContent, $utf8NoBom)

# ─── 写 auth.json(合并模式,保留其他字段) ────────────
$authData = @{}
if (Test-Path $authFile) {
    try {
        $raw = Get-Content $authFile -Raw -Encoding UTF8
        if ($raw.Trim()) {
            $obj = $raw | ConvertFrom-Json
            $obj.PSObject.Properties | ForEach-Object { $authData[$_.Name] = $_.Value }
        }
    } catch {
        $authData = @{}
    }
}
$authData['OPENAI_API_KEY'] = $ApiKey
$json = ($authData | ConvertTo-Json -Depth 10) + "`n"
[System.IO.File]::WriteAllText($authFile, $json, $utf8NoBom)

# ─── 完成提示 ────────────────────────────────────────
Write-Host "`n  ${GRN}${BLD}✓ 配置完成${OFF}"

# 检测 Codex 是否运行(macOS 名 'Codex',CLI 'codex',Windows 通常 'Codex')
$codexRunning = $false
foreach ($name in @('codex', 'Codex')) {
    if (Get-Process -Name $name -ErrorAction SilentlyContinue) {
        $codexRunning = $true
        break
    }
}

if ($codexRunning) {
    # Windows:Codex 桌面应用关窗口后驻留在系统托盘,必须从托盘退出
    Write-Host "  ${DIM}Codex 正在运行 — 仅关闭窗口不够,应用驻留在系统托盘。${OFF}"
    Write-Host "  ${DIM}请到屏幕${BLD}右下角任务栏${OFF}${DIM}(系统托盘)→ 右键 ${BLD}Codex${OFF}${DIM} 图标 → ${BLD}退出${OFF}${DIM},然后重新打开应用。${OFF}`n"
} else {
    Write-Host "  ${DIM}打开 Codex 即可开始使用 InteNext.ai。${OFF}`n"
}
