#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Termux Agent Hooks — PreInvocation Timer Start
# Засекает время старта генерации/инвокации агента
# ==============================================================================
set -u

# Определяем временный каталог с поддержкой специфики Termux ($TMPDIR / $PREFIX/tmp)
TMP_DIR="${TMPDIR:-${PREFIX:-/data/data/com.termux/files/usr}/tmp}"
[ ! -d "$TMP_DIR" ] && TMP_DIR="/tmp"
[ -d "$TMP_DIR" ] || mkdir -p "$TMP_DIR" 2>/dev/null || true

START_FILE="${TMP_DIR}/termux_agent_invoke_start"

# Сохраняем временную метку старта
date +%s > "$START_FILE" 2>/dev/null || true
# Также пишем в традиционный путь, если он доступен
[ -d "/tmp" ] && date +%s > "/tmp/agy_invoke_start" 2>/dev/null || true

# Возвращаем положительное решение для рантайма хуков
echo '{"decision": "allow"}'
