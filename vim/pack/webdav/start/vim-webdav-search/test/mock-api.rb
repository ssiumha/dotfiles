#!/usr/bin/env ruby
# Mock of the vault search index, implementing doc/vault-search-api.openapi.yaml
# with Ruby built-ins only. Paths mirror the WebDAV fixture tree so a result can
# actually be opened.

require 'socket'
require 'uri'
require 'json'

PORT = (ENV['MOCK_API_PORT'] || 9998).to_i

INDEX = {
  'commit' => '4f2c1ab9d3e5c7180a2b6f4d8e1c9a3b5d7f0e2c',
  'indexed_at' => '2026-08-31T12:00:00Z',
  'note_count' => 4
}.freeze

# Line-addressable corpus. Searching it for real keeps the tests honest: a query
# has to match something that is actually there.
CORPUS = {
  'test/file1.txt' => [
    'This is test file content.',
    'Ceph runs here too, outside test/deep.',
    'Line 3'
  ],
  'test/deep/aaa.md' => [
    '# AAA Document',
    'Ceph is a distributed storage system.',
    'See [[file1|별칭]] for details.',
    'Tagged #infra and #infra/k8s here.'
  ],
  'test/한글.md' => [
    '# 한글 문서',
    '',
    '테스트 내용입니다.'
  ],
  'test/deep/subfolder/nested.txt' => [
    'Nested file content'
  ]
}.freeze

# The names a note goes by, for in=title. Filename comes from the path.
ALIASES = {
  'test/deep/aaa.md' => ['Ceph notes']
}.freeze

NOTE_TAGS = {
  'test/deep/aaa.md' => %w[infra infra/k8s],
  'test/file1.txt' => %w[devops],
  'test/한글.md' => %w[noise]
}.freeze

# One entry per link occurrence, the shape the spec calls LinkOccurrence.
LINKS = [
  {
    'path' => 'test/deep/aaa.md',
    'title' => 'AAA Document',
    'line' => 3,
    'text' => 'See [[file1|별칭]] for details.',
    'link' => {
      'raw' => '[[file1|별칭]]',
      'target' => 'file1',
      'alias' => '별칭',
      'heading' => nil,
      'block' => nil,
      'kind' => 'wikilink',
      'embed' => false
    },
    'resolved_path' => 'test/file1.txt',
    'matched_by' => 'basename'
  },
  {
    'path' => 'test/deep/aaa.md',
    'title' => 'AAA Document',
    'line' => 4,
    'text' => 'Tagged #infra and #infra/k8s here.',
    'link' => {
      'raw' => '[[nowhere]]',
      'target' => 'nowhere',
      'alias' => nil,
      'heading' => nil,
      'block' => nil,
      'kind' => 'wikilink',
      'embed' => false
    },
    'resolved_path' => nil,
    'matched_by' => nil
  }
].freeze

def tagged?(path, tag)
  NOTE_TAGS.fetch(path, []).any? { |n| n == tag || n.start_with?("#{tag}/") }
end

def title_for(path)
  first = CORPUS.fetch(path, []).find { |l| l.start_with?('# ') }
  first ? first.sub(/^#\s*/, '') : File.basename(path, '.*')
end

def hit(path, line, text, matched_in, query)
  {
    'path' => path,
    'title' => title_for(path),
    'line' => line,
    'column' => query.empty? ? 1 : (text.downcase.index(query.downcase) || 0) + 1,
    'text' => text,
    'score' => 0.9,
    'matched_in' => matched_in
  }
end

def matches?(text, query)
  query.empty? || text.downcase.include?(query.downcase)
end

# in=title reads the names a note goes by; in=content reads its body
def title_hits(path, lines, query)
  found = []
  name = File.basename(path, '.*')
  found << hit(path, 1, name, 'filename', query) if matches?(name, query)
  ALIASES.fetch(path, []).each do |a|
    found << hit(path, 1, a, 'alias', query) if matches?(a, query)
  end
  lines.each_with_index do |line, idx|
    next unless line.start_with?('#')
    found << hit(path, idx + 1, line, 'heading', query) if matches?(line, query)
  end
  found
end

def content_hits(path, lines, query)
  lines.each_with_index.filter_map do |line, idx|
    hit(path, idx + 1, line, 'content', query) if matches?(line, query)
  end
end

def search(params)
  query = Array(params['q']).first.to_s
  where = Array(params['in']).first || 'content'
  tags = Array(params['tag'])
  excluded = Array(params['exclude_tag'])
  prefixes = Array(params['path'])
  hits = []

  CORPUS.each do |path, lines|
    next if prefixes.any? && prefixes.none? { |p| path.start_with?(p) }
    next if tags.any? && !tags.all? { |t| tagged?(path, t) }
    next if excluded.any? { |t| tagged?(path, t) }

    hits.concat(title_hits(path, lines, query)) if %w[title all].include?(where)
    hits.concat(content_hits(path, lines, query)) if %w[content all].include?(where)
  end

  hits.sort_by { |h| [-h['score'], h['path'], h['line']] }
end

def backlinks(params)
  path = Array(params['path']).first.to_s
  name = Array(params['name']).first.to_s
  LINKS.select do |occurrence|
    if !path.empty?
      occurrence['resolved_path'] == path
    elsif !name.empty?
      occurrence['link']['target'] == name || occurrence['link']['alias'] == name
    else
      false
    end
  end
end

def outgoing(params)
  path = Array(params['path']).first.to_s
  state = Array(params['state']).first || 'all'
  found = LINKS.select { |o| o['path'] == path }
  case state
  when 'resolved' then found.select { |o| o['resolved_path'] }
  when 'unresolved' then found.reject { |o| o['resolved_path'] }
  else found
  end
end

def tags(_params)
  counts = Hash.new(0)
  notes = Hash.new { |h, k| h[k] = [] }
  NOTE_TAGS.each do |path, list|
    list.each do |tag|
      counts[tag] += 1
      notes[tag] << path
    end
  end
  counts.map { |tag, count| { 'tag' => tag, 'count' => count, 'note_count' => notes[tag].uniq.size } }
        .sort_by { |e| [-e['count'], e['tag']] }
end

def render(results, params)
  format = Array(params['format']).first || 'json'
  headers = [
    "X-Vault-Commit: #{INDEX['commit']}",
    "X-Vault-Indexed-At: #{INDEX['indexed_at']}",
    "X-Result-Total: #{results.size}"
  ]

  if format == 'ndjson'
    body = results.map { |r| JSON.generate(r) }.join("\n")
    body += "\n" unless body.empty?
    [body, 'application/x-ndjson', headers]
  else
    body = JSON.generate('results' => results, 'total' => results.size, 'index' => INDEX)
    [body, 'application/json', headers]
  end
end

def error(status, message)
  [JSON.generate('error' => message), 'application/json', [], status]
end

def handle(path, params)
  case path
  when '/api/vault/search'
    return error('400 Bad Request', 'q or tag required') if Array(params['q']).first.to_s.empty? && Array(params['tag']).empty?

    render(search(params), params)
  when '/api/vault/backlinks'
    return error('400 Bad Request', 'path or name required') if Array(params['path']).empty? && Array(params['name']).empty?

    render(backlinks(params), params)
  when '/api/vault/links'
    return error('400 Bad Request', 'path required') if Array(params['path']).empty?

    render(outgoing(params), params)
  when '/api/vault/tags'
    render(tags(params), params)
  else
    error('404 Not Found', 'no such endpoint')
  end
end

server = TCPServer.new(PORT)
warn "Mock search index on http://localhost:#{PORT}"

loop do
  Thread.start(server.accept) do |client|
    begin
      request = client.gets
      next if request.nil?

      _method, target, = request.split(' ')
      while (line = client.gets)
        break if line == "\r\n"
      end

      uri = URI.parse(target)
      params = Hash.new { |h, k| h[k] = [] }
      URI.decode_www_form(uri.query.to_s).each { |k, v| params[k] << v }

      body, content_type, headers, status = handle(uri.path, params)
      status ||= '200 OK'

      client.print "HTTP/1.1 #{status}\r\n"
      client.print "Content-Type: #{content_type}; charset=utf-8\r\n"
      client.print "Content-Length: #{body.bytesize}\r\n"
      headers.each { |h| client.print "#{h}\r\n" }
      client.print "Connection: close\r\n\r\n"
      client.print body
    rescue StandardError => e
      warn "mock-api: #{e.class}: #{e.message}"
    ensure
      client.close rescue nil
    end
  end
end
