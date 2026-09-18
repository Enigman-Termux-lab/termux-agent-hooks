#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Termux Agent Hooks — Stop Notification & Haptic Feedback
# Срабатывает при завершении цикла выполнения агента (Stop event)
# ==============================================================================
set -u

TMP_DIR="${TMPDIR:-${PREFIX:-/data/data/com.termux/files/usr}/tmp}"
[ ! -d "$TMP_DIR" ] && TMP_DIR="/tmp"
START_FILE="${TMP_DIR}/termux_agent_invoke_start"
LEGACY_START_FILE="/tmp/agy_invoke_start"

THRESHOLD_SECONDS=300 # Порог: 5 минут (300 секунд)

# 1. Тактильный виброотклик (32 миллисекунды)
if command -v termux-vibrate >/dev/null 2>&1; then
    termux-vibrate -d 32 -f >/dev/null 2>&1 || true
fi

# 2. Проверяем продолжительность сессии выполнения
ACTIVE_FILE=""
if [ -f "$START_FILE" ]; then
    ACTIVE_FILE="$START_FILE"
elif [ -f "$LEGACY_START_FILE" ]; then
    ACTIVE_FILE="$LEGACY_START_FILE"
fi

if [ -n "$ACTIVE_FILE" ]; then
    START_TIME=$(cat "$ACTIVE_FILE" 2>/dev/null || date +%s)
    CURRENT_TIME=$(date +%s)
    DIFF=$((CURRENT_TIME - START_TIME))

    if [ "$DIFF" -ge "$THRESHOLD_SECONDS" ]; then
        MINS=$((DIFF / 60))
        [ "$MINS" -eq 0 ] && MINS=1

        # Всплывающее уведомление Toast
        if command -v termux-toast >/dev/null 2>&1; then
            termux-toast "AI Agent: Ответ готов! (раздумья: ${MINS} мин)" 2>/dev/null || true
        fi

        # Системный Android Push с кнопкой быстрого возврата в Termux
        if command -v termux-notification >/dev/null 2>&1; then
            termux-notification \
                --id "termux-agent-notify" \
                --title "AI Agent (Termux)" \
                --content "Задача выполнена! Время ожидания: ${MINS} мин." \
                --sound \
                --priority "high" \
                --vibrate 1200 \
                --action "am start -n com.termux/com.termux.app.TermuxActivity" >/dev/null 2>&1 || true
        fi
    fi

    rm -f "$START_FILE" "$LEGACY_START_FILE" 2>/dev/null || true
fi

# Возвращаем положительное решение для рантайма хуков
echo '{"decision": "allow"}'
