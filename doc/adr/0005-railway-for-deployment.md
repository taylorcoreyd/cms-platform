# ADR-005: Railway for Deployment

**Status:** Accepted  
**Date:** 2026-05-18

## Context
Need simple, fast deployment for v1. Already successfully using Railway Hobby plan for other projects. Need to deploy a Rails + MariaDB application with minimal friction.

## Decision
Use Railway for deployment.

## Alternatives Considered
- **Fly.io:** Excellent Rails support, Docker-based, but slightly more setup complexity
- **DigitalOcean:** App Platform or Droplets, but less Rails-optimized than Railway
- **Render:** Similar to Railway with good Rails support, but developer prefers Railway
- **Heroku:** Classic PaaS, but has limitations, slower deploys, and less modern tooling

## Consequences
- **Good:** Fast deployment - Git push to deploy
- **Good:** Excellent Rails support and documentation
- **Good:** Free tier sufficient for 2 low-traffic personal sites
- **Good:** Already familiar with Railway workflow
- **Good:** Easy to connect MariaDB add-on
- **Bad:** Vendor lock-in (though data is exportable)
- **Bad:** Need to be aware of Railway-specific configurations
- **Note:** Railway provides managed MariaDB, automatic HTTPS, and easy scaling
