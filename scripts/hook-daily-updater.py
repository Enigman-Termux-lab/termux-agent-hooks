#!/usr/bin/env python3
"""
Termux Agent Hooks — PreInvocation Daily Update Reminder
Проверяет интервал (86400 секунд / 24 часа) с последней проверки обновлений
и инжектирует ненавязчивое системное напоминание в диалог агента.
"""

import json
import os
import sys
import time

INTERVAL_SECONDS = 86400  # 24 часа

def get_state_file_path() -> str:
    home = os.environ.get("HOME", "")
    config_dir = os.path.join(home, ".config", "termux-agent-hooks")
    try:
        os.makedirs(config_dir, exist_ok=True)
        return os.path.join(config_dir, "last_update_check.timestamp")
    except Exception:
        return "/tmp/termux_agent_last_update_check.timestamp"

def main():
    # Поглощаем входной JSON из stdin (контракт хуков Antigravity CLI)
    try:
        if not sys.stdin.isatty():
            _ = sys.stdin.read()
    except Exception:
        pass

    state_file = get_state_file_path()
    current_time = int(time.time())
    should_remind = False

    if os.path.exists(state_file):
        try:
            with open(state_file, "r", encoding="utf-8") as f:
                content = f.read().strip()
                last_time = int(content)
                if current_time - last_time >= INTERVAL_SECONDS:
                    should_remind = True
        except Exception:
            should_remind = True
    else:
        should_remind = True

    output = {"injectSteps": []}

    if should_remind:
        try:
            with open(state_file, "w", encoding="utf-8") as f:
                f.write(str(current_time))
        except Exception:
            pass

        output["injectSteps"].append({
            "ephemeralMessage": (
                "⏰ [Daily Maintenance Reminder] Прошли сутки с момента последней проверки обновлений Termux. "
                "Рекомендуется проверить актуальность пакетов и CLI-агентов с помощью "
                "Enigman-Termux-lab/lab-auto-updater (скрипт update_all.sh) или команды pkg update."
            )
        })

    print(json.dumps(output, ensure_ascii=False))

if __name__ == "__main__":
    main()
