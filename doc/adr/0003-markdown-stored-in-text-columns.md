# ADR-003: Markdown Stored in Text Columns

**Status:** Accepted  
**Date:** 2026-05-18

## Context
Need rich text authoring for blog posts and pages. Want portable, versionable content that's easy to work with as plain text. The photography site has narrative-heavy content where Markdown's simplicity is a feature, not a limitation.

## Decision
Store Markdown as plain text in database columns. Render with a Markdown library (e.g., Redcarpet or CommonMarker). Use a Markdown editor in the admin interface.

## Alternatives Considered
- **ActionText:** Built into Rails, uses Trix editor, but stores HTML-ish content which is less portable and harder to version control
- **Trix:** Rich text editor from Basecamp, but stores HTML content
- **EasyMDE:** Markdown editor, but requires JavaScript integration and is a separate dependency

## Consequences
- **Good:** Content is plain text - portable across systems
- **Good:** Easy to version control and review changes
- **Good:** Human-readable in raw form
- **Good:** Can use any Markdown editor or library
- **Good:** Easy to migrate or transform later
- **Bad:** Need to choose and configure a Markdown rendering library
- **Bad:** No built-in image embedding (but ActiveStorage can handle attachments separately)
- **Note:** For image embedding, we'll use ActiveStorage attachments with Markdown reference syntax: `![alt](attachment:filename.jpg)`
