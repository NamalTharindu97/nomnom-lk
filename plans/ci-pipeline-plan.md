# CI Pipeline Enhancement Plan — NomNom LK

## Current State
4 CI jobs: Backend (Go tests), Admin (build + Playwright E2E), Flutter (analyze + tests), Docker (build & push on master). No linting, no security scanning, no coverage, no auto-deploy.

## Phase 1 — Linting & Code Quality (2-3 hours)

### Goals
- Catch bugs early with static analysis
- Enforce consistent code style
- Block PRs with code quality issues

### Files to Create
```
.golangci.yml                        # Go linter config
```

### Files to Modify
- `backend/Makefile` — add `lint` target
- `.github/workflows/test.yml` — add lint steps

### Files to Create Details

**`.golangci.yml`** (at repo root):
```yaml
version: "2"
run:
  timeout: 5m
  modules-download-mode: readonly
linters:
  default: standard
  enable:
    - errcheck
    - gosimple
    - govet
    - ineffassign
    - staticcheck
    - unused
    - misspell
    - revive
issues:
  exclude-rules:
    - path: _test\.go
      linters:
        - errcheck
```

**`backend/Makefile`** — add:
```makefile
lint:
	golangci-lint run ./...
lint-ci:
	golangci-lint run ./... --out-format=github-actions
```

### CI Workflow Changes

Add step to **backend job** (before tests):
```yaml
- name: Lint
  uses: golangci/golangci-lint-action@v6
  with:
    version: latest
    working-directory: backend
```

Add step to **admin job** (before build):
```yaml
- name: Lint
  run: npm run lint
  working-directory: admin
```

Add step to **admin job** (after lint):
```yaml
- name: TypeScript type check
  run: npx tsc --noEmit
  working-directory: admin
```

## Phase 2 — Security Scanning (2-3 hours)

### Goals
- Catch dependency vulnerabilities
- Detect leaked secrets before commit
- Scan Docker images for vulnerable packages

### Files to Create
```
.github/dependabot.yml               # Auto-PRs for dependency updates
```

### Files to Modify
- `.github/workflows/test.yml` — add security steps

### Dependabot Config

**`.github/dependabot.yml`**:
```yaml
version: 2
updates:
  - package-ecosystem: "gomod"
    directory: "/backend"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
  - package-ecosystem: "npm"
    directory: "/admin"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

### CI Steps to Add

**1. Gitleaks (secret scanning)** — early in both backend and admin jobs:
```yaml
- name: Secret scan
  uses: gitleaks/gitleaks-action@v2
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**2. npm audit** — admin job, after install:
```yaml
- name: Audit dependencies
  run: npm audit --audit-level=high
  working-directory: admin
```

**3. govulncheck** — backend job, after install:
```yaml
- name: Check Go vulnerabilities
  run: |
    go install golang.org/x/vuln/cmd/govulncheck@latest
    govulncheck ./...
  working-directory: backend
```

**4. Trivy (Docker scan)** — docker job, after build:
```yaml
- name: Scan backend image
  uses: aquasecurity/trivy-action@v0.29
  with:
    image-ref: ${{ secrets.DOCKER_USERNAME }}/nomnom-backend:latest
    format: table
    exit-code: 1
    severity: HIGH,CRITICAL

- name: Scan admin image
  uses: aquasecurity/trivy-action@v0.29
  with:
    image-ref: ${{ secrets.DOCKER_USERNAME }}/nomnom-admin:latest
    format: table
    exit-code: 1
    severity: HIGH,CRITICAL
```

## Phase 3 — Coverage & Quality Gates (2-3 hours)

### Goals
- Track test coverage over time
- Block PRs that reduce coverage below threshold
- Centralized quality reporting

### Files to Create
```
sonar-project.properties             # SonarQube Cloud config
codecov.yml                          # Codecov config
```

### Files to Modify
- `.github/workflows/test.yml` — add coverage + SonarQube steps

### SonarQube Cloud Setup

**`sonar-project.properties`**:
```properties
sonar.projectKey=NamalTharindu97_nomnom-lk
sonar.organization=namaltharindu97
sonar.host.url=https://sonarcloud.io

# Go
sonar.go.coverage.reportPaths=backend/coverage.out
sonar.go.tests.reportPaths=backend/report.xml

# Admin (JS/TS)
sonar.javascript.lcov.reportPaths=admin/coverage/lcov.info
sonar.sources=admin/src
sonar.tests=admin/tests

# Flutter (Dart)
sonar.dart.coverage.reportPaths=flutter/coverage/lcov.info
```

**`codecov.yml`**:
```yaml
coverage:
  status:
    project:
      default:
        target: 70%
        threshold: 2%
    patch:
      default:
        target: 80%
```

### CI Steps to Add

**Backend job — add coverage**:
```yaml
- name: Run unit tests with coverage
  run: go test ./internal/... -v -count=1 -race -coverprofile=coverage.out -covermode=atomic
  working-directory: backend

- name: Upload Go coverage
  uses: codecov/codecov-action@v5
  with:
    directory: backend
    files: coverage.out
    flags: backend
```

**Admin job — add coverage (Vitest output)**:
```yaml
- name: Run unit tests with coverage
  run: npx vitest run --coverage
  working-directory: admin

- name: Upload admin coverage
  uses: codecov/codecov-action@v5
  with:
    directory: admin
    files: coverage/lcov.info
    flags: admin
```

**New sonar job**:
```yaml
sonar:
  name: SonarQube Quality Gate
  needs: [backend, admin, flutter]
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0
    - name: Download coverage artifacts
      uses: actions/download-artifact@v4
      with:
        path: coverage-artifacts
    - name: SonarQube Scan
      uses: SonarSource/sonarcloud-github-action@v2
      env:
        SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

## Phase 4 — Auto-Deploy & Pipeline Polish (2-3 hours)

### Goals
- Automatic Render deployment after Docker push
- Build caching for faster CI
- Better failure diagnostics

### Files to Modify
- `.github/workflows/test.yml` — caching + deploy hook
- `admin/vitest.config.ts` — coverage config

### CI Changes

**npm caching** — admin job:
```yaml
- name: Cache npm
  uses: actions/cache@v4
  with:
    path: |
      ~/.npm
      admin/node_modules
    key: npm-${{ hashFiles('admin/package-lock.json') }}
    restore-keys: npm-
```

**Render deploy hook** — docker job, after push:
```yaml
- name: Deploy backend to Render
  run: |
    curl -X POST "${{ secrets.RENDER_BACKEND_DEPLOY_HOOK }}"

- name: Deploy admin to Render
  run: |
    curl -X POST "${{ secrets.RENDER_ADMIN_DEPLOY_HOOK }}"
```

**Admin Vitest coverage config** — `admin/vitest.config.ts`:
```ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['lcov', 'text-summary'],
      reportsDirectory: './coverage',
    },
  },
});
```

## Implementation Order

| Phase | What | Depends On | Est. Time |
|-------|------|-----------|-----------|
| **P1** | Linting | Nothing | 2-3h |
| **P2** | Security | P1 (can parallelize) | 2-3h |
| **P3** | Coverage + SonarQube | P1 | 2-3h |
| **P4** | Deploy hook + caching | P1 | 1-2h |

Each phase can be a separate PR/branch. Phases 1 and 2 can be developed in parallel.

## Expected Final CI Pipeline Flow

```
PR push
  ├── Gitleaks (secret scan)         ← Phase 2
  ├── golangci-lint                  ← Phase 1
  ├── npm run lint + tsc --noEmit    ← Phase 1
  ├── flutter analyze                ← Already exists
  │
  ├── Backend tests                  ← Already exists
  │   ├── govulncheck                ← Phase 2
  │   └── coverage.out → Codecov     ← Phase 3
  │
  ├── Admin build + E2E              ← Already exists
  │   ├── npm audit                  ← Phase 2
  │   └── coverage → Codecov         ← Phase 3
  │
  ├── Flutter tests                  ← Already exists
  │
  ├── SonarQube quality gate         ← Phase 3
  │
  └── [on master only]
      ├── Trivy Docker scan          ← Phase 2
      └── Render deploy hook         ← Phase 4
```

## Tool Summary

| Tool | Category | Why Chosen |
|------|----------|-----------|
| **golangci-lint** | Go linter | Industry standard, 50+ linters, native GH action |
| **ESLint** | JS/TS linter | Already configured, just needs CI invocation |
| **Gitleaks** | Secret detection | Free, fast, dedicated GH action |
| **Dependabot** | Dep updates | Built into GitHub, zero config |
| **npm audit** | JS vulns | Already available, free |
| **govulncheck** | Go vulns | Official Go team tool |
| **Trivy** | Container scan | Open source, CI-native, covers OS + language deps |
| **SonarQube Cloud** | Quality gate | Free for public repos, PR comments, coverage tracking |
| **Codecov** | Coverage | Free for public, PR annotations, GitHub integration |
| **Render Deploy Hook** | Auto-deploy | Native Render feature, triggered via curl |
