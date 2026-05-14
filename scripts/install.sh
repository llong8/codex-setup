#!/usr/bin/env bash
#
# Codex Setup × InteNext.ai — 一键把 Codex 接入 InteNext 算力平台
#
# 用法:
#   curl -fsSL https://api.intenext.ai/install | bash
#   curl -fsSL https://api.intenext.ai/install | bash -s -- sk-yourkey
#

set -euo pipefail

# ─── 颜色(终端才上色;支持 256/truecolor) ──────────────
if [[ -t 1 ]]; then
  IS_TTY=1
  C_OFF=$'\033[0m'
  C_DIM=$'\033[2m'
  C_BLD=$'\033[1m'
  C_RED=$'\033[31m'
  C_GRN=$'\033[32m'
  C_YEL=$'\033[33m'
  C_BLU=$'\033[38;5;75m'    # 浅蓝
  C_CYN=$'\033[38;5;87m'    # 青绿
  C_PUR=$'\033[38;5;141m'   # 紫
  C_PNK=$'\033[38;5;213m'   # 玫粉
  C_GLD=$'\033[38;5;220m'   # 琥珀金
  C_UND=$'\033[4m'
else
  IS_TTY=0
  C_OFF='' C_DIM='' C_BLD='' C_RED='' C_GRN='' C_YEL='' \
  C_BLU='' C_CYN='' C_PUR='' C_PNK='' C_GLD='' C_UND=''
fi

CODEX_DIR="${HOME}/.codex"
CONFIG_FILE="${CODEX_DIR}/config.toml"
AUTH_FILE="${CODEX_DIR}/auth.json"

# ─── 渐变 logo:InteNext AI(下一代 AI 算力平台),5 色主题 ─
brand_logo() {
  printf '%sI%sn%st%se%sN%se%sx%st%s %sAI%s' \
    "$C_BLU" "$C_BLU" "$C_PUR" "$C_PUR" "$C_PNK" "$C_PNK" "$C_GLD" "$C_GLD" "$C_OFF" \
    "$C_CYN" "$C_OFF"
  printf ' %s(下一代 AI 算力平台)%s' "$C_DIM" "$C_OFF"
}

# ─── 头部 ── 渐变方框,跟底部促销框同款 ────────────────
print_header() {
  if command -v python3 >/dev/null 2>&1; then
    PROMO_COLOR="$IS_TTY" python3 - <<'PY'
import os, re, unicodedata

COLOR = os.environ.get('PROMO_COLOR') == '1'
def c(code): return f'\x1b[{code}m' if COLOR else ''
def tc(r, g, b): return f'\x1b[38;2;{r};{g};{b}m' if COLOR else ''

OFF = c('0');   DIM = c('2');   BLD = c('1')
CYN = c('38;5;87'); UND = c('4')

# 5 色渐变站(与底部促销框同一色谱)
STOPS = [
    (74, 158, 255),   (154,  74, 255),   (255,  74, 154),
    (255, 170,  74),  ( 74, 220, 255),
]
def gradient(t):
    if t <= 0: return STOPS[0]
    if t >= 1: return STOPS[-1]
    pos = t * (len(STOPS) - 1)
    i = int(pos); f = pos - i
    a, b = STOPS[i], STOPS[i+1]
    return tuple(int(a[k] + (b[k] - a[k]) * f) for k in range(3))

ANSI = re.compile(r'\x1b\[[0-9;]*m')
def w(s):
    plain = ANSI.sub('', s)
    return sum(2 if unicodedata.east_asian_width(ch) in ('W', 'F') else 1 for ch in plain)

def brand():
    # "InteNext AI" 渐变 + dim 副标题
    text = 'InteNext AI'
    out = BLD
    for i, ch in enumerate(text):
        if ch == ' ':
            out += ch
        else:
            out += tc(*gradient(i / (len(text) - 1))) + ch
    out += f'{OFF} {DIM}(下一代 AI 算力平台){OFF}'
    return out

# 每行之间夹一行空字符串,营造呼吸感
lines = [
    '',
    f'{brand()}',
    '',
    f'{CYN}{UND}https://api.intenext.ai{OFF}',
    '',
    f'{DIM}主流大模型 API · 1 折价开箱即用{OFF}',
    '',
]

WIDTH = 72

def grad_h(corner_l, fill, corner_r):
    parts = [tc(*gradient(0)) + corner_l]
    for i in range(WIDTH):
        parts.append(tc(*gradient(i / (WIDTH - 1))) + fill)
    parts.append(f'{OFF}{tc(*gradient(1.0))}{corner_r}{OFF}')
    return ''.join(parts)

def side(row, total):
    return tc(*gradient(row / max(total - 1, 1)))

padded = lines
total = len(padded)

print()
print(f'  {grad_h("┌", "─", "┐")}')
for idx, line in enumerate(padded):
    pad = WIDTH - 2 - w(line)
    if pad < 0: pad = 0
    sl = side(idx, total)
    sr = side((idx + total // 2) % total, total)
    print(f'  {sl}│{OFF}  {line}{" " * pad}{sr}│{OFF}')
print(f'  {grad_h("└", "─", "┘")}')
print()
PY
  else
    # 无 python3:降级回单色横线头(老样式)
    printf '\n'
    printf '  %s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n' "$C_DIM" "$C_OFF"
    printf '  '
    brand_logo
    printf '\n'
    printf '  %s%shttps://api.intenext.ai%s\n' "$C_CYN" "$C_UND" "$C_OFF"
    printf '  %sAI 算力平台 · 主流大模型 API · 1 折价开箱即用%s\n' "$C_DIM" "$C_OFF"
    printf '  %s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n' "$C_DIM" "$C_OFF"
    printf '\n'
  fi
}

# ─── 促销面板(完成后展示)── 方框版,100%% InteNext.ai 自身广告。
#     用 Python 精确计算 CJK 宽字符显示宽度,保证右边框对齐;
#     无 python3 时降级回纯左侧栏版本。
print_promo() {
  if command -v python3 >/dev/null 2>&1; then
    PROMO_COLOR="$IS_TTY" python3 - <<'PY'
import os, re, unicodedata

COLOR = os.environ.get('PROMO_COLOR') == '1'
def c(code): return f'\x1b[{code}m' if COLOR else ''
def tc(r, g, b): return f'\x1b[38;2;{r};{g};{b}m' if COLOR else ''

OFF = c('0');   DIM = c('2');   BLD = c('1')
GRN = c('32');  BLU = c('38;5;75');  CYN = c('38;5;87')
PUR = c('38;5;141'); PNK = c('38;5;213'); GLD = c('38;5;220')
UND = c('4')

ANSI = re.compile(r'\x1b\[[0-9;]*m')
def w(s):
    plain = ANSI.sub('', s)
    return sum(2 if unicodedata.east_asian_width(ch) in ('W', 'F') else 1 for ch in plain)

# 5 色品牌渐变色站(蓝 → 紫 → 粉 → 金 → 青),用于真彩色渐变插值
STOPS = [
    (74, 158, 255),    # blue
    (154,  74, 255),   # purple
    (255,  74, 154),   # pink
    (255, 170,  74),   # gold
    ( 74, 220, 255),   # cyan
]

def gradient(t):
    """t ∈ [0,1] → 在 5 个色站之间线性插值"""
    if t <= 0: return STOPS[0]
    if t >= 1: return STOPS[-1]
    pos = t * (len(STOPS) - 1)
    i = int(pos)
    f = pos - i
    a, b = STOPS[i], STOPS[i+1]
    return tuple(int(a[k] + (b[k] - a[k]) * f) for k in range(3))

# 品牌 logo:沿渐变站取 5 段颜色
def brand():
    text = 'InteNext AI'
    out = BLD
    for i, ch in enumerate(text):
        if ch == ' ':
            out += ch
        else:
            out += tc(*gradient(i / (len(text) - 1))) + ch
    out += f'{OFF} {DIM}(下一代 AI 算力平台){OFF}'
    return out

lines = [
    '',
    f'{brand()}',
    f'{DIM}主流大模型 API · 1 折价开箱即用{OFF}',
    '',
    f'{BLU}▸{OFF}  主流大模型 {GLD}{BLD}1 折价{OFF} · 省 {GLD}{BLD}90%{OFF} 成本',
    f'{BLU}▸{OFF}  推理 {CYN}{BLD}10×{OFF} 加速 · {CYN}{BLD}1s{OFF} 出图 · {CYN}{BLD}100ms{OFF} 语音',
    f'{BLU}▸{OFF}  语言:GPT-5.5 / Claude 4.7 / Gemini 3.1 / DeepSeek',
    f'{BLU}▸{OFF}  创作:Veo 3.1 / GPT Image 2 / SD 3.5',
    f'{BLU}▸{OFF}  新模型 {GRN}{BLD}0 时差上线{OFF}',
    f'{BLU}▸{OFF}  注册即送 · {GLD}{BLD}0 门槛试用{OFF}',
    '',
    # 多 4 空格让"控制台"和"淘宝旗舰店"的 → 箭头对齐(中文 2 列对齐补位)
    f'控制台      →  {CYN}{UND}https://api.intenext.ai{OFF}',
    f'淘宝旗舰店  →  {CYN}{UND}https://item.taobao.com/item.htm?ft=t&id=1046050759606{OFF}',
    '',
]

WIDTH = 72   # 内部宽度

# ─ 横向渐变 ─:每个 ─ 自身的颜色按列号在 STOPS 上插值
def grad_h(corner_l, fill, corner_r):
    parts = [corner_l]
    for i in range(WIDTH):
        parts.append(tc(*gradient(i / (WIDTH - 1))) + fill)
    parts.append(f'{OFF}{tc(*gradient(1.0))}{corner_r}{OFF}')
    # 角的颜色按所在位置取
    return tc(*gradient(0)) + parts[0] + ''.join(parts[1:])

# 每一行左/右 │ 的颜色按行号(垂直方向再一次穿越渐变)
def side(row, total):
    return tc(*gradient(row / max(total - 1, 1)))

total_rows = len(lines)

print()
print(f'  {grad_h("┌", "─", "┐")}')
for idx, line in enumerate(lines):
    pad = WIDTH - 2 - w(line)
    if pad < 0: pad = 0
    side_l = side(idx, total_rows)
    # 右侧 │ 用同样色但稍微错相位,让左右像两条独立彩带
    side_r = side((idx + total_rows // 2) % total_rows, total_rows)
    print(f'  {side_l}│{OFF}  {line}{" " * pad}{side_r}│{OFF}')
print(f'  {grad_h("└", "─", "┘")}')
print()
PY
  else
    # python3 不在 → 降级为左侧栏(老版本)
    local BAR=$'\xe2\x96\x8e'
    printf '\n'
    printf '  %s%s%s  %s✓ 配置已完成%s\n' "$C_PNK" "$BAR" "$C_OFF" "$C_GRN$C_BLD" "$C_OFF"
    printf '  %s%s%s  ' "$C_PNK" "$BAR" "$C_OFF"
    brand_logo
    printf '  %s—  AI 算力平台%s\n' "$C_DIM" "$C_OFF"
    printf '  %s%s%s  %s%shttps://api.intenext.ai%s\n' "$C_PNK" "$BAR" "$C_OFF" "$C_CYN" "$C_UND" "$C_OFF"
    printf '  %s%s%s\n' "$C_PNK" "$BAR" "$C_OFF"
    printf '  %s%s%s  %s▸%s  主流大模型 API %s1 折价%s · 省 90%%\n' "$C_PUR" "$BAR" "$C_OFF" "$C_BLU" "$C_OFF" "$C_GLD$C_BLD" "$C_OFF"
    printf '  %s%s%s  %s▸%s  支持 GPT-5 / Claude / Gemini 等主流模型\n' "$C_PUR" "$BAR" "$C_OFF" "$C_BLU" "$C_OFF"
    printf '  %s%s%s  %s▸%s  支持 GPT Image 2 / Nano Banana 等生图模型\n' "$C_PUR" "$BAR" "$C_OFF" "$C_BLU" "$C_OFF"
    printf '  %s%s%s  %s▸%s  自建高速节点 · 延迟 %s低 70%%%s\n' "$C_PUR" "$BAR" "$C_OFF" "$C_BLU" "$C_OFF" "$C_CYN$C_BLD" "$C_OFF"
    printf '  %s%s%s  %s▸%s  新模型 %s0 时差上线%s\n' "$C_PUR" "$BAR" "$C_OFF" "$C_BLU" "$C_OFF" "$C_GRN$C_BLD" "$C_OFF"
    printf '  %s%s%s  %s▸%s  注册即送 · %s0 门槛试用%s\n' "$C_PUR" "$BAR" "$C_OFF" "$C_BLU" "$C_OFF" "$C_GLD$C_BLD" "$C_OFF"
    printf '  %s%s%s  控制台  %s→%s  %s%shttps://api.intenext.ai%s\n' "$C_BLU" "$BAR" "$C_OFF" "$C_DIM" "$C_OFF" "$C_CYN" "$C_UND" "$C_OFF"
    printf '\n'
  fi
}

# ─── 开始:一个营销面板把品牌 + 卖点 + CTA 全装下 ────────
print_promo

# ─── 检查 Codex 是否安装 ────────────────────────────────
if [[ ! -d "$CODEX_DIR" ]]; then
  printf '  %s✗%s 没检测到 Codex(找不到 ~/.codex 目录)\n'      "$C_RED" "$C_OFF" >&2
  printf '  %s请先安装 Codex 后再运行此命令。%s\n\n'            "$C_DIM" "$C_OFF" >&2
  exit 1
fi

# ─── 获取 API Key ───────────────────────────────────────
API_KEY="${1:-}"
if [[ -z "$API_KEY" ]]; then
  if [[ -t 0 ]]; then
    TTY_IN="/dev/stdin"
  elif [[ -r /dev/tty ]]; then
    TTY_IN="/dev/tty"
  else
    printf '  %s✗%s 当前环境无法交互输入,请这样跑:\n'                              "$C_RED" "$C_OFF" >&2
    printf '  %s  curl -fsSL https://api.intenext.ai/install | bash -s -- sk-yourkey%s\n\n' "$C_DIM" "$C_OFF" >&2
    exit 1
  fi
  printf '  %s请粘贴你的 API Key,然后按回车%s\n\n' "$C_CYN" "$C_OFF"

  # 自适应终端宽度,封顶 78 列(像 Claude Code 那样)
  COLS=$(tput cols 2>/dev/null || echo 80)
  WID=$(( COLS > 80 ? 78 : COLS - 4 ))
  LINE=$(printf '%*s' "$WID" '' | tr ' ' '─')

  # 先把上、中、下三行画好,然后光标向上 2 行回到中间行 + 右移 5 列(刚好在 "  ›  " 之后)
  printf '  %s%s%s\n' "$C_DIM" "$LINE" "$C_OFF"   # 上线
  printf '  %s›%s  \n' "$C_CYN" "$C_OFF"           # 中间(提示符)
  printf '  %s%s%s\n' "$C_DIM" "$LINE" "$C_OFF"   # 下线
  printf '\033[2A\033[5C'                          # 光标回到 "  ›  " 之后

  read -r API_KEY <"$TTY_IN"

  # 回车后光标在下线那一行的开头;再下移 1 行,让后续输出在下线之下
  printf '\033[1B'
fi

if [[ -z "$API_KEY" ]]; then
  printf '\n  %s✗%s API Key 不能为空\n\n' "$C_RED" "$C_OFF" >&2
  exit 1
fi

printf '\n  %s正在配置 …%s\n' "$C_DIM" "$C_OFF"

# ─── 备份 ────────────────────────────────────────────────
[[ -f "$CONFIG_FILE" ]] && cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
[[ -f "$AUTH_FILE" ]]   && cp "$AUTH_FILE"   "${AUTH_FILE}.bak"

# ─── 写 config.toml(剥离 + 重排) ─────────────────────
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

if [[ -f "$CONFIG_FILE" ]]; then
  awk '
    BEGIN { before = 1; in_managed = 0; top = ""; rest = "" }
    /^\[model_providers\.OpenAI\][ \t]*$/ { in_managed = 1; before = 0; next }
    /^\[/ { in_managed = 0; before = 0; rest = rest $0 "\n"; next }
    in_managed { next }
    before {
      if ($0 ~ /^[ \t]*(model_provider|model|review_model|model_reasoning_effort|disable_response_storage|network_access|windows_wsl_setup_acknowledged)[ \t]*=/) next
      top = top $0 "\n"; next
    }
    { rest = rest $0 "\n" }
    END {
      sub(/[ \t\n]+$/, "", top); sub(/[ \t\n]+$/, "", rest)
      if (length(top) > 0) printf "%s\n\n", top
      print "model_provider = \"OpenAI\""
      print "model = \"gpt-5.4\""
      print "review_model = \"gpt-5.4\""
      print "model_reasoning_effort = \"medium\""
      print "disable_response_storage = true"
      print "network_access = \"enabled\""
      print "windows_wsl_setup_acknowledged = true"
      if (length(rest) > 0) printf "\n%s\n", rest
      print ""
      print "[model_providers.OpenAI]"
      print "name = \"OpenAI\""
      print "base_url = \"https://api.haivex.ai/v1\""
      print "wire_api = \"responses\""
      print "requires_openai_auth = true"
    }
  ' "$CONFIG_FILE" > "$TMPFILE"
else
  cat > "$TMPFILE" <<'EOF'
model_provider = "OpenAI"
model = "gpt-5.4"
review_model = "gpt-5.4"
model_reasoning_effort = "medium"
disable_response_storage = true
network_access = "enabled"
windows_wsl_setup_acknowledged = true

[model_providers.OpenAI]
name = "OpenAI"
base_url = "https://api.haivex.ai/v1"
wire_api = "responses"
requires_openai_auth = true
EOF
fi
mv "$TMPFILE" "$CONFIG_FILE"
trap - EXIT

# ─── 写 auth.json ────────────────────────────────────────
if command -v python3 >/dev/null 2>&1; then
  HAIVEX_KEY="$API_KEY" python3 - <<'PY'
import json, os
auth_file = os.path.expanduser('~/.codex/auth.json')
key = os.environ['HAIVEX_KEY']
data = {}
if os.path.exists(auth_file):
    try:
        with open(auth_file) as f:
            content = f.read().strip()
            if content:
                parsed = json.loads(content)
                if isinstance(parsed, dict):
                    data = parsed
    except Exception:
        data = {}
data['OPENAI_API_KEY'] = key
with open(auth_file, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
PY
elif command -v jq >/dev/null 2>&1 && [[ -f "$AUTH_FILE" ]]; then
  jq --arg k "$API_KEY" '. + {OPENAI_API_KEY: $k}' "$AUTH_FILE" > "${AUTH_FILE}.tmp"
  mv "${AUTH_FILE}.tmp" "$AUTH_FILE"
else
  cat > "$AUTH_FILE" <<EOF
{
  "OPENAI_API_KEY": "${API_KEY}"
}
EOF
fi
chmod 600 "$AUTH_FILE"

# ─── 完成提示 ────────────────────────────────────────────
printf '\n  %s✓ 配置完成%s\n' "$C_GRN$C_BLD" "$C_OFF"

CODEX_RUNNING=0
if command -v pgrep >/dev/null 2>&1; then
  pgrep -x codex >/dev/null 2>&1 && CODEX_RUNNING=1
fi

if [[ "$CODEX_RUNNING" == "1" ]]; then
  printf '  %sCodex 正在运行,请%s关闭并重新打开 Codex%s 即可生效。%s\n\n' \
         "$C_DIM" "$C_BLD$C_OFF$C_DIM" "$C_DIM" "$C_OFF"
else
  printf '  %s打开 Codex 即可开始使用。%s\n\n' "$C_DIM" "$C_OFF"
fi
