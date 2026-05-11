#!/usr/bin/env ruby
# frozen_string_literal: true

# 일일 정보 신선도 점검 스크립트
#
# 기능:
#   1. 미기록 작업 탐색 — 유의미한 세션이 debrief 없이 끝난 경우
#   2. Stale 페이지 탐색 — open status 페이지의 freshness 체크
#   3. 고아 TODO 탐색 — 14일+ 미완료 TODO
#   4. Standup 재료 준비
#
# Usage:
#   ruby wakeup-reconcile.rb [--days N] [--stale-days N] [--dry-run]
#
# 읽기 전용, 멱등. 어떤 파일도 수정하지 않음.

require_relative "recall_common"
require "optparse"

# --- 설정 ---

options = { days: 1, stale_days: 14, dry_run: false }
OptionParser.new do |opts|
  opts.banner = "Usage: wakeup-reconcile.rb [options]"
  opts.on("--days N", Integer, "Look back N days (default: 1)") { |v| options[:days] = v }
  opts.on("--stale-days N", Integer, "Staleness threshold (default: 14)") { |v| options[:stale_days] = v }
  opts.on("--dry-run", "Show report without side effects") { options[:dry_run] = true }
end.parse!

TODAY = Date.today
LOOKBACK_START = TODAY - options[:days]
STALE_THRESHOLD = options[:stale_days]

# --- 1. 미기록 작업 탐색 ---

def scan_significant_sessions(start_date, end_date)
  sessions = find_all_jsonl.filter_map do |jsonl|
    scan_session_for_work(jsonl.to_s, start_date, end_date)
  end
  dedup_sessions(sessions)
end

def scan_session_for_work(filepath, start_date, end_date)
  session_id = nil
  first_ts = nil
  first_user_msg = nil
  user_count = 0
  tool_names = Set.new
  cwd = nil
  file_size = File.size(filepath)
  found_ts = false

  File.foreach(filepath, encoding: "utf-8") do |line|
    line.strip!
    next if line.empty?

    obj = begin; JSON.parse(line); rescue JSON::ParserError; next; end

    session_id ||= obj["sessionId"] if obj["sessionId"]
    cwd ||= obj["cwd"] if obj["cwd"]

    if !found_ts && obj["timestamp"] && !obj["timestamp"].empty?
      begin
        local_date = Time.parse(obj["timestamp"]).localtime.to_date
        return nil if local_date < start_date || local_date > end_date
        first_ts = obj["timestamp"]
        found_ts = true
      rescue ArgumentError
        next
      end
    end

    if real_user_message?(obj)
      user_count += 1
      text = extract_text(obj.dig("message", "content") || "")
      first_user_msg ||= text if text && !text.empty?
    end

    names = extract_tool_names(obj.dig("message", "content") || [])
    names.each { |n| tool_names.add(n) }
  end

  return nil unless first_ts
  return nil if user_count < 3 # 너무 짧은 세션 무시

  {
    session_id: session_id || File.basename(filepath, ".jsonl"),
    first_ts: first_ts,
    first_msg: first_user_msg || "(no message)",
    user_count: user_count,
    file_size: file_size,
    filepath: filepath,
    cwd: cwd,
    tool_names: tool_names,
    project: derive_project(cwd),
  }
rescue Errno::ENOENT, Encoding::InvalidByteSequenceError
  nil
end

def find_debrief_dates_by_project
  debriefs = {}
  LOGSEQ_PAGES.glob("pj-*___debrief___*.md").each do |f|
    project = nil
    date = nil
    File.foreach(f, encoding: "utf-8") do |line|
      if line.start_with?("project::")
        m = line.match(/\[\[pj-([^\]]+)\]\]/)
        project = m[1] if m
      elsif line.start_with?("date::")
        m = line.match(/\[\[(\d{4}-\d{2}-\d{2})\]\]/)
        date = m[1] if m
      end
      break if project && date
    end
    debriefs["#{project}:#{date}"] = true if project && date
  rescue Errno::ENOENT, Encoding::InvalidByteSequenceError
    next
  end
  debriefs
end

def find_unrecorded_sessions(start_date, end_date)
  sessions = scan_significant_sessions(start_date, end_date)
  debriefs = find_debrief_dates_by_project

  # Edit/Write 도구 사용이 있는 유의미한 세션만 (Bash 제외 — 거의 모든 세션이 Bash 사용)
  significant = sessions.select do |s|
    has_edits = (s[:tool_names] & Set["Edit", "Write"]).size > 0
    has_edits && s[:user_count] >= 5
  end

  significant.reject do |s|
    session_date = format_date(s[:first_ts])
    project = s[:project]
    # 같은 날짜+프로젝트의 debrief가 있으면 기록됨
    debriefs["#{project}:#{session_date}"]
  end
end

# --- 2. Stale 페이지 탐색 ---

ACTIVE_STATUSES = Set["open", "in-progress", "investigating", "waiting", "blocked", "draft"].freeze

def parse_page_properties(filepath)
  props = {}
  File.foreach(filepath, encoding: "utf-8") do |line|
    break if line.start_with?("- ") # outliner 본문 시작
    if line.match?(/^\w[\w-]*::/)
      key, val = line.split("::", 2)
      props[key.strip] = val.strip if val
    end
  end
  props
rescue Errno::ENOENT, Encoding::InvalidByteSequenceError
  {}
end

def extract_date_from_prop(val)
  m = val&.match(/(\d{4}-\d{2}-\d{2})/)
  m ? Date.parse(m[1]) : nil
rescue ArgumentError
  nil
end

def find_stale_pages(stale_days)
  stale = []

  # pj- 프로젝트 namespace + 루트 namespace 모두 스캔
  candidates = LOGSEQ_PAGES.glob("pj-*___*___*.md") + LOGSEQ_PAGES.glob("*___*.md").reject { |f| f.basename.to_s.start_with?("pj-") }
  candidates.each do |f|
    props = parse_page_properties(f.to_s)
    status = props["status"]&.strip&.downcase
    next unless status && ACTIVE_STATUSES.include?(status)

    page_name = f.basename(".md").to_s.gsub("___", "/")
    last_verified = extract_date_from_prop(props["last-verified"])
    next_check = extract_date_from_prop(props["next-check"])
    page_date = extract_date_from_prop(props["date"])

    reason = nil
    days_overdue = 0

    if next_check && next_check < TODAY
      reason = "next-check overdue"
      days_overdue = (TODAY - next_check).to_i
    elsif last_verified && (TODAY - last_verified).to_i > stale_days
      reason = "last-verified stale"
      days_overdue = (TODAY - last_verified).to_i
    elsif !last_verified && !next_check && page_date && (TODAY - page_date).to_i > stale_days
      reason = "no freshness tracking"
      days_overdue = (TODAY - page_date).to_i
    end

    next unless reason

    stale << {
      page: page_name,
      status: status,
      reason: reason,
      days: days_overdue,
      last_verified: last_verified,
      next_check: next_check,
    }
  end

  stale.sort_by { |s| -s[:days] }
end

# --- 3. 고아 TODO 탐색 ---

def find_orphaned_todos(stale_days)
  todos = []
  cutoff = TODAY - stale_days

  LOGSEQ_JOURNALS.glob("*.md").each do |f|
    # 파일명: YYYY_MM_DD.md
    date_str = f.basename(".md").to_s.gsub("_", "-")
    begin
      journal_date = Date.parse(date_str)
    rescue ArgumentError
      next
    end
    next if journal_date > cutoff

    File.foreach(f, encoding: "utf-8") do |line|
      next unless line.match?(/^-\s+TODO\s/)
      todo_text = line.sub(/^-\s+TODO\s+/, "").strip
      # 프로젝트 태그 추출
      project = nil
      m = todo_text.match(/#(pj-[\w-]+)/)
      project = m[1] if m

      todos << {
        date: journal_date.to_s,
        text: todo_text[0, 80],
        project: project,
      }
    end
  rescue Errno::ENOENT, Encoding::InvalidByteSequenceError
    next
  end

  todos.sort_by { |t| t[:date] }
end

# --- 4. Standup 재료 ---

def prepare_standup(start_date, end_date)
  yesterday_sessions = scan_significant_sessions(start_date, end_date)

  # 어제 저널
  journal_path = LOGSEQ_JOURNALS / "#{end_date.strftime('%Y_%m_%d')}.md"
  yesterday_journal_dones = []
  if journal_path.exist?
    File.foreach(journal_path, encoding: "utf-8") do |line|
      if line.match?(/^-\s+DONE\s/)
        yesterday_journal_dones << line.sub(/^-\s+DONE\s+/, "").strip[0, 80]
      end
    end
  end

  # 오늘 저널 TODO
  today_journal_path = LOGSEQ_JOURNALS / "#{TODAY.strftime('%Y_%m_%d')}.md"
  today_todos = []
  if today_journal_path.exist?
    File.foreach(today_journal_path, encoding: "utf-8") do |line|
      if line.match?(/^-\s+TODO\s/)
        today_todos << line.sub(/^-\s+TODO\s+/, "").strip[0, 80]
      end
    end
  end

  {
    sessions: yesterday_sessions.map { |s| "#{s[:project] || '?'}: #{derive_slug(s[:first_msg])}" },
    dones: yesterday_journal_dones,
    todos: today_todos,
  }
end

# --- 리포트 출력 ---

def print_report(unrecorded, stale, todos, standup)
  puts "## Freshness Report -- #{TODAY}"
  puts

  # 미기록 작업
  puts "### 미기록 작업"
  if unrecorded.empty?
    puts "없음"
  else
    puts "| 세션 | 날짜 | 프로젝트 | 메시지 |"
    puts "|------|------|---------|--------|"
    unrecorded.each do |s|
      sid = s[:session_id][0, 8]
      date = format_date(s[:first_ts])
      project = s[:project] || "?"
      msg = derive_slug(s[:first_msg])[0, 50]
      puts "| #{sid} | #{date} | #{project} | #{msg} |"
    end
  end
  puts

  # Stale 문서
  puts "### Stale 문서"
  if stale.empty?
    puts "없음"
  else
    overdue = stale.select { |s| s[:reason] == "next-check overdue" }
    stale_rest = stale.reject { |s| s[:reason] == "next-check overdue" }

    unless overdue.empty?
      puts
      puts "**기한 초과 (next-check)**"
      puts "| 페이지 | next-check | 초과일 |"
      puts "|--------|-----------|-------|"
      overdue.each do |s|
        puts "| [[#{s[:page]}]] | #{s[:next_check]} | #{s[:days]}일 |"
      end
    end

    unless stale_rest.empty?
      puts
      puts "**Stale (#{STALE_THRESHOLD}일+ 미확인)**"
      puts "| 페이지 | 상태 | 사유 | 경과일 |"
      puts "|--------|------|------|-------|"
      stale_rest.each do |s|
        puts "| [[#{s[:page]}]] | #{s[:status]} | #{s[:reason]} | #{s[:days]}일 |"
      end
    end
  end
  puts

  # 고아 TODO
  puts "### 고아 TODO (#{STALE_THRESHOLD}일+)"
  if todos.empty?
    puts "없음"
  else
    puts "| 저널 | TODO | 프로젝트 |"
    puts "|------|------|---------|"
    todos.first(20).each do |t|
      puts "| #{t[:date]} | #{t[:text]} | #{t[:project] || '-'} |"
    end
    puts "(외 #{todos.size - 20}건)" if todos.size > 20
  end
  puts

  # Standup 재료
  puts "### Standup 재료"
  puts "- 어제:"
  if standup[:dones].empty? && standup[:sessions].empty?
    puts "  - (기록 없음)"
  else
    standup[:dones].first(5).each { |d| puts "  - #{d}" }
    standup[:sessions].first(5).each { |s| puts "  - [session] #{s}" }
  end
  puts "- 오늘:"
  if standup[:todos].empty?
    puts "  - (TODO 없음)"
  else
    standup[:todos].first(5).each { |t| puts "  - #{t}" }
  end
  puts
end

# --- 메인 ---

unrecorded = find_unrecorded_sessions(LOOKBACK_START, TODAY)
stale = find_stale_pages(STALE_THRESHOLD)
todos = find_orphaned_todos(STALE_THRESHOLD)

yesterday = TODAY - 1
standup = prepare_standup(yesterday, yesterday)

print_report(unrecorded, stale, todos, standup)
