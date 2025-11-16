
# Cross-platform index (agent-optimized)

This file is an index. Read the small atomic files in `.claude/` before implementing.

Files (atomic):
- `parity.md` — platform mappings, parity rules, default constraints
- `implementation.md` — reuse decision tree and placement rules (View/ViewModel/Service/Model)
- `testing.md` — mock patterns, required tests, CI commands
- `localization.md` — localization keys, format rules, RTL handling
- `quick_rules.md` — grep + build + test quick commands

Rules summary:
- Default: implement changes on BOTH platforms unless task notes otherwise.
- Always search for existing code; prefer extending over creating new files.
- Keep MVVM separation and no network in UI.
- Mock all network calls in unit tests; no live network in CI tests.

Use the atomic files to get full details. Do not rely on this index alone.
