---
applyTo: "**"
---

# Pointer — read AGENTS.md

The canonical agent instructions for this repository live in
[AGENTS.md](../AGENTS.md) at the repository root. **Read it before doing anything else.**

This file exists only so tools that look for `.github/copilot-instructions.md` are routed
to the same single source of truth. Do not duplicate rules here.

Two rules are repeated because getting them wrong is expensive:

- **Dev-first.** Target the Firebase project `track-network-dev`. Never deploy to prod
  (`the-track-and-field-network`) unless the user explicitly says "prod".
- **Never run `firebase deploy` without an explicit `--project` flag.**
