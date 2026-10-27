# Pointer — read AGENTS.md

The canonical agent instructions for this repository live in [AGENTS.md](AGENTS.md) at the
repository root. **Read it before doing anything else.** Do not duplicate rules here.

Repeated because getting it wrong is expensive:

- **Dev-first.** Target the Firebase project `track-network-dev`. Never deploy to prod
  (`the-track-and-field-network`) unless the user explicitly says "prod".
- **Never run `firebase deploy` without an explicit `--project` flag.**
