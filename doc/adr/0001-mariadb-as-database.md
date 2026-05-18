# ADR-001: MariaDB as the Database

**Status:** Accepted  
**Date:** 2026-05-18

## Context
Need a relational database for a Rails CMS with multi-tenancy support. Developer has familiarity with MySQL from university and prefers beginner-friendly documentation for a learning project.

## Decision
Use MariaDB as the database for this project.

## Alternatives Considered
- **PostgreSQL:** Better multi-tenancy support via schemas, but official documentation is technical/reference-style and less beginner-friendly. Strong Rails ecosystem support.
- **SQLite:** Not suitable for production deployments.

## Consequences
- **Good:** Familiar to developer, beginner-friendly documentation
- **Good:** Works well with row-based multi-tenancy approach
- **Good:** MariaDB is a drop-in replacement for MySQL with additional features
- **Bad:** No native schema support (requires row-based tenancy instead)
- **Bad:** May need to migrate to PostgreSQL for future SaaS features (Catalogs, etc.)
- **Note:** Can migrate to PostgreSQL later if needed for v2 SaaS deployments
