---
name: notify
description: Send notifications to desktop or phone. Use for desktop when user says "notify me", "alert me", "let me know when". Use for phone/Pushover when user says "notify me on my phone", "message me on my phone", "send to my phone", or similar phrases specifying mobile/phone delivery. Examples: "notify me when tests finish" (desktop), "message me on my phone when the deploy is done" (phone).
---

# Notifications

## Desktop (notify-send)

```bash
notify-send -i ~/.claude/skills/notify/assets/claude-icon.png "Title" "Message"
```

## Phone (Pushover)

Requires credentials in `~/.claude/skills/notify/config`. See `config.example` for format.

```bash
source ~/.claude/skills/notify/config && curl -s -X POST https://api.pushover.net/1/messages.json \
  -d "token=$PUSHOVER_TOKEN" \
  -d "user=$PUSHOVER_USER" \
  -d "title=Title" \
  -d "message=Message"
```

If config is empty, prompt user to fill in credentials from https://pushover.net.
