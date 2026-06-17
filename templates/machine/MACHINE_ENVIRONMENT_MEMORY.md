# Machine Environment Memory

This file stores stable, non-secret facts about the local machine.

Generated for:

```text
user: {{USER_ID}}
home: {{HOME_DIR}}
agents_root: {{AGENTS_ROOT}}
os: {{OS_NAME}}
generated_at_utc: {{GENERATED_UTC}}
```

## Fill In After Setup

Record durable facts such as:

- preferred shell and terminal behavior
- available language runtimes
- package managers
- compiler toolchains
- database clients and local service preferences
- browser automation availability
- paths that local agents should treat as permanent

Do not record credentials, tokens, private keys, or one-time session details.

## Known Local Policies

- Treat `{{AGENTS_ROOT}}` as the canonical shared memory source.
- Run the verifier after editing workflow files.
- Keep machine facts factual and current; remove stale entries instead of
  preserving history in this file.
