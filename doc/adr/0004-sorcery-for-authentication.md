# ADR-004: Sorcery for Authentication

**Status:** Accepted  
**Date:** 2026-05-18

## Context
Need user authentication for the CMS admin interface. Want a modular, transparent solution that doesn't hide complexity. Previous experience with monolithic authentication solutions (like Devise) was painful to customize.

## Decision
Use Sorcery gem for authentication.

## Alternatives Considered
- **Devise:** Full-featured, battle-tested, but monolithic and opinionated. Hard to customize without fighting the framework.
- **Authlogic:** Lightweight, well-tested, but older with less active development and smaller community.
- **Custom:** Full control, but time-consuming to build and maintain. High risk of security vulnerabilities if not done carefully.

## Consequences
- **Good:** Modular - pick only the features you need (base authentication, remember_me, reset_password, etc.)
- **Good:** Transparent - can see exactly what's happening, no magic
- **Good:** Works well with multi-tenancy patterns
- **Good:** Easy to customize and extend
- **Bad:** More manual setup than Devise (need to wire up features yourself)
- **Bad:** Less "batteries included" than Devise
- **Note:** Will start with `:base`, `:remember_me`, and `:reset_password` modules
