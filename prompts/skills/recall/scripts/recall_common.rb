#!/usr/bin/env ruby
# frozen_string_literal: true

# 세션 recall 스크립트 공통 유틸리티
# recall-day.rb, extract-session.rb, recall-index.rb 에서 require_relative로 사용

require "json"
require "date"
require "pathname"
require "time"
require "set"

CLAUDE_PROJECTS = Pathname.new(Dir.home).join(".claude", "projects")
# Vault 위치: 단일 진실 소스는 documentation skill (~/.claude/skills/documentation/SKILL.md).
# 변경 시 documentation skill 갱신 후 이 경로 일괄 수정.
VAULT_ROOT      = Pathname.new(Dir.home).join("Documents", "obsidian")
LOGSEQ_JOURNALS = VAULT_ROOT.join("journals")
SESSION_DIR     = VAULT_ROOT.join(".session")
KNOW_DIR        = VAULT_ROOT.join("know")
LOGSEQ_PAGES    = VAULT_ROOT.join("pages") # legacy (마이그 후 미존재)

# system-reminder 등 시스템 태그 제거용 정규식
STRIP_PATTERNS = [
  %r{<system-reminder>.*?</system-reminder>}m,
  %r{<local-command-caveat>.*?</local-command-caveat>}m,
  %r{<local-command-stdout>.*?</local-command-stdout>}m,
  %r{<command-name>.*?</command-name>}m,
  %r{<command-message>.*?</command-message>}m,
  %r{<command-args>.*?</command-args>}m,
  %r{<available-deferred-tools>.*?</available-deferred-tools>}m,
  %r{<task-notification>.*?</task-notification>}m,
  %r{<user-prompt-submit-hook>.*?</user-prompt-submit-hook>}m,
  %r{<persisted-output>.*?</persisted-output>}m,
  %r{\[File History:.*?\n(?:.*?\n)*?(?=\n[^\d]|\z)}m,  # read-file-context.rb 주입 방어
].freeze

# 시스템 생성 메시지 (스킵 대상)
SKIP_MESSAGES = [
  /^\[Request interrupted by user.*\]$/,
  /^This session is being continued from a previous conversation/,
  /^## Continue:/,
  /^\*\*IMPORTANT/,
].freeze

# 파일명 금지 문자
STRIP_CHARS = /[<>:"\/\\|?*#^{}\[\]]/

def clean_content(text)
  return "" unless text.is_a?(String)

  STRIP_PATTERNS.each { |pat| text = text.gsub(pat, "") }
  text.strip
end

def skip_message?(text)
  SKIP_MESSAGES.any? { |pat| pat.match?(text) }
end

def extract_text(content)
  case content
  when String
    clean_content(content)
  when Array
    parts = content.filter_map do |block|
      case block
      when Hash
        block["text"] if block["type"] == "text"
      when String
        block
      end
    end
    clean_content(parts.join(" "))
  else
    ""
  end
end

def extract_tool_names(content)
  return [] unless content.is_a?(Array)

  content.filter_map do |block|
    block["name"] if block.is_a?(Hash) && block["type"] == "tool_use"
  end.uniq
end

def real_user_message?(obj)
  return false unless obj["type"] == "user"
  return false if obj["toolUseResult"]

  text = extract_text(obj.dig("message", "content") || "")
  return false if text.nil? || text.length < 5
  return false if text.match?(/^\/\w+\s*$/)
  return false if skip_message?(text)

  true
end

def parse_date_expr(expr)
  expr = expr.strip.downcase
  today = Date.today

  case expr
  when "", "today"
    [today, today]
  when "yesterday"
    d = today - 1
    [d, d]
  when /^(\d+)\s*days?\s*ago$/
    d = today - $1.to_i
    [d, d]
  when /^last\s+(\d+)\s*days?$/
    [today - $1.to_i, today]
  when "this week"
    [today - (today.cwday - 1), today] # Monday-based
  when "last week"
    this_monday = today - (today.cwday - 1)
    [this_monday - 7, this_monday - 1]
  when /^last\s+(\w+)$/
    weekdays = { "monday" => 1, "tuesday" => 2, "wednesday" => 3, "thursday" => 4,
                 "friday" => 5, "saturday" => 6, "sunday" => 7 }
    target = weekdays[$1]
    if target
      days_back = (today.cwday - target) % 7
      days_back = 7 if days_back == 0
      d = today - days_back
      [d, d]
    else
      warn "Error: cannot parse date expression '#{expr}'"
      exit 1
    end
  when /^\d{4}-\d{2}-\d{2}$/
    d = Date.parse(expr)
    [d, d]
  else
    warn "Error: cannot parse date expression '#{expr}'"
    warn "Supported: today, yesterday, N days ago, last N days, this week, last week, last monday, YYYY-MM-DD"
    exit 1
  end
end

def format_time(ts_str)
  return "??:??" if ts_str.nil? || ts_str.empty?

  Time.parse(ts_str).localtime.strftime("%H:%M")
rescue ArgumentError, TypeError
  "??:??"
end

def format_date(ts_str)
  return Date.today.to_s if ts_str.nil? || ts_str.empty?

  Time.parse(ts_str).localtime.strftime("%Y-%m-%d")
rescue ArgumentError, TypeError
  Date.today.to_s
end

def format_size(bytes)
  if bytes < 1024
    "#{bytes}B"
  elsif bytes < 1024 * 1024
    "#{bytes / 1024}KB"
  else
    "#{bytes / (1024 * 1024)}MB"
  end
end

def find_all_jsonl
  return [] unless CLAUDE_PROJECTS.exist?

  CLAUDE_PROJECTS.glob("*/*.jsonl").to_a
end

def dedup_sessions(sessions)
  seen = {}
  sessions.each do |s|
    sid = s[:session_id][0, 8]
    if !seen[sid] || s[:file_size] > seen[sid][:file_size]
      seen[sid] = s
    end
  end
  seen.values.sort_by { |s| s[:first_ts] || "" }
end

def derive_project(cwd)
  return nil if cwd.nil? || cwd.empty?

  cwd = cwd.sub(/\A~/, Dir.home)
  parts = cwd.split("/")

  parts.each_with_index do |part, i|
    return parts[i + 1] if part == "pj" && i + 1 < parts.length
  end

  # fallback: 마지막 의미있는 디렉토리
  parts.reverse_each { |p| return p unless p.empty? }
  nil
end

def derive_slug(text)
  text = text.strip.split("\n").first || ""
  text = text[0, 60].sub(/\s+\S*$/, "") if text.length > 60
  text = text.gsub(STRIP_CHARS, "").gsub(/\s+/, " ").strip
  text.empty? ? "untitled" : text
end

def duration_minutes(first_ts, last_ts)
  t1 = Time.parse(first_ts)
  t2 = Time.parse(last_ts)
  ((t2 - t1) / 60).to_i
rescue ArgumentError, TypeError, NoMethodError
  0
end
