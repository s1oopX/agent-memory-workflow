# Agent Memory Import Receipt

Version: `workflow-v3`

Return this receipt after importing the workflow.

```yaml
agent_name: <agent or tool name>
agent_version: <version if known>
imported_at_utc: <timestamp>
source_root: "{{AGENTS_ROOT}}"
workflow_version: "workflow-v3"
persistent_storage: <durable_memory|project_rules|manual_user_action_required|chat_local_only>
canonical_shared_source: "{{AGENTS_ROOT}}\machine"
durable_memory_record: <bootstrap_pointer_written|project_rule_pointer_written|not_written>
local_filesystem_access: <yes|no>
files_read:
  - AGENT_BOOTSTRAP.md
  - AGENT_MEMORY_IMPORT_PROMPT.md
  - machine\MACHINE_ENVIRONMENT_MEMORY.md
  - machine\AGENT_EXECUTION_PLAYBOOK.md
  - machine\AGENT_ENVIRONMENT_QUICK_REFERENCE.md
  - machine\HOME_DIRECTORY_MAP.md
  - machine\MAINTENANCE_POLICY.md
  - AGENT_PLATFORM_ADAPTERS.md
  - imports\IMPORT_REGISTRY.md
secrets_policy: no_secrets_stored
fresh_chat_test: <passed|needed|not_supported>
manual_user_action_required: <yes|no>
notes: <short notes or none>
```

If the agent can only remember the import inside the current chat, use
`chat_local_only`. If the user must paste or approve the memory in another
settings layer, use `manual_user_action_required`.

Use `durable_memory_record: not_written` unless a bootstrap pointer or equivalent
record was actually written to durable storage.
