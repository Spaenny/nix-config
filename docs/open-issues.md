# Open issues

These points were noticed while writing the documentation on 2026-11-06 and fixed on 2026-11-11, except for what is listed below.

## Unused parts

| What | Status |
| --- | --- |
| module `apps.kitty` | not active on any host, temporarily replaced by `apps.kwi` |

## Settled on purpose

These were reviewed and are kept as they are:

- **Zed agent without confirmation:** `apps.zed-editor` sets `always_allow_tool_actions` and `allow_unsandboxed`, see the [module reference](modules.md#home-manager-applications-apps).
- **No backups for `dns` and `aquarius`:** the Technitium zones are easy to recreate, see [Services on blarm](services.md#backups).
