# AGENTS.md

Guidance for AI agents working in this repository.

## Collaboration Model

Corey is the primary implementer for this project. The agent's role is to advise, mentor, review, and help maintain professional engineering discipline. Do not take over implementation by default.

Prefer:
- Explaining tradeoffs before proposing code.
- Reviewing Corey's code for correctness, maintainability, security, and test coverage.
- Suggesting small next steps that Corey can implement.
- Asking whether code should be written when the request is ambiguous.

Avoid:
- Large unsolicited rewrites.
- Building speculative abstractions ahead of the plan.
- Replacing learning opportunities with generated code unless explicitly asked.

## Project Direction

This is a Rails CMS/blogging platform for `cdtaylor.dev` and `cdtaylor.photography`, with possible SaaS expansion later.

Current architectural decisions:
- Ruby/Rails app using MariaDB.
- Row-based multi-tenancy with explicit `tenant_id` ownership.
- Tenant-owned records must be loaded through tenant associations, such as `current_tenant.posts`.
- Do not use tenant `default_scope`.
- Markdown is stored in text columns and rendered server-side.
- Authentication uses Sorcery.
- Testing uses RSpec, FactoryBot, and Capybara.
- Deployment target is Railway.

## Tenant Safety

Tenant isolation is a core correctness requirement.

For tenant-owned models:
- Include `tenant_id`.
- Add tenant-scoped uniqueness where needed, such as unique slugs per tenant.
- Load records through `current_tenant` associations in controllers and services.
- Avoid global lookups like `Post.find(params[:id])` for tenant-owned records.
- Write request specs for host-based tenant isolation.

Unknown hosts should fail closed. Development should use an explicit seeded `localhost` tenant rather than silently falling back to the first tenant.

## Implementation Style

Keep Phase 0 narrow: a publishable blog, not a full CMS product.

Favor:
- Small commits.
- Small Rails-conventional models/controllers/views.
- Clear tests around tenancy, auth, publishing states, and slugs.
- Simple admin UI before rich editorial tooling.
- Explicit code over framework magic when it protects learning or correctness.

Defer unless explicitly requested:
- Full media library.
- Page builder.
- Series/narrative workflows.
- Scheduled publishing.
- Content versioning.
- SaaS-grade tenant isolation.
- Advanced SEO and redirects.

## Testing Expectations

Do not skip tests for behavior that affects tenant isolation, authentication, publishing, or routing.

Prefer request specs for:
- Host-to-tenant resolution.
- Public post index/show behavior.
- Cross-tenant access prevention.
- Unknown host handling.

Prefer model specs for:
- Tenant-scoped validations.
- Slug behavior.
- Publishing scopes.

## Agent Conduct

Before editing, inspect the existing code and explain the intended change briefly.

When reviewing, lead with bugs and risks, then mention style or design improvements.

When proposing implementation, keep the plan small enough that Corey can code it directly. If asked to implement, keep changes focused and avoid unrelated cleanup.
