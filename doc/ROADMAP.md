# CMS/Blogging Platform Project Plan
**Project:** Professional CMS for cdtaylor.photography & cdtaylor.dev  
**Date:** 2026-05-18  
**Status:** Draft  

---

## Project Overview

Build a multi-tenant CMS/blogging platform starting with two personal sites (cdtaylor.photography, cdtaylor.dev) with the vision to expand to other users. The platform prioritizes professional software engineering practices, clean architecture, and serves as a learning vehicle for system design.

### Core Goals
1. **Professional Quality**: Production-grade code, maintainable, scalable
2. **Learning Focus**: Architecture, design patterns, testing discipline
3. **Multi-tenant from Day 1**: Shared infrastructure serving multiple independent sites
4. **Editorial Excellence**: Strong authoring tools (critical for photography site with narrative focus)

---

## Technology Stack

| Layer | Technology | Rationale |
|-------|------------|-----------|
| Backend | **Ruby 3.4 + Rails 8.1** | Latest features, RJIT compiler, future-proof, maximum learning value |
| Frontend | **Hotwire (Turbo + Stimulus)** | Server-rendered HTML, minimal JS, progressive enhancement |
| Styling | **Tailwind CSS** | Utility-first, design consistency, rapid prototyping |
| Database | **MariaDB** | Beginner-friendly docs, familiar from university, row-based multi-tenancy (tenant_id) |
| Storage | **ActiveStorage (Local → Cloudflare R2/S3 later)** | Built-in Rails solution, service-agnostic abstraction, start local then migrate to cloud |
| Search | **MariaDB Full-Text** | Built-in, zero setup, upgrade to Meilisearch later if needed |
| Deployment | **Railway (Hobby plan)** | Fast deployment, excellent Rails support, free tier, MariaDB support |
| Testing | **RSpec + FactoryBot + Capybara** | Comprehensive test suite, BDD-style |
| Authentication | **Sorcery** | Modular, transparent, pick only needed features |
| Background Jobs | **ActiveJob :async adapter** | Built into Rails, zero setup, sufficient for initial needs |
| Rich Text | **Markdown** | Stored as text, portable, easy to version/render, with Markdown editor |

> **Version Note:** Using Ruby 3.4 + Rails 8.1 (released October 22, 2025). Expect excellent performance with Ruby 3.4's RJIT compiler and Rails 8.x improvements. Some gems may need version constraints - verify compatibility during setup.
>
> **Database Note:** Using MariaDB with row-based multi-tenancy (explicit tenant_id scoping through tenant associations). Simpler for v1 clone-and-use deployments. Can migrate to Apartment or Catalogs for v2 SaaS deployments.
>
> **Storage Note:** Start with local ActiveStorage for development sprint. ActiveStorage's service abstraction allows seamless migration to Cloudflare R2, S3, or any S3-compatible provider later with zero code changes - only configuration updates.

---

> **ADRs:** Architecture Decision Records are stored in `/doc/adr/` in the project directory. See: ADR-001 through ADR-005.

## Architecture Decisions

### 1. Multi-tenancy Strategy

**Approach: Row-based Multi-tenancy**
- Single MariaDB database per deployment
- All models have `tenant_id` column and belong to a Tenant
- Tenant-owned records are accessed through tenant associations, such as `current_tenant.posts`
- **Pattern**: explicit scoping in controllers/services; no tenant `default_scope`

**Rationale:**
- Perfect for v1 clone-and-use deployments (single database setup)
- Simpler than Apartment for individual deployments
- Easy to understand and maintain
- Can migrate to Apartment (database-based) or MariaDB Catalogs for v2 SaaS deployments

**Implementation:**

**1. Database Schema**
```ruby
# db/migrate/[timestamp]_create_tenants.rb
create_table :tenants do |t|
  t.string :name
  t.string :domain, index: { unique: true }  # cdtaylor.dev, cdtaylor.photography
  t.timestamps
end

# For each content model, add tenant_id with composite indexes
add_column :posts, :tenant_id, :bigint
add_index :posts, [:tenant_id, :slug], unique: true
add_index :posts, [:tenant_id, :status, :published_at]
```

**2. Current Tenant Resolution**
```ruby
# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :tenant
end

# app/controllers/concerns/set_tenant.rb
module SetTenant
  extend ActiveSupport::Concern
  
  included do
    before_action :set_tenant
  end
  
  def set_tenant
    domain = request.host

    Current.tenant = if Rails.env.development? && domain.in?(['localhost', '127.0.0.1'])
      Tenant.find_by!(domain: 'localhost')
    else
      Tenant.find_by!(domain: domain)
    end
  rescue ActiveRecord::RecordNotFound
    # Unknown hosts should fail closed. Seed a localhost tenant for development.
    raise ActionController::RoutingError, 'Not Found'
  end
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include SetTenant
end
```

**3. Tenantable Concern**
```ruby
# app/models/concerns/tenantable.rb
module Tenantable
  extend ActiveSupport::Concern
  
  included do
    belongs_to :tenant
    # NO default_scope - use explicit scoping instead
    
    # Helper scope for explicit tenant filtering
    scope :for_tenant, ->(tenant) { where(tenant: tenant) }
  end
end

# Usage pattern (explicit scoping everywhere):
# current_tenant.posts.find_by!(slug: params[:slug])
# current_tenant.pages.published
# current_tenant.media_items

# app/models/post.rb
class Post < ApplicationRecord
  include Tenantable
  
  validates :slug, uniqueness: { scope: :tenant_id }
end
```

**4. Cross-Tenant Security Tests (Critical!)**
```ruby
# spec/models/post_spec.rb
RSpec.describe Post do
  describe "tenant isolation" do
    let(:tenant1) { create(:tenant, domain: 'site1.test') }
    let(:tenant2) { create(:tenant, domain: 'site2.test') }
    let!(:post1) { create(:post, tenant: tenant1, slug: 'hello') }
    let!(:post2) { create(:post, tenant: tenant2, slug: 'hello') }
    
    it "prevents cross-tenant access through tenant associations" do
      expect(tenant1.posts.find_by(slug: 'hello')).to eq(post1)
      expect(tenant1.posts.find_by(slug: 'hello')).not_to eq(post2)
      expect(tenant2.posts.find_by(slug: 'hello')).to eq(post2)
    end

    it "isolates counts by tenant association" do
      expect(tenant1.posts.count).to eq(1)
      expect(tenant2.posts.count).to eq(1)
    end

    it "does not rely on global Post queries for isolation" do
      expect(Post.where(slug: 'hello').count).to eq(2)
    end
  end
end
```

### 2. Content Modeling

**Page Composition (Section-Based Editing):**
- Pages are composed of ordered Sections (building blocks)
- Four section types: Text (Markdown), Image (single + caption), Gallery (multiple images), Divider (visual separator)
- Enables structured page layouts without complex templates
- Model: `Page has_many :sections`, `Section` has `section_type` enum and polymorphic content

```
Content (polymorphic)
├── Post
│   ├── title
│   ├── slug
│   ├── body (Markdown)
│   ├── excerpt
│   ├── published_at
│   ├── featured_image (ActiveStorage)
│   ├── seo_title
│   ├── seo_description
│   └── status (draft/published/archived)
│
├── Page
│   ├── title
│   ├── slug
│   ├── body (Markdown)
│   ├── position
│   ├── parent (for hierarchy)
│   └── template (for custom layouts)
│
└── MediaItem
    ├── file (ActiveStorage)
    ├── alt_text
    ├── caption
    ├── credits
    └── focal_point (for cropping)

Taxonomies:
├── Category (hierarchical)
├── Tag
└── Series (for photography narratives)
```

### 3. Editorial Authoring Tools

**Key Requirements (especially for cdtaylor.photography):**
- Rich Markdown editor with image insertion/management
- Media library with grid/list views, bulk operations
- Content organization: collections, series, narratives
- Draft/preview workflow
- Scheduled publishing
- Content versioning/history

**Implementation:**
- **Markdown Editor**: Store Markdown in text columns and render server-side; choose a Markdown editor such as EasyMDE when the admin UI needs a richer editing experience
- **Media Picker**: Custom Stimulus controller with modal selection
- **Narrative Structure**: Series model with ordered Posts, custom styling per series

### 4. SEO System

```
SEO Features:
├── Automatic sitemap.xml generation
├── RSS/Atom feeds per site
├── Open Graph / Twitter Cards meta tags
├── Canonical URLs
├── Redirect management
├── Robots.txt per tenant
└── Schema.org structured data
```

**Implementation:**
- Gem: `sitemap_generator` for sitemaps
- Gem: `meta-tags` or custom helper for meta tags
- Custom controller concerns for SEO headers

### 5. Theming System

**Approach: View Component + Tailwind Based**
- Each tenant has a `theme` setting (e.g., `default`, `photography`, `dev`)
- Themes define:
  - Color schemes (Tailwind config overrides)
  - Typography
  - Layout templates
  - Custom CSS overrides
- Shared view components with theme-aware styling

**Implementation:**
```ruby
# app/models/tenant.rb
class Tenant < ApplicationRecord
  enum theme: { default: 'default', photography: 'photography', dev: 'dev' }
  has_one :theme_setting
end

# app/controllers/concerns/themeable.rb
module Themeable
  extend ActiveSupport::Concern
  
  included do
    before_action :set_theme
    helper_method :current_theme
  end
  
  def current_theme
    @current_theme ||= current_tenant.theme_setting || ThemeSetting.default
  end
end
```

---

## Project Structure

```
cms-platform/
├── app/
│   ├── controllers/
│   │   ├── admin/                    # Admin area
│   │   │   ├── application_controller.rb
│   │   │   ├── posts_controller.rb
│   │   │   ├── pages_controller.rb
│   │   │   ├── sections_controller.rb
│   │   │   ├── media_items_controller.rb
│   │   │   └── seo_controller.rb
│   │   ├── concerns/                 # Shared controller logic
│   │   │   ├── set_tenant.rb         # Resolves current tenant from host
│   │   │   ├── seoable.rb
│   │   │   └── themeable.rb
│   │   └── public/                   # Public-facing controllers
│   │       ├── pages_controller.rb
│   │       ├── posts_controller.rb
│   │       └── home_controller.rb
│   │
│   ├── models/
│   │   ├── concerns/                 # Model concerns
│   │   │   ├── tenantable.rb         # Row-based multi-tenancy
│   │   │   ├── content/              # Content-related
│   │   │   │   ├── publishable.rb
│   │   │   │   ├── sluggable.rb
│   │   │   │   └── seoable.rb
│   │   │   └── media/
│   │   │       └── attachable.rb
│   │   ├── current.rb               # Global tenant context
│   │   ├── tenant.rb
│   │   ├── user.rb
│   │   ├── post.rb
│   │   ├── page.rb
│   │   ├── section.rb
│   │   ├── media_item.rb
│   │   ├── category.rb
│   │   ├── tag.rb
│   │   ├── series.rb
│   │   └── theme_setting.rb
│   │
│   ├── views/
│   │   ├── admin/                    # Admin views
│   │   │   └── sections/             # Section partials by type
│   │   ├── public/                   # Public views
│   │   ├── components/               # ViewComponents
│   │   ├── layouts/                  # Layouts (per theme)
│   │   └── partials/
│   │
│   ├── helpers/
│   │   ├── seo_helper.rb
│   │   └── markdown_helper.rb
│   │
│   ├── jobs/                        # Background jobs
│   │   └── generate_sitemap_job.rb
│   │
│   └── mailers/
│
├── config/
│   ├── initializers/
│   │   ├── active_storage.rb
│   │   └── tailwind.rb
│   └── tailwind.config.js
│
├── db/
│   ├── migrate/
│   └── schema.rb
│
├── lib/
│   └── tasks/
│
├── spec/                           # RSpec tests
│   ├── models/
│   │   └── post_spec.rb          # Includes cross-tenant isolation tests
│   ├── controllers/
│   ├── features/
│   └── support/
│
├── public/
│   └── themes/                      # Theme assets
│
├── storage/                        # ActiveStorage (or symlink to cloud)
│
├── Dockerfile
├── docker-compose.yml
├── Gemfile
├── Gemfile.lock
├── .env.example
├── .gitignore
├── README.md
└── config.ru
```

---

## Implementation Phases

### Phase 0: MVP Vertical Slice
**Goal:** Publish real posts/pages for cdtaylor.dev and cdtaylor.photography from one Rails app.

**Core Principle:** Prove the architecture by publishing real content. Defer all speculative features.

| Task | Priority | Estimate | Dependencies |
|------|----------|----------|--------------|
| Initialize Rails 8.1 app with MariaDB | High | 1h | None |
| Configure Docker + docker-compose | High | 2h | Rails app |
| Create Tenant model and tenantable concern | High | 3h | Rails app |
| Create Current model and SetTenant concern | High | 2h | Tenant |
| Create User model with Sorcery authentication | High | 4h | Tenant |
| Write cross-tenant security tests | High | 2h | Tenant |
| Create Post model (title, slug, body, status, published_at) | High | 2h | Foundation |
| Create basic admin CRUD for Posts | High | 4h | Post model |
| Add Markdown rendering for Post body | Medium | 2h | Post model |
| Create public Post controller (index, show) | High | 2h | Post model |
| Add basic SEO fields (title, description) to Post | Medium | 1h | Post model |
| Set up ActiveStorage for Post images | Medium | 2h | Post model |
| Configure basic tenant-aware layout | Medium | 2h | Foundation |
| Deploy to Railway | High | 2h | Complete |
| Publish 5 real dev posts + 1 photography story | High | 4h | All above |

**Explicitly Deferred (do NOT build in Phase 0):**
- Section/page builder
- Full media library (start with simple image attachment on Post form)
- Series/narratives
- Scheduled publishing
- Content versioning
- Redirect manager
- Advanced SEO (sitemap, RSS, Open Graph)
- SaaS-grade tenant isolation
- Themes system (start with one clean shared theme)
- Categories/tags

**Success Criteria:**
- [ ] Can publish posts to both sites from one app
- [ ] Real content is live and accessible
- [ ] Architecture proves out (tenancy, auth, deployment)
- [ ] No speculative abstractions built

---

### Phase 1: Post-MVP Content Core (Week 1-2 after MVP)
**Goal:** Expand the proven MVP into a fuller CMS without rebuilding foundation work.

| Task | Priority | Estimate | Dependencies |
|------|----------|----------|--------------|
| Add Page model with hierarchy | High | 3h | MVP |
| Add MediaItem model with ActiveStorage metadata | High | 4h | MVP |
| Add Category model (hierarchical) | Medium | 3h | MVP |
| Add Tag model | Medium | 2h | MVP |
| Add Series model for photography narratives | Medium | 3h | MVP |
| Extract publishable concern from Post/Page behavior | Medium | 2h | Page model |
| Extract sluggable concern from Post/Page behavior | Medium | 2h | Page model |
| Build admin CRUD for Pages and supporting content types | High | 8h | Content models |
| Create public controllers for Pages and content archives | High | 4h | Content models |
| Expand SEO concern across Posts and Pages | Medium | 3h | Content models |

**Deliverables:**
- Page editing and public pages
- Expanded content organization
- Reusable content concerns based on proven MVP behavior
- Basic public-facing content archives

### Phase 2: Editorial Experience (Week 3-4 after MVP)
**Goal:** Improve authoring workflows once the core content model is proven.

| Task | Priority | Estimate | Dependencies |
|------|----------|----------|--------------|
| Add a Markdown editor to Post/Page forms | High | 4h | Phase 1 |
| Add draft preview for unpublished content | Medium | 4h | Phase 1 |
| Improve admin navigation and content filtering | Medium | 4h | Phase 1 |
| Add image insertion helpers for Markdown content | High | 4h | MediaItem model |
| Add basic content organization UI for tags/categories | Medium | 6h | Phase 1 |

**Deliverables:**
- Faster authoring interface
- Previewable drafts
- Basic image insertion workflow
- Usable content organization screens

### Phase 3: Media & Narrative Workflow (Week 5-6 after MVP)
**Goal:** Add the richer media and narrative tools needed for the photography site.

| Task | Priority | Estimate | Dependencies |
|------|----------|----------|--------------|
| Build media library UI | High | 8h | Content Core |
| Implement media picker for editor | High | 4h | Media library |
| Create content organization UI (collections/series) | Medium | 6h | Content Core |
| Add scheduled publishing | Medium | 3h | Content Core |
| Implement content versioning | Low | 4h | Content Core |
| Build WYSIWYG for narrative layouts | Medium | 6h | Editorial tools |

**Deliverables:**
- Professional authoring interface
- Seamless media integration
- Narrative content structuring (for photography site)

### Phase 4: SEO & Frontend Polish (Week 7-8 after MVP)
**Goal:** Add publishing metadata and polish public-facing interfaces after real content exists.

| Task | Priority | Estimate | Dependencies |
|------|----------|----------|--------------|
| Implement sitemap generation | High | 3h | Content Core |
| Create RSS/Atom feeds | High | 3h | Content Core |
| Build Open Graph / Twitter Cards | High | 3h | Content Core |
| Implement canonical URLs | Medium | 2h | Content Core |
| Create redirect management system | Medium | 4h | Content Core |
| Build robots.txt per tenant | Low | 2h | SEO |
| Add Schema.org structured data | Medium | 3h | Content Core |
| Design photography site theme | High | 8h | Foundation |
| Design dev site theme | High | 8h | Foundation |
| Implement theme switching system | High | 4h | Themes |

**Deliverables:**
- Complete SEO system
- Two distinct, polished site themes
- Professional public-facing interfaces

### Phase 5: Operations & SaaS Readiness (Later roadmap)
**Goal:** Harden the already-deployed app and prepare for future SaaS or higher-traffic use.

| Task | Priority | Estimate | Dependencies |
|------|----------|----------|--------------|
| Harden Railway deployment | High | 4h | Deployed MVP |
| Review MariaDB production configuration | High | 2h | Deployed MVP |
| Configure ActiveStorage with Cloudflare R2 | High | 3h | Deployed MVP |
| Set up CI/CD pipeline (GitHub Actions) | High | 3h | Deployed MVP |
| Review custom domain setup (cdtaylor.photography, cdtaylor.dev) | High | 2h | Deployed MVP |
| Set up SSL certificates | High | 1h | Domains |
| Implement backup strategy | Medium | 3h | Deployment |
| Performance optimization | Medium | 4h | Deployment |
| Security hardening | High | 4h | Deployment |
| Write comprehensive documentation | Medium | 4h | Complete |

**Deliverables:**
- Live production sites
- Automated deployment pipeline
- Backup and recovery procedures
- Project documentation

---

## Learning Opportunities

Each phase includes focused learning topics:

### Architecture & Design Patterns
- **Multi-tenancy patterns**: Schema vs row vs database isolation
- **DDD concepts**: Aggregates, repositories, domain services
- **Clean Architecture**: Separation of concerns, dependency rules
- **Service Objects**: Extracting business logic from models
- **Query Objects**: Encapsulating complex database queries
- **ViewComponent pattern**: Component-based view architecture

### Rails-Specific
- **ActiveRecord advanced**: Polymorphic associations, STI, concerns
- **ActionController concerns**: DRY controller logic
- **ActiveStorage**: File uploads, variants, direct uploads
- **Background jobs**: ActiveJob with Sidekiq/GoodJob
- **Caching**: Russian doll caching, cache digests
- **Internationalization**: Multi-language support (future)

### Frontend & UX
- **Hotwire**: Turbo Streams, Frames, Stimulus controllers
- **Tailwind CSS**: Utility-first styling, responsive design
- **Accessibility**: Semantic HTML, ARIA, keyboard navigation
- **Progressive enhancement**: Graceful degradation

### Testing
- **RSpec**: Model specs, controller specs, request specs
- **FactoryBot**: Test data generation
- **Capybara**: Feature tests with real browsers
- **TDD workflow**: Red-Green-Refactor discipline
- **Test coverage**: SimpleCov integration

### DevOps
- **Docker**: Containerization, multi-container apps
- **MariaDB**: Schema design, indexing, query optimization
- **CI/CD**: GitHub Actions workflows
- **Cloud deployment**: Railway, Cloudflare R2
- **Monitoring**: Logging, error tracking (Sentry)

---

## Coding Standards & Best Practices

### Ruby Style
- Follow **RuboCop** defaults (config included in project)
- Use **standard** gem for consistent formatting
- Prefer explicit over implicit
- Small, focused methods (max 10 lines)
- Descriptive method and variable names

### Rails Conventions
- RESTful routes and controller actions
- Skinny controllers, fat models (via concerns/services)
- Use service objects for complex business logic
- Query objects for complex database queries
- ViewComponents for reusable view fragments
- Partial templates for shared view logic

### Testing
- 100% coverage for critical paths (auth, payments if added)
- 80%+ overall test coverage
- Fast test suite (< 5 minutes for full suite)
- Specs for: models, controllers, features, jobs, mailers

### Git Workflow
- Feature branches: `feature/[description]`
- Bug fixes: `bugfix/[description]`
- Main branch protected, require PR reviews
- Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`
- Atomic commits with clear messages

### Documentation
- README with setup, deployment, architecture
- ADR (Architecture Decision Records) for major decisions
- Inline code comments for "why" not "what"
- CHANGELOG for notable changes

---

## Project Guidelines

### For Corey (The Developer)
1. **Write tests first**: Adopt TDD for new features
2. **Small commits**: Each commit should do one thing well
3. **Review your code**: Before committing, read it critically
4. **Ask for feedback**: Share PRs early for architectural review
5. **Document decisions**: Write ADRs for significant choices

### For Vibe (The Mentor)
1. **Focus on principles**: Explain the "why" behind suggestions
2. **Offer alternatives**: Present tradeoffs, not just one solution
3. **Code review discipline**: Point out anti-patterns and improvements
4. **Architecture guidance**: Help design scalable, maintainable systems
5. **Learning resources**: Suggest articles, books, talks for deeper understanding

---

## Next Immediate Steps

1. **Initialize the project**
   ```bash
   # Verify Ruby version
   ruby -v  # Should be 3.4.x
   
   # Create Rails 8.1 app
   rails new cms-platform --database=mysql --css=tailwind --js=importmap
   cd cms-platform
   
   # Add essential gems (check Rails 8.1 + MariaDB compatibility)
   bundle add sorcery
   bundle add mysql2
   bundle add rspec-rails
   bundle add factory_bot_rails
   bundle add faker
   bundle add rubocop
   bundle add standard
   
   # Set up database
   rails db:create
   ```
   > **Note:** With Rails 8.1, some gems may need specific versions. Check compatibility and use `--version` flag if needed (e.g., `bundle add sorcery --version '~> 0.17'`)

2. **Configure Docker**
   - Create Dockerfile for Rails app
   - Create docker-compose.yml with MariaDB service
   - Set up volume for ActiveStorage

3. **Set up multi-tenancy**
   - Create Tenant model and tenantable concern
   - Create Current model and SetTenant concern
   - Write cross-tenant security tests

4. **Create initial models**
   - User (with Sorcery)
   - Association between User and Tenant

---

## Resources & References

### Rails Multi-tenancy
- [Row-based multi-tenancy with Rails](https://medium.com/@bintudotai/building-a-multi-tenant-app-with-ruby-on-rails-3f5a0f0d8a8d)
- [Multi-tenancy with Rails (article)](https://medium.com/flatstack/multi-tenancy-in-rails-6-using-database-based-approach)
- [Schema-based vs Row-based Multi-tenancy](https://www.martinfowler.com/articles/patterns-of-distributed-systems/multi-tenant.html)

### Rails Best Practices
- [Rails Guides](https://guides.rubyonrails.org/)
- [The Rails Doctrine](https://rubyonrails.org/doctrine/)
- [Rails Style Guide](https://github.com/rubocop/ruby-style-guide)

### Testing
- [RSpec Rails](https://github.com/rspec/rspec-rails)
- [FactoryBot](https://github.com/thoughtbot/factory_bot_rails)
- [Capybara](https://github.com/teamcapybara/capybara)

### Frontend
- [Hotwire Documentation](https://hotwired.dev/)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [Stimulus Handbook](https://stimulus.hotwired.dev/handbook)

### Deployment
- [Railway Rails Deployment](https://docs.railway.app/guides/deploy-rails)
- [Docker for Rails](https://docs.docker.com/language/ruby/rails/)

---

## Open Questions

1. **Media Storage**: Cloudflare R2 vs AWS S3 vs DigitalOcean Spaces? (Decide later when moving from local storage)

## Resolved Decisions

- **Backend**: Ruby 3.4 + Rails 8.1
- **Database**: MariaDB (row-based multi-tenancy with tenant_id)
- **Authentication**: Sorcery
- **Storage**: ActiveStorage (Local → Cloud later)
- **Background Jobs**: ActiveJob :async adapter
- **Search**: MariaDB Full-Text
- **Rich Text**: Markdown stored in text columns
- **Deployment**: Railway (Hobby plan)
- **Testing**: RSpec + FactoryBot + Capybara
- **Caching**: Russian doll caching

---

## Success Criteria

### MVP (Minimum Viable Product)
- [ ] Two live sites: cdtaylor.photography and cdtaylor.dev
- [ ] Multi-tenant architecture in place
- [ ] Content creation and management working
- [ ] Basic post image attachment works
- [ ] Basic SEO in place
- [ ] Clean shared theme with tenant-specific branding

### Professional Grade
- [ ] Comprehensive test suite (>80% coverage)
- [ ] Clean, maintainable codebase
- [ ] Documentation complete
- [ ] Deployment automated
- [ ] Backups configured
- [ ] Monitoring in place

### Learning Achieved
- [ ] Solid understanding of multi-tenant architecture
- [ ] Professional Rails development practices
- [ ] Full-stack testing discipline
- [ ] Deployment and DevOps fundamentals
- [ ] System design principles

---

*Last updated: 2026-05-18*  
*Plan owner: Corey Taylor*  
*Mentor: Vibe*
