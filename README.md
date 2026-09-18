<div align="center">

# 🪝 Termux Agent Hooks

### *Набор рекомендованных аппаратных, защитных и сервисных хуков для AI-агентов в Android Termux*

[![Termux](https://img.shields.io/badge/Termux-Android-000000?style=for-the-badge&logo=termux&logoColor=white)](https://termux.dev/)
[![Termux:API](https://img.shields.io/badge/Termux-API-FF8C00?style=for-the-badge&logo=android&logoColor=white)](https://wiki.termux.com/wiki/Termux:API)
[![Antigravity](https://img.shields.io/badge/Antigravity-AI_Agent-orange?style=for-the-badge&logo=google&logoColor=white)](https://github.com/Enigman-Termux-lab)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Supported-7B61FF?style=for-the-badge&logo=anthropic&logoColor=white)](https://claude.ai)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

<br/>

**Termux Agent Hooks** — модульная коллекция готовых хуков жизненного цикла для автономных AI-ассистентов ([Antigravity CLI](https://github.com/Enigman-Termux-lab), [Claude Code](https://claude.ai), OpenCode) в среде Termux на Android. Инструмент связывает программные циклы агента с физическими возможностями смартфона (вибромотор, биометрический сканер пальца, шторка системных уведомлений Android) и обеспечивает безопасность системы при выполнении автономных команд.

---

</div>

## 📌 Зачем это нужно?

Когда локальный кодинг-агент выполняет автономные задачи на мобильном устройстве:

* 📳 **Тактильный микро-отклик (32 мс):** при каждом завершении генерации ответа (`Stop` event) устройство даёт быстрый мягкий вибро-импульс. Вы физически ощущаете динамику работы агента, даже не глядя на экран.
* 🔔 **Android Push-уведомления при долгих задачах (> 5 мин):** если агент уходит в долгий ресерч, компиляцию или масштабный рефакторинг (300+ секунд), система отправляет системный Push в шторку Android с высоким приоритетом, звуком и вибрацией. Тап по пушу **мгновенно возвращает вас в активное окно Termux**.
* 🛡️ **Биометрический шлюз безопасности (`termux-fingerprint`):** перехват деструктивных и опасных операций (`rm -rf`, `git push --force`, `git reset --hard`, `git clean -f`, `dd if=`, fork-бомбы). Агент не сможет стереть файлы или испортить репозиторий без прикосновения к сканеру отпечатка пальца с нейтральным диалогом подтверждения `AI Agent: Biometric Confirmation`.
* ⏰ **Суточный напоминатель обслуживания (Daily Update Reminder):** интервальный чекер (86400 с), который ненавязчиво инжектирует в системный контекст модели (`injectSteps`) напоминание о проверке свежести среды и пакетов.

---

## 🔗 Связанные проекты

* 🔄 **[Enigman-Termux-lab/termux-auto-updater](https://github.com/Enigman-Termux-lab/termux-auto-updater)** — безопасное автоматическое обновление пакетов Termux, Node.js и CLI-агентов по стандартам `termux-fix-path`.
* 🔔 **[Enigman-Termux-lab/termux-agent-notify](https://github.com/Enigman-Termux-lab/termux-agent-notify)** — специализированный модуль push-уведомлений и тактильного отклика.

---

## 📦 Системные требования

1. Установленный эмулятор терминала [Termux](https://termux.dev/).
2. Пакет `termux-api` и утилиты:
   ```bash
   pkg update -y && pkg install termux-api jq python -y
   ```
3. Приложение [Termux:API](https://f-droid.org/packages/com.termux.api/) из F-Droid (требуется предоставить разрешения на показ уведомлений и биометрию).

---

## ⚡ Быстрая установка

Установка и автоматическая привязка к Antigravity CLI выполняется в 1 команду:

```bash
git clone https://github.com/Enigman-Termux-lab/termux-agent-hooks.git ~/projects/termux-agent-hooks
cd ~/projects/termux-agent-hooks
./install.sh
```

Скрипт `install.sh`:
- Проверит наличие пакетов `termux-api`, `jq`, `python`;
- Разместит скрипты в `$HOME/.config/termux-agent-hooks/scripts/`;
- Сделает их исполняемыми (`chmod +x`);
- Автоматически объединит настройки с вашим `~/.gemini/antigravity-cli/hooks.json`.

---

## ⚙️ Настройка в хуках агентов

### 1. Antigravity CLI (глобально: `~/.gemini/antigravity-cli/hooks.json`)

```json
{
  "termux-agent-hooks": {
    "PreInvocation": [
      {
        "type": "command",
        "command": "bash $HOME/.config/termux-agent-hooks/scripts/hook-timer-start.sh",
        "timeout": 5
      },
      {
        "type": "command",
        "command": "python3 $HOME/.config/termux-agent-hooks/scripts/hook-daily-updater.py",
        "timeout": 10
      }
    ],
    "PreToolUse": [
      {
        "matcher": "run_command",
        "hooks": [
          {
            "type": "command",
            "command": "bash $HOME/.config/termux-agent-hooks/scripts/hook-biometric-gate.sh",
            "timeout": 30
          }
        ]
      }
    ],
    "Stop": [
      {
        "type": "command",
        "command": "bash $HOME/.config/termux-agent-hooks/scripts/hook-notify-stop.sh",
        "timeout": 10
      }
    ]
  }
}
```

*Для уровня отдельного проекта (workspace) используйте файл `.agents/hooks.json` (готовый шаблон доступен в `configs/project-hooks.json`).*

---

### 2. Claude Code (`~/.claude/settings.json`)

Добавьте блок хуков в ваш конфигурационный файл `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash $HOME/.config/termux-agent-hooks/scripts/hook-biometric-gate.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash $HOME/.config/termux-agent-hooks/scripts/hook-notify-stop.sh"
          }
        ]
      }
    ]
  }
}
```

---

## 🛠 Состав хуков

| Скрипт | Событие | Назначение |
|:---|:---|:---|
| [`scripts/hook-timer-start.sh`](scripts/hook-timer-start.sh) | `PreInvocation` | Фиксирует метку времени старта генерации ответа агента. |
| [`scripts/hook-notify-stop.sh`](scripts/hook-notify-stop.sh) | `Stop` | Тактильная вибрация 32 мс (`termux-vibrate -d 32 -f`). При сессии $\ge 300$ с выводит `termux-toast` и системный Push с кнопкой возврата в Termux. |
| [`scripts/hook-biometric-gate.sh`](scripts/hook-biometric-gate.sh) | `PreToolUse` | Анализирует команды. При детекте `rm -rf`, `git push -f`, `git reset --hard`, `dd`, fork-бомб вызывает `termux-fingerprint` с заголовком `AI Agent: Biometric Confirmation`. |
| [`scripts/hook-daily-updater.py`](scripts/hook-daily-updater.py) | `PreInvocation` | Интервальный чекер 86400 с (24 ч). При наступлении срока инжектирует напоминание в `injectSteps` о запуске `lab-auto-updater`. |

---

## 🔒 Безопасность и конфиденциальность

* **Строго без персональных данных:** скрипты и конфигурации не содержат персональных токенов, логинов, паролей или жёстко привязанных путей файловой системы; все пути рассчитываются динамически через переменные окружения `$HOME` и `$PREFIX`.
* **Изолированный стейт:** временные метки хранятся в защищённом каталоге конфигурации пользователя `$HOME/.config/termux-agent-hooks/`.
* **Безотказность:** при любых сбоях API или отсутствии датчиков хуки завершаются корректно, не зависая и не ломая выполнение пользовательских задач.

---

## 📄 Лицензия

Распространяется под лицензией [MIT](LICENSE). Разработано для открытой экосистемы **[Enigman-Termux-lab](https://github.com/Enigman-Termux-lab)**.
