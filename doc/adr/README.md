# Architecture Decision Records (ADRs)

This directory contains Architecture Decision Records (ADRs) for the CMS/Blogging Platform project.

## What is an ADR?

An ADR is a short document that captures an important architectural decision made along with its context and consequences.

## Active ADRs

| Number | Title | Status | Date |
|--------|-------|--------|------|
| [ADR-001](./0001-mariadb-as-database.md) | MariaDB as the Database | Accepted | 2026-05-18 |
| [ADR-002](./0002-row-based-multi-tenancy.md) | Row-Based Multi-Tenancy with Explicit Scoping | Accepted | 2026-05-18 |
| [ADR-003](./0003-markdown-stored-in-text-columns.md) | Markdown Stored in Text Columns | Accepted | 2026-05-18 |
| [ADR-004](./0004-sorcery-for-authentication.md) | Sorcery for Authentication | Accepted | 2026-05-18 |
| [ADR-005](./0005-railway-for-deployment.md) | Railway for Deployment | Accepted | 2026-05-18 |

## Template

```markdown
# ADR-XXX: Title

**Status:** Proposed/Accepted/Deprecated  
**Date:** YYYY-MM-DD

## Context
[What problem are we solving?]

## Decision
[What did we decide?]

## Alternatives Considered
- [Option 1]: [Pros/Cons]
- [Option 2]: [Pros/Cons]

## Consequences
- Good: [benefits]
- Bad: [drawbacks]
- Note: [additional context]
```

## More Info

- [ADR GitHub Template](https://github.com/joelcostigliola/asm-adr)
- [ADR Original](https://adr.github.io/)
