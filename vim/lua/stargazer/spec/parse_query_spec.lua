local engine = require('stargazer.engine')
require('stargazer.modes')
local parse = engine.parse_query

T.describe('parse_query: mode dispatch', function()
  T.eq(parse('Wallet').mode, 'infer', 'PascalCase -> infer')
  T.eq(parse('GET /api').mode, 'router', 'HTTP method -> router')
  T.eq(parse('/users').mode, 'router', 'path prefix -> router')
  T.eq(parse('m:User').mode, 'model', 'prefix m: -> model')
  T.eq(parse('d:auth').mode, 'domain', 'prefix d: -> domain')
  T.eq(parse('s:create').mode, 'symbol', 'prefix s: -> symbol')
  T.eq(parse('&wallet').mode, 'context', '& prefix -> context')
  T.eq(parse('!').mode, 'git', '! prefix -> git')
  T.eq(parse('model User').mode, 'model', 'keyword -> model')
  T.eq(parse('hello world'), nil, 'no match -> nil')
end)

T.describe('parse_query: pipe filter', function()
  local p1 = parse('Wallet | client')
  T.eq(p1.mode, 'infer', 'pipe: mode preserved')
  T.eq(p1.pipe_filter, 'client', 'pipe: filter extracted')

  local p2 = parse('GET /api | health')
  T.eq(p2.mode, 'router', 'pipe: router mode')
  T.eq(p2.pipe_filter, 'health', 'pipe: filter extracted')

  -- no pipe
  T.eq(parse('Wallet').pipe_filter, nil, 'no pipe -> nil')
end)

T.describe('parse_query: query extraction', function()
  T.eq(parse('m:User').query, 'User', 'm:User -> query=User')
  T.eq(parse('GET /api/users').query, '/api/users', 'GET path extraction')
  T.eq(parse('Wallet').query, 'Wallet', 'PascalCase query')
  T.eq(parse('model User').query, 'user', 'keyword query (lowercased)')
  T.eq(parse('').mode, 'grep', 'empty -> grep fallback')
  T.eq(parse('').query, '', 'empty -> empty query')
end)

T.describe('parse_query: edge cases', function()
  -- nil / invalid input
  T.eq(parse(nil).mode, 'grep', 'nil -> grep fallback')
  T.eq(parse(nil).query, '', 'nil -> empty query')

  -- infer boundary: only strict PascalCase single word
  T.eq(parse('wallet'), nil, 'lowercase -> not infer')
  T.eq(parse('WALLET').mode, 'infer', 'all-caps -> infer (starts with upper)')
  T.eq(parse('Wallet Service'), nil, 'multi-word with space -> no match')
  T.eq(parse('WalletService').mode, 'infer', 'PascalCase compound -> infer')

  -- git mode
  T.eq(parse('!').mode, 'git', '! alone -> git')
  T.eq(parse('!').query, '', '! alone -> empty query')
  T.eq(parse('! handler').mode, 'git', '! query -> git')
  T.eq(parse('! handler').query, 'handler', '! query extraction')
  T.eq(parse('!handler').query, 'handler', '!query (no space) extraction')
  T.eq(parse('diff handler').mode, 'git', 'keyword diff -> git')
  T.eq(parse('staged handler').mode, 'git', 'keyword staged -> git')
  T.eq(parse('changed handler').mode, 'git', 'keyword changed -> git')

  -- keyword case insensitivity
  T.eq(parse('Model User').mode, 'model', 'capitalized keyword -> model')

  -- router prefix
  T.eq(parse('r:users').mode, 'router', 'r: prefix -> router')
  T.eq(parse('r:users').query, 'users', 'r: prefix query')

  -- empty pipe filter
  T.eq(parse('Wallet |').pipe_filter, nil, 'empty pipe -> nil')

  -- pipe with spaces
  local p = parse('Wallet |  client ')
  T.eq(p.pipe_filter, 'client ', 'pipe trims leading space only')
end)

T.describe('parse_query: folder filter @path/', function()
  -- basic extraction
  local p1 = parse('s:create @src/auth/')
  T.eq(p1.mode, 'symbol', 'folder: mode preserved')
  T.eq(p1.query, 'create', 'folder: query preserved')
  T.eq(p1.folder_filter, 'src/auth/', 'folder: extracted')

  -- folder at start
  local p2 = parse('@src/ m:User')
  T.eq(p2.mode, 'model', 'folder at start: mode ok')
  T.eq(p2.query, 'User', 'folder at start: query ok')
  T.eq(p2.folder_filter, 'src/', 'folder at start: extracted')

  -- folder with git mode
  local p3 = parse('! @vim/lua/')
  T.eq(p3.mode, 'git', 'folder + git: mode ok')
  T.eq(p3.folder_filter, 'vim/lua/', 'folder + git: extracted')

  -- folder + pipe combo
  local p4 = parse('Wallet @src/ | auth')
  T.eq(p4.mode, 'infer', 'folder+pipe: mode ok')
  T.eq(p4.folder_filter, 'src/', 'folder+pipe: folder extracted')
  T.eq(p4.pipe_filter, 'auth', 'folder+pipe: pipe extracted')

  -- no folder (no @)
  T.eq(parse('m:User').folder_filter, nil, 'no @ -> nil folder')

  -- @ without slash -> not a folder
  T.eq(parse('s:create @auth').folder_filter, nil, '@ without / -> nil folder')

  -- deep nested path
  local p5 = parse('s:create @src/auth/controllers/')
  T.eq(p5.folder_filter, 'src/auth/controllers/', 'deep nested path')

  -- multiple @ -> first wins, second stays in raw
  local p6 = parse('s:create @src/ @lib/')
  T.eq(p6.folder_filter, 'src/', 'multiple @: first wins')
  T.eq(p6.mode, 'symbol', 'multiple @: mode still parsed')
end)

T.describe('parse_query: git mode pipe', function()
  local p = parse('! handler | auth')
  T.eq(p.mode, 'git', 'git pipe: mode preserved')
  T.eq(p.query, 'handler', 'git pipe: query extracted')
  T.eq(p.pipe_filter, 'auth', 'git pipe: filter extracted')
end)

T.describe('parse_query: folder exclude @!path/', function()
  local p1 = parse('s:create @!test/')
  T.eq(p1.mode, 'symbol', 'folder exclude: mode preserved')
  T.eq(p1.query, 'create', 'folder exclude: query preserved')
  T.eq(p1.folder_filter, 'test/', 'folder exclude: path extracted')
  T.eq(p1.folder_exclude, true, 'folder exclude: flag set')

  -- deep path
  local p2 = parse('Wallet @!src/test/')
  T.eq(p2.folder_filter, 'src/test/', 'folder exclude: deep path')
  T.eq(p2.folder_exclude, true, 'folder exclude: deep flag')

  -- include (no !) -> exclude nil
  local p3 = parse('s:create @src/')
  T.eq(p3.folder_filter, 'src/', 'folder include: path ok')
  T.eq(p3.folder_exclude, nil, 'folder include: no exclude flag')
end)

T.describe('parse_query: pipe exclude | !filter', function()
  local p1 = parse('Wallet | !Test')
  T.eq(p1.mode, 'infer', 'pipe exclude: mode preserved')
  T.eq(p1.pipe_filter, 'Test', 'pipe exclude: filter extracted')
  T.eq(p1.pipe_exclude, true, 'pipe exclude: flag set')

  -- include (no !) -> exclude nil
  local p2 = parse('Wallet | client')
  T.eq(p2.pipe_filter, 'client', 'pipe include: filter ok')
  T.eq(p2.pipe_exclude, nil, 'pipe include: no exclude flag')

  -- both folder exclude + pipe exclude
  local p3 = parse('Wallet @!test/ | !Mock')
  T.eq(p3.folder_filter, 'test/', 'combo: folder path')
  T.eq(p3.folder_exclude, true, 'combo: folder exclude')
  T.eq(p3.pipe_filter, 'Mock', 'combo: pipe filter')
  T.eq(p3.pipe_exclude, true, 'combo: pipe exclude')

  -- "| !" with no filter text -> nil
  T.eq(parse('Wallet | !').pipe_filter, nil, 'empty exclude -> nil')
  T.eq(parse('Wallet | !').pipe_exclude, nil, 'empty exclude -> no flag')
end)
