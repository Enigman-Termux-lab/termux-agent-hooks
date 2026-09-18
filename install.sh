#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Termux Agent Hooks — Installer
# Устанавливает хуки в ~/.config/termux-agent-hooks/ и подключает их к агентам
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.config/termux-agent-hooks"
AGY_CONFIG_DIR="${HOME}/.gemini/antigravity-cli"
AGY_HOOKS_FILE="${AGY_CONFIG_DIR}/hooks.json"

echo "=================================================="
echo "🪝  Установка Termux Agent Hooks"
echo "=================================================="

# 1. Проверка системных пакетов Termux
echo "🔍 Проверка системных зависимостей..."
MISSING_PKGS=()

for pkg in termux-api jq python; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo "📦 Установка недостающих пакетов: ${MISSING_PKGS[*]}..."
    pkg update -y && pkg install -y "${MISSING_PKGS[@]}"
fi

echo "ℹ️  Убедитесь, что Android-приложение Termux:API установлено (F-Droid) и ему выданы разрешения на уведомления и биометрию."

# 2. Создание целевых каталогов и копирование файлов
echo "📂 Копирование хуков в ${TARGET_DIR}..."
mkdir -p "${TARGET_DIR}/scripts"
mkdir -p "${TARGET_DIR}/configs"

cp -r "${SCRIPT_DIR}/scripts/"* "${TARGET_DIR}/scripts/"
cp -r "${SCRIPT_DIR}/configs/"* "${TARGET_DIR}/configs/"
chmod +x "${TARGET_DIR}/scripts/"*

# 3. Интеграция с Antigravity CLI (~/.gemini/antigravity-cli/hooks.json)
echo "⚙️ Настройка конфигурации хуков Antigravity CLI..."
mkdir -p "${AGY_CONFIG_DIR}"

python3 - <<EOF
import json
import os

hooks_file = "${AGY_HOOKS_FILE}"
template_file = "${TARGET_DIR}/configs/antigravity-hooks.json"

with open(template_file, "r", encoding="utf-8") as f:
    template_data = json.load(f)

current_data = {}
if os.path.exists(hooks_file):
    try:
        with open(hooks_file, "r", encoding="utf-8") as f:
            current_data = json.load(f)
    except Exception:
        current_data = {}

# Безопасное объединение: обновляем секцию termux-agent-hooks
current_data["termux-agent-hooks"] = template_data["termux-agent-hooks"]

with open(hooks_file, "w", encoding="utf-8") as f:
    json.dump(current_data, f, indent=2, ensure_ascii=False)
    f.write("\n")

print("✅ Файл конфигурации hooks.json успешно обновлён.")
EOF

echo ""
echo "🎉 Установка успешно завершена!"
echo "📁 Хуки размещены в: ${TARGET_DIR}/scripts"
echo "⚙️ Antigravity CLI: хуки активированы в ${AGY_HOOKS_FILE}"
echo ""
echo "💡 Для подключения в Claude Code скопируйте секцию hooks из:"
echo "   ${TARGET_DIR}/configs/claude-settings.json"
echo "   в ваш файл ~/.claude/settings.json"
echo "=================================================="
