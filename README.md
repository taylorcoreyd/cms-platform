# CMS-Platform

CMS-Platform is just a working name.

The intended installation:
1. Clone repo
2. Link repo to a railway deployment, push to server, etc.
3. Get your Rails secret key, `bin/rails secret`
4. Set environment variables:
- DOMAINS="example1.com, example2.com"
- DATABASE_URL=<database url>
- RAILS_ENV="production"
- SECRET_KEY_BASE=<rails secret key>
- RAILS_SERVE_STATIC_FILES="true"
5. Deploy!