# Before / After Examples

## Justfile Examples

### Case 1: myapp project

**Before** (current):
```just
deploy-api ENV:         # verb-noun, no group
db-migrate-api ENV:     # noun-verb-noun, -api redundant
db-status-api ENV:      # noun-noun-noun, verb unclear
logs SERVICE ENV:       # bare noun
init-hook:              # verb-noun, no group
```

**After** (principles applied):
```just
[group('deploy')]
# Deploy API service to target environment
deploy-api ENV:

[group('db')]
# Run database migrations for target environment
db-migrate ENV:

[group('db')]
# Show migration status for target environment
db-status ENV:

[group('api')]
# Stream service logs (follow mode)
api-log ENV:

[group('setup')]
# Initialize git hooks
setup-hook:
```

Changes:
- `db-migrate-api` -> `db-migrate`: remove redundant `-api` (single DB in project)
- `logs` -> `api-log`: fix bare noun + place in service group
- Add `[group]` attribute to all recipes
- Standardize descriptions to imperative verb-first

### Case 2: mobile project

**Before** (current):
```just
android:                # bare noun (actually builds)
ios:                    # bare noun
android-deploy:         # noun-verb
fetch-api:              # verb-noun
api-update:             # noun-verb
codegen:                # compound, no group
```

**After** (principles applied):
```just
[group('build')]
# Build Android APK
build-android:

[group('build')]
# Build iOS archive
build-ios:

[group('deploy')]
# Deploy Android build to Firebase
deploy-android:

[group('api')]
# Fetch OpenAPI spec from server
api-fetch-spec:

[group('api')]
# Update API client from spec
api-update-client:

[group('api')]
# Generate code from API spec
api-codegen:
```

Changes:
- `android` -> `build-android`: fix bare noun, add verb
- `android-deploy` -> `deploy-android`: cross-service action goes to verb group
- `fetch-api` -> `api-fetch-spec`: service-specific action goes to noun group
- `codegen` -> `api-codegen`: add group prefix

## Makefile Example

**Before**:
```makefile
install-k3d:            ## Install k3d
start-develop-db:       ## Start MySQL, Redis, ES, Kafka containers
stop-develop-db:        ## Stop MySQL, Redis, ES, Kafka containers
```

**After**:
```makefile
.PHONY: setup-k3d
setup-k3d:              ## Install k3d binary

.PHONY: docker-up
docker-up:              ## Start all dev containers (MySQL, Redis, ES, Kafka)

.PHONY: docker-down
docker-down:            ## Stop all dev containers
```

Changes:
- `install-k3d` -> `setup-k3d`: `install` not in standard verbs, use `setup`
- `start-develop-db` -> `docker-up`: use `up`/`down` pair, remove `develop` (local is default)
