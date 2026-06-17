# Home Directory Map

Map stable directories here so local agents do not have to rediscover them.

```text
home: {{HOME_DIR}}
agents_root: {{AGENTS_ROOT}}
```

## Suggested Sections

```text
code:
  - pending
documents:
  - pending
downloads:
  - pending
temporary_work:
  - pending
agent_config:
  - {{AGENTS_ROOT}}
```

## Policy

- Mark temporary directories clearly.
- Do not assume temporary directories are safe to keep.
- Do not move or delete application state directories without explicit user
  approval.
