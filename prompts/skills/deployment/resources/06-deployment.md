# Deployment Automation

서비스 배포 및 프로세스 관리 가이드입니다.

## 배포 스크립트

### 기본 배포

**scripts/deploy.sh**
```bash
#!/bin/bash
set -e

echo "🚀 Deploying..."

git pull origin main
npm ci --production
npm run build

# 헬스체크
if curl -f http://localhost:3000/health; then
    pm2 reload ecosystem.config.js --update-env
    echo "✓ Deployment complete!"
else
    echo "✗ Health check failed"
    exit 1
fi
```

### 롤백

**scripts/rollback.sh**
```bash
#!/bin/bash
set -e

PREV=$(git rev-parse HEAD~1)
echo "⏪ Rolling back to $PREV..."

git reset --hard $PREV
npm ci --production
npm run build
pm2 reload ecosystem.config.js

echo "✓ Rollback complete!"
```

## PM2

### ecosystem.config.js

```javascript
module.exports = {
  apps: [
    {
      name: 'api',
      script: './dist/index.js',
      instances: 'max',
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
      },
      error_file: './logs/error.log',
      out_file: './logs/out.log',
      max_memory_restart: '1G',
      autorestart: true,
    },
    {
      name: 'worker',
      script: './dist/worker.js',
      instances: 2,
      cron_restart: '0 3 * * *',  // 매일 3시
    },
  ],
}
```

### PM2 명령

```bash
# 시작
pm2 start ecosystem.config.js

# 재시작 (Zero-downtime)
pm2 reload ecosystem.config.js

# 정지
pm2 stop all

# 로그
pm2 logs

# 모니터링
pm2 monit

# 자동 시작
pm2 save
pm2 startup
```

## Justfile

```justfile
# 배포
deploy:
    @echo "🚀 Deploying..."
    git pull origin main
    npm ci --production
    npm run build
    pm2 reload ecosystem.config.js
    @echo "✓ Done!"

# 롤백
rollback:
    @echo "⏪ Rolling back..."
    git reset --hard HEAD~1
    npm ci --production
    npm run build
    pm2 reload ecosystem.config.js
    @echo "✓ Done!"

# 로그
logs service="":
    @if [ -z "{{service}}" ]; then \
        pm2 logs; \
    else \
        pm2 logs {{service}}; \
    fi

# 재시작
restart service="":
    @if [ -z "{{service}}" ]; then \
        pm2 restart all; \
    else \
        pm2 restart {{service}}; \
    fi

# 헬스체크
health:
    @curl -f http://localhost:3000/health && echo "✓ Healthy" || echo "✗ Unhealthy"

# 상태
status:
    pm2 status
```

## Zero-Downtime

### PM2 설정
```javascript
{
  listen_timeout: 10000,
  kill_timeout: 5000,
}
```

### Graceful Shutdown

```typescript
const server = app.listen(3000)

process.on('SIGINT', async () => {
  console.log('Shutting down...')

  server.close(async () => {
    // 진행 중인 요청 완료
    await db.$disconnect()
    await redis.quit()

    process.exit(0)
  })

  // 타임아웃
  setTimeout(() => {
    process.exit(1)
  }, 10000)
})
```

## 환경변수

### .env

```bash
# .env.production (gitignore)
NODE_ENV=production
DATABASE_URL=postgres://...
REDIS_URL=redis://...

# .env.example (git 포함)
NODE_ENV=development
DATABASE_URL=postgres://localhost/dev
```

### PM2

```javascript
{
  env: {
    NODE_ENV: 'development',
  },
  env_production: {
    NODE_ENV: 'production',
  },
}
```

```bash
pm2 start ecosystem.config.js --env production
```

## 헬스체크

```typescript
app.get('/health', async (req, res) => {
  try {
    await db.$queryRaw`SELECT 1`
    await redis.ping()

    res.json({
      status: 'ok',
      uptime: process.uptime(),
    })
  } catch (error) {
    res.status(503).json({
      status: 'error',
      error: error.message,
    })
  }
})
```

## 로그

### PM2 로그 로테이션

```bash
pm2 install pm2-logrotate

pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7
pm2 set pm2-logrotate:compress true
```

## 베스트 프랙티스

### 항상 헬스체크
```bash
if ! curl -f http://localhost:3000/health; then
    rollback
fi
```

### 백업
```bash
git tag -a v1.0.0-$(date +%Y%m%d-%H%M%S) -m "Pre-deployment"
```

### 점진적 재시작
```javascript
pm2 reload api --update-env --parallel 1
```

## 트러블슈팅

### 포트 사용 중
```bash
lsof -i :3000
kill -9 <PID>
```

### PM2 응답 없음
```bash
pm2 restart all --force

pm2 kill
pm2 resurrect
```

## 참고

- PM2: https://pm2.keymetrics.io/
- Node.js 프로덕션: https://nodejs.org/en/docs/guides/
