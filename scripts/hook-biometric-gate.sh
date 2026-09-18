#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Termux Agent Hooks — PreToolUse Biometric Security Gate
# Защита от деструктивных команд через биометрию termux-fingerprint
# Поддерживает Antigravity CLI и Claude Code
# ==============================================================================
set -u

payload="$(cat)"

# Определяем среду вызова (Claude Code использует .tool_name, Antigravity CLI использует .toolCall)
is_claude=false
if printf '%s' "$payload" | jq -e '.tool_name' >/dev/null 2>&1; then
    is_claude=true
fi

# Извлекаем команду из входного JSON
if command -v jq >/dev/null 2>&1; then
    cmd="$(printf '%s' "$payload" | jq -r '(.toolCall.args.CommandLine // .tool_input.command // .command // .CommandLine // empty)' 2>/dev/null)"
else
    cmd="$payload"
fi

if [ -z "$cmd" ]; then
    if [ "$is_claude" = true ]; then
        exit 0
    else
        echo '{"decision": "allow"}'
        exit 0
    fi
fi

# Шаблоны опасных и деструктивных операций
patterns=(
    'rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r|-rf|-fr|--recursive)'
    'git[[:space:]]+push[[:space:]].*(--force|--force-with-lease|-f([[:space:]]|$))'
    'git[[:space:]]+reset[[:space:]]+.*--hard'
    'git[[:space:]]+clean[[:space:]]+.*-[a-zA-Z]*f'
    'git[[:space:]]+branch[[:space:]]+.*-D'
    '\bdd[[:space:]]+if='
    '\bmkfs\b'
    '>[[:space:]]*/dev/(sd|nvme|mmcblk|block)'
    '\bDROP[[:space:]]+(TABLE|DATABASE|SCHEMA)\b'
    '\bTRUNCATE[[:space:]]+TABLE\b'
    ':\(\)\s*\{' # fork-bomb
)

matched=""
for p in "${patterns[@]}"; do
    if printf '%s' "$cmd" | grep -qEi "$p"; then
        matched="$p"
        break
    fi
done

# Если опасных паттернов не найдено — разрешаем выполнение
if [ -z "$matched" ]; then
    if [ "$is_claude" = true ]; then
        exit 0
    else
        echo '{"decision": "allow"}'
        exit 0
    fi
fi

# Если утилита termux-fingerprint недоступна
if ! command -v termux-fingerprint >/dev/null 2>&1; then
    if [ "$is_claude" = true ]; then
        echo "Внимание: обнаружена опасная команда, но termux-fingerprint не установлен: $cmd" >&2
        exit 2
    else
        echo '{"decision": "force_ask", "reason": "Обнаружена потенциально опасная команда, но termux-fingerprint недоступен. Требуется ручное подтверждение."}'
        exit 0
    fi
fi

# Предупреждающий тактильный сигнал
command -v termux-vibrate >/dev/null 2>&1 && termux-vibrate -d 50 -f >/dev/null 2>&1 || true

# Запрос биометрического подтверждения через аппаратный сенсор
short_cmd="$(printf '%s' "$cmd" | tr '\n' ' ' | head -c 70)"
result="$(termux-fingerprint -t "AI Agent: Biometric Confirmation" -d "Подтвердите выполнение: $short_cmd" 2>/dev/null)"
auth=""
if command -v jq >/dev/null 2>&1; then
    auth="$(printf '%s' "$result" | jq -r '.auth_result // empty' 2>/dev/null)"
else
    if echo "$result" | grep -q "AUTH_RESULT_SUCCESS"; then
        auth="AUTH_RESULT_SUCCESS"
    fi
fi

if [ "$auth" = "AUTH_RESULT_SUCCESS" ]; then
    command -v termux-vibrate >/dev/null 2>&1 && termux-vibrate -d 20 -f >/dev/null 2>&1 || true
    if [ "$is_claude" = true ]; then
        exit 0
    else
        echo '{"decision": "allow"}'
        exit 0
    fi
else
    if [ "$is_claude" = true ]; then
        echo "Операция отклонена: биометрическое подтверждение не пройдено ($auth). Команда: $cmd" >&2
        exit 2
    else
        echo '{"decision": "deny", "reason": "Операция заблокирована: биометрическое подтверждение не пройдено"}'
        exit 0
    fi
fi
