#!/usr/bin/env ruby
# frozen_string_literal: true

# PreToolUse hook: Read 전에 해당 파일의 과거 세션 이력을 주입
# matcher: Read
# stdin: JSON { tool_name, tool_input: { file_path }, session_id, transcript_path }
# stdout: JSON { hookSpecificOutput: { additionalContext, permissionDecision } }

require "json"
require "pathname"

# Vault 위치: documentation skill 단일 진실 소스. 변경 시 함께 수정.
SESSION_DIR  = Pathname.new(Dir.home).join("Documents", "obsidian", ".session")
MAX_SESSIONS = 5
MIN_MATCHES  = 2

begin
  input = JSON.parse($stdin.read)
rescue JSON::ParserError
  exit 0
end

file_path = input.dig("tool_input", "file_path")
exit 0 if file_path.nil? || file_path.empty?
exit 0 unless SESSION_DIR.exist?

# 절대경로 → ~ 축약 (세션 페이지가 ~/... 형식으로 저장)
home = Dir.home
search_path = file_path.start_with?(home) ? "~#{file_path[home.length..]}" : file_path

# 현재 세션 ID (8자) — 자기 세션 제외용
current_sid = (input["session_id"] || "")[0, 8]

# 세션 페이지에서 파일 경로 매치 검색
matches = Dir.glob(SESSION_DIR.join("**", "*.md").to_s).select do |page|
  File.foreach(page, encoding: "utf-8").any? { |line| line.include?(search_path) }
rescue Errno::ENOENT, Encoding::InvalidByteSequenceError
  false
end

# 파일명에 날짜 prefix → 사전순 정렬 = 시간순
matches.sort!.reverse!

# 현재 세션 제외 (파일명 끝의 8자 sid)
unless current_sid.empty?
  matches.reject! { |p| File.basename(p, ".md").end_with?(current_sid) }
end

exit 0 if matches.size < MIN_MATCHES

# 각 세션 페이지에서 frontmatter + summary 추출
entries = []
matches.first(MAX_SESSIONS).each do |page|
  date = nil
  sid = nil
  status = nil
  summary = nil
  in_fm = false
  fm_done = false
  in_summary_section = false

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
      end
      next
    end

    case line
    when /^- # Summary/
      in_summary_section = true
    when /^- # /
      in_summary_section = false
    else
      if in_summary_section && summary.nil?
        stripped = line.strip.sub(/^\t*- /, "")
        summary = stripped[0, 80] unless stripped.empty?
      end
    end
  end

  entries << "#{date} sid:#{sid} [#{status || '?'}] #{summary || '(no summary)'}" if date && sid
rescue Errno::ENOENT, Encoding::InvalidByteSequenceError
  next
end

exit 0 if entries.empty?

basename = File.basename(file_path)
context = "[File History: #{basename} — #{matches.size} sessions]\n#{entries.join("\n")}"

result = {
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: context,
    permissionDecision: "allow",
  },
}

puts JSON.generate(result)
