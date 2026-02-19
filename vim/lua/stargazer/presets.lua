-- stargazer/presets.lua — 프레임워크 프리셋 데이터 (OCP: 이 파일만 수정)

local engine = require('stargazer.engine')

engine.register_preset('rails', {
  detect = 'Gemfile',
  router = {
    { glob = 'config/routes.rb', pattern = '(get|post|put|patch|delete|resources|resource|match)\\s' },
    { glob = 'app/controllers/**/*.rb', pattern = 'def\\s+(index|show|create|update|destroy|new|edit)' },
  },
  model = {
    { glob = 'app/models/**/*.rb', pattern = 'class\\s+\\w+' },
    { glob = 'db/migrate/**/*.rb', pattern = 'create_table|add_column|change_column' },
  },
  domain = {
    { glob = 'app/services/**/*.rb', pattern = 'class\\s+\\w+' },
    { glob = 'app/jobs/**/*.rb', pattern = 'class\\s+\\w+' },
  },
})

engine.register_preset('spring', {
  detect = 'pom.xml',
  router = {
    { glob = '**/*.java', pattern = '@(Get|Post|Put|Delete|Patch|Request)Mapping' },
  },
  model = {
    { glob = '**/*.java', pattern = '@(Entity|Table|Document)' },
  },
  domain = {
    { glob = '**/*.java', pattern = '@(Service|Repository|Component)' },
  },
})

engine.register_preset('express', {
  detect = 'package.json',
  detect_content = { file = 'package.json', pattern = '"express"' },
  router = {
    { glob = '**/*.{js,ts}', pattern = '(app|router)\\.(get|post|put|delete|patch|all)\\(' },
  },
  model = {
    { glob = '**/*.{js,ts}', pattern = '(mongoose\\.model|sequelize\\.define|Schema\\()' },
  },
  domain = {
    { glob = { '**/services/**/*.{js,ts}', '**/middleware/**/*.{js,ts}' }, pattern = '(class|export|module\\.exports)' },
  },
})

engine.register_preset('fastapi', {
  detect = 'pyproject.toml',
  detect_content = { file = 'pyproject.toml', pattern = 'fastapi' },
  router = {
    { glob = '**/*.py', pattern = '@(app|router)\\.(get|post|put|delete|patch)' },
  },
  model = {
    { glob = '**/*.py', pattern = 'class\\s+\\w+.*Base\\)|class\\s+\\w+.*Model\\)' },
  },
  domain = {
    { glob = { '**/services/**/*.py', '**/repositories/**/*.py' }, pattern = '(class|def)\\s+\\w+' },
  },
})

engine.register_preset('django', {
  detect = 'manage.py',
  router = {
    { glob = '**/urls.py', pattern = 'path\\(|re_path\\(|url\\(' },
    { glob = '**/views.py', pattern = 'def\\s+\\w+.*request' },
  },
  model = {
    { glob = '**/models.py', pattern = 'class\\s+\\w+.*models\\.Model' },
    { glob = '**/models/**/*.py', pattern = 'class\\s+\\w+.*models\\.Model' },
  },
  domain = {
    { glob = { '**/services/**/*.py', '**/serializers.py' }, pattern = '(class|def)\\s+\\w+' },
  },
})

engine.register_preset('nextjs', {
  detect = 'next.config.*',
  router = {
    { glob = 'app/**/route.{js,ts}', pattern = 'export.*(GET|POST|PUT|DELETE|PATCH)' },
    { glob = 'pages/api/**/*.{js,ts}', pattern = 'export\\s+default' },
  },
  model = {
    { glob = '**/*.{js,ts}', pattern = '(prisma|mongoose|sequelize)' },
  },
  domain = {
    { glob = { 'lib/**/*.{js,ts}', 'services/**/*.{js,ts}' }, pattern = '(export|class)\\s+\\w+' },
  },
})

engine.register_preset('nestjs', {
  detect = 'nest-cli.json',
  router = {
    { glob = '**/*.ts', pattern = '@(Get|Post|Put|Delete|Patch|All|Head|Options)\\(' },
    { glob = '**/*.ts', pattern = '@Controller\\(' },
  },
  model = {
    { glob = '**/*.ts', pattern = '@(Entity|Schema)\\(' },
  },
  domain = {
    { glob = '**/*.ts', pattern = '@(Injectable|Controller)\\(' },
  },
})
