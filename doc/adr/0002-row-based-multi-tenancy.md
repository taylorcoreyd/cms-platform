# ADR-002: Row-Based Multi-Tenancy with Explicit Scoping

**Status:** Accepted  
**Date:** 2026-05-18

## Context
Need to serve multiple independent sites (tenants) from one codebase. v1 will be clone-and-use deployments where users deploy their own instance. Need simple setup without complex infrastructure.

## Decision
Use row-based multi-tenancy with explicit tenant scoping. All models have `tenant_id` column and belong to Tenant. Access patterns use explicit associations: `current_tenant.posts.find_by!(slug: ...)`. **No default_scope** - explicit scoping prevents magic and edge cases.

## Alternatives Considered
- **Apartment gem (database-based):** Better isolation but requires complex multi-database setup, not ideal for clone-and-use deployments
- **Apartment gem (schema-based):** Requires PostgreSQL, not compatible with MariaDB choice
- **acts_as_tenant gem:** Similar to row-based, but we want explicit control over scoping

## Consequences
- **Good:** Simple single-database setup for v1 clone-and-use deployments
- **Good:** Easy to understand and debug
- **Good:** Explicit scoping prevents issues with default_scope (admin screens, background jobs, associations, tests, console work)
- **Bad:** Need to remember to scope queries by tenant explicitly
- **Bad:** Cross-tenant queries require explicit `unscoped` or custom `for_tenant` scope
- **Note:** Can migrate to Apartment (schema-based) for v2 SaaS deployments if stronger isolation is needed
