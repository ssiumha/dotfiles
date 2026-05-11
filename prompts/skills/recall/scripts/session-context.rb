#!/usr/bin/env ruby
# frozen_string_literal: true

# SessionStart hook — 새 세션 시작 시 프로젝트별 최근 세션 compact index 주입
# matcher: 없음 (모든 SessionStart에서 fire)
# stdout → Claude 컨텍스트에 주입됨
#
# compact 이벤트일 때는 건너뜀 (session-start.sh의 WIP 복원이 더 구체적)
# 환경변수 CLAUDE_RECALL_AUTO_INJECT=0 으로 비활성화 가능

require "json"
require "pathname"

# Vault 위치: documentation skill 단일 진실 소스. 변경 시 함께 수정.
VAULT_ROOT   = Pathname.new(Dir.home).join("Documents", "obsidian")
SESSION_DIR  = VAULT_ROOT.join(".session")
MAX_SESSIONS = 5
MAX_KEY_FILES = 3

exit 0 if ENV["CLAUDE_RECALL_AUTO_INJECT"] == "0"
exit 0 unless SESSION_DIR.exist?

begin
  input = JSON.parse($stdin.read)
rescue JSON::ParserError
  exit 0
end

# compact 이벤트면 건너뜀 — WIP 훅이 더 구체적
exit 0 if input["session_type"] == "compact"

# cwd에서 프로젝트명 추출
cwd = input["cwd"] || Dir.pwd

def derive_project(cwd)
  parts = cwd.split("/")
  parts.each_with_index { |p, i| return parts[i + 1] if p == "pj" && i + 1 < parts.length }
  parts.reverse_each { |p| return p unless p.empty? }
  nil
end

project = derive_project(cwd)
exit 0 if project.nil? || project.empty?

# frontmatter `project: session-{name}` 매치하는 세션 페이지 검색 (최신순)
# 파일명: "YYYY-MM-DD {slug} {sid8}.md" — 날짜순 정렬 = 파일명 정렬
project_marker = "project: session-#{project}"
pages = Dir.glob(SESSION_DIR.join("**", "*.md").to_s).select do |page|
  found = false
  in_fm = false
  begin
    File.foreach(page, encoding: "utf-8") do |line|
      if line.start_with?("---")
        in_fm = !in_fm
        break unless in_fm  # 두 번째 --- 닫힘 → 종료
        next
      end
      next unless in_fm
      if line.strip == project_marker
        found = true
        break
      end
    end
  rescue Errno::ENOENT, Encoding::InvalidByteSequenceError
    found = false
  end
  found
end

exit 0 if pages.empty?

pages.sort!.reverse!  # 파일명에 날짜 포함 → 최신순

# 각 페이지에서 compact index 항목 추출
entries = []
pages.first(MAX_SESSIONS).each do |page|
  date = nil
  sid = nil
  status = nil
  msgs = nil
  request = nil
  investigated = nil
  completed = nil
  files = []
  in_files = false
  in_summary = false
  in_fm = false
  fm_done = false

  File.foreach(page, encoding: "utf-8") do |line|
    if !fm_done && line.start_with?("---")
      if !in_fm
        in_fm = true
      else
        in_fm = false
        fm_done = true
      end
      next
    end

    if in_fm
      case line
      when /^date:\s*['"]?([^'"\n]+)['"]?/
        date = $1.strip
      when /^session-id:\s*['"]?([^'"\n]+)['"]?/
        sid = $1.strip
      when /^status:\s*['"]?([^'"\n]+)['"]?/
        status = $1.strip
      when /^messages:\s*['"]?([^'"\n]+)['"]?/
        msgs = $1.strip
      end
      next
    end

    case line
    when /^- # Summary/
      in_summary = true
    when /^- # Files/
      in_summary = false
      in_files = true
    when /^- # /
      in_summary = false
      in_files = false
    else
      if in_summary
        case line
        when /\*\*Request\*\*:\s*(.+)/
          request = $1.strip[0, 80]
        when /\*\*Investigated\*\*:\s*(.+)/
          investigated = $1.strip[0, 60]
        when /\*\*Completed\*\*:\s*(.+)/
          completed = $1.strip[0, 80]
        when /^\t- /
          request ||= line.strip.sub(/^\t*- /, "")[0, 80]
        end
      end
      if in_files && line.match?(/^\t- `(.+)`/)
        f = line.strip.sub(/^- `/, "").sub(/`$/, "")
        files << File.basename(f)
      end
    end
  end

  next unless date && sid

  entry = "#{date} [#{status || '?'}] #{msgs || '?'}msgs sid:#{sid}"
  entry += "\n  → #{request}" if request && !request.empty?
  entry += "\n  investigated: #{investigated}" if investigated
  entry += "\n  completed: #{completed}" if completed
  entry += "\n  files: #{files.first(MAX_KEY_FILES).join(', ')}" if files.any?
  entries << entry
rescue Errno::ENOENT, Encoding::InvalidByteSequenceError
  next
end

exit 0 if entries.empty?

puts "=== #{project} session index ==="
puts ""
entries.each { |e| puts e }
puts ""
puts "위 세션 맥락을 확인하고, 현재 작업과 관련이 있으면 /recall 을 실행하여 상세 컨텍스트를 복원하세요."
