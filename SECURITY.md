# Security Policy

## Scope

Agent Memory Workflow is a local-first file protocol. The main security concern
is preventing credentials, private machine facts, and private session data from
being written into shared memory files or public templates.

## Supported Versions

Security reports are accepted for the latest released version and the `main`
branch.

## Reporting a Vulnerability

Do not open a public issue for security-sensitive reports.

Use GitHub's private vulnerability reporting if available on the repository. If
that option is unavailable, open a minimal public issue asking for a private
contact path without including sensitive details.

Do not include:

- credentials
- API tokens
- private keys
- cookies
- database passwords
- private machine paths that identify a real user or organization
- private session logs

## Expected Handling

Valid reports should receive an initial response as soon as practical. Fixes
will prioritize avoiding secret persistence, unsafe overwrite behavior, path
handling defects, and release/package integrity problems.
