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
