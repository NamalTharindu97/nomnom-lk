# CI/CD Enhancement Plan

## Goal
Enhance the CI/CD pipeline for automated deployments to Render, with phase-by-phase rollouts and proper testing gates.

---

## Current State

### Existing Pipeline (`test.yml`)

```
Push to master/phase/**
    ↓
┌─────────────────────────────────────┐
│ Backend Job                          │
│ - Secret scan (gitleaks)            │
│ - Go lint (golangci-lint)           │
│ - Go vulnerabilities (govulncheck)  │
│ - Unit tests + coverage             │
│ - Integration tests                 │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ Admin Job                            │
│ - Secret scan                       │
│ - npm audit                         │
│ - TypeScript check                  │
│ - Unit tests + coverage             │
│ - Playwright E2E tests              │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ Flutter Job                          │
│ - Flutter analyze                   │
│ - Unit + widget tests               │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ Docker Job (master only)            │
│ - Build backend image               │
│ - Scan with Trivy                   │
│ - Build admin image                 │
│ - Scan with Trivy                   │
│ - Push to Docker Hub                │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ SonarCloud Job (master only)        │
│ - Code quality analysis             │
└─────────────────────────────────────┘
```

### Issues with Current Pipeline

1. **No deploy step** — Docker images pushed but not deployed
2. **No deployment verification** — No health check after deploy
3. **No rollback mechanism** — Manual intervention needed
4. **No environment separation** — Same pipeline for all branches
5. **No deploy gating** — Docker job runs even if tests fail (but `needs:` ensures tests pass)

---

## Enhancement Plan

### Phase 1: Add Deploy Workflow (Tomorrow)

**Goal:** Auto-deploy to Render when tests pass on master.

#### 1.1 Create `.github/workflows/deploy.yml`

```yaml
name: Deploy to Render

on:
  workflow_run:
    workflows: ["Test"]
    types: [completed]
    branches: [master]

jobs:
  deploy:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Trigger Render deploy
        run: |
          echo "Triggering Render deployment..."
          curl -X POST "${{ secrets.RENDER_DEPLOY_HOOK }}" \
            -H "Content-Type: application/json"
      
      - name: Wait for deploy
        run: |
          echo "Waiting for Render to deploy..."
          sleep 120  # Render cold start
      
      - name: Health check
        run: |
          echo "Checking backend health..."
          for i in {1..5}; do
            if curl -sf https://nomnom-backend.onrender.com/health; then
              echo "✅ Backend is healthy"
              exit 0
            fi
            echo "Attempt $i failed, retrying in 30s..."
            sleep 30
          done
          echo "❌ Backend health check failed"
          exit 1
      
      - name: Notify on failure
        if: failure()
        run: |
          echo "::error::Deployment failed health check"
          # Add Slack/Discord notification here if needed
```

#### 1.2 Setup Render Deploy Hook

1. Go to Render Dashboard → Backend service → Settings
2. Scroll to "Deploy Hook"
3. Copy the URL (format: `https://api.render.com/hooks/deploy/hook-xxxxx`)
4. Add to GitHub repo secrets:
   - Name: `RENDER_DEPLOY_HOOK`
   - Value: `https://api.render.com/hooks/deploy/hook-xxxxx`

#### 1.3 Add Deploy Status Badge

Add to `README.md`:

```markdown
[![Deploy Status](https://api.render.com/badge?service=nomnom-backend)](https://dashboard.render.com/service/srv-xxxxx)
```

---

### Phase 2: Environment Separation (Week 2)

**Goal:** Separate staging and production environments.

#### 2.1 Create Staging Environment

Add to `render.yaml`:

```yaml
services:
  # Staging (for PR previews)
  - type: web
    name: nomnom-backend-staging
    runtime: image
    plan: free
    region: oregon
    image:
      url: docker.io/namal97/nomnom-backend:latest
    envVars:
      - key: ENVIRONMENT
        value: staging
      # ... same as production
```

#### 2.2 Branch-Based Deployments

Create `.github/workflows/deploy-staging.yml`:

```yaml
name: Deploy Staging

on:
  push:
    branches: ["phase/**"]

jobs:
  deploy-staging:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Render deploy (staging)
        run: |
          curl -X POST "${{ secrets.RENDER_DEPLOY_HOOK_STAGING }}"
```

---

### Phase 3: Deployment Verification (Week 3)

**Goal:** Comprehensive testing after deployment.

#### 3.1 Smoke Tests

Create `.github/workflows/smoke-test.yml`:

```yaml
name: Smoke Tests

on:
  workflow_run:
    workflows: ["Deploy to Render"]
    types: [completed]

jobs:
  smoke-test:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Run smoke tests
        run: |
          BASE_URL="https://nomnom-backend.onrender.com"
          
          # Test 1: Health check
          curl -sf "$BASE_URL/health" || exit 1
          
          # Test 2: Login
          TOKEN=$(curl -sf -X POST "$BASE_URL/api/v1/auth/login" \
            -H "Content-Type: application/json" \
            -d '{"email":"admin@nomnom.lk","password":"Admin@123"}' \
            | jq -r '.access_token')
          
          # Test 3: Get offers
          curl -sf "$BASE_URL/api/v1/offers" \
            -H "Authorization: Bearer $TOKEN" || exit 1
          
          # Test 4: Get restaurants
          curl -sf "$BASE_URL/api/v1/restaurants" \
            -H "Authorization: Bearer $TOKEN" || exit 1
          
          echo "✅ All smoke tests passed"
```

#### 3.2 Rollback Mechanism

Add to `.github/workflows/deploy.yml`:

```yaml
      - name: Rollback on failure
        if: failure()
        run: |
          echo "Rolling back to previous version..."
          # Trigger redeploy of previous Docker image
          curl -X POST "${{ secrets.RENDER_DEPLOY_HOOK }}" \
            -H "Content-Type: application/json" \
            -d '{"clear_cache": false}'
```

---

### Phase 4: Advanced Features (Month 2)

#### 4.1 Canary Deployments

Deploy to 10% of traffic first, then full rollout:

```yaml
      - name: Canary deploy
        run: |
          # Deploy canary version
          curl -X POST "${{ secrets.RENDER_DEPLOY_HOOK }}" \
            -d '{"image_tag": "${{ github.sha }}"}'
          
          # Wait 5 minutes
          sleep 300
          
          # Check error rate
          ERROR_RATE=$(curl -sf "https://nomnom-backend.onrender.com/health" \
            | jq -r '.error_rate')
          
          if (( $(echo "$ERROR_RATE > 0.01" | bc -l) )); then
            echo "❌ Error rate too high, rolling back"
            exit 1
          fi
          
          echo "✅ Canary looks good, promoting to full"
```

#### 4.2 Deployment Notifications

Add Slack/Discord notifications:

```yaml
      - name: Notify Slack
        if: always()
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          fields: repo,message,commit,author
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

#### 4.3 Performance Monitoring

Add Lighthouse CI:

```yaml
      - name: Lighthouse audit
        uses: treosh/lighthouse-ci-action@v10
        with:
          urls: |
            https://nomnom-admin.onrender.com
          budgetPath: ./lighthouse-budget.json
```

---

## Implementation Timeline

| Phase | When | Effort | Impact |
|-------|------|--------|--------|
| Phase 1: Deploy workflow | Tomorrow | 30 min | Auto-deploy on master push |
| Phase 2: Environment separation | Week 2 | 2 hrs | Staging for testing |
| Phase 3: Deployment verification | Week 3 | 1 hr | Automated smoke tests |
| Phase 4: Advanced features | Month 2 | 4 hrs | Canary, notifications, monitoring |

---

## Required Secrets

| Secret | Where to Get | Used For |
|--------|--------------|----------|
| `RENDER_DEPLOY_HOOK` | Render Dashboard → Backend → Settings | Trigger deploy |
| `RENDER_DEPLOY_HOOK_STAGING` | Render Dashboard → Staging → Settings | Trigger staging deploy |
| `SLACK_WEBHOOK` | Slack → Apps → Incoming Webhooks | Notifications |
| `DOCKER_USERNAME` | Docker Hub | Already configured |
| `DOCKER_PASSWORD` | Docker Hub | Already configured |

---

## Success Criteria

### Phase 1
- [ ] `deploy.yml` triggers on master push
- [ ] Render deploys automatically
- [ ] Health check passes after deploy
- [ ] Deploy badge shows in README

### Phase 2
- [ ] Staging environment exists
- [ ] `phase/*` branches deploy to staging
- [ ] Staging URL works

### Phase 3
- [ ] Smoke tests run after deploy
- [ ] Rollback works on failure
- [ ] Deployment status visible in GitHub

### Phase 4
- [ ] Canary deployments work
- [ ] Slack notifications on deploy
- [ ] Lighthouse audits pass

---

## Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `.github/workflows/deploy.yml` | Create | Auto-deploy on master |
| `.github/workflows/deploy-staging.yml` | Create | Staging deployments |
| `.github/workflows/smoke-test.yml` | Create | Post-deploy verification |
| `render.yaml` | Modify | Add staging service |
| `README.md` | Modify | Add deploy badge |

**Total: 4 new files, 2 modified files**
