#!/usr/bin/env ruby
# frozen_string_literal: true

# 날짜 기반 Claude 세션 브라우저
#
# Usage:
#   ruby recall-day.rb list [DATE_EXPR]
#   ruby recall-day.rb expand <N> [DATE_EXPR]
#
# DATE_EXPR: today, yesterday, N days ago, last N days, this week, last week, last monday, YYYY-MM-DD

require_relative "recall_common"

# --- 세션 스캔 ---

def scan_session_metadata(filepath, start_date, end_date)
  session_id = nil
  first_ts = nil
  first_user_msg = nil
  user_count = 0
  file_size = File.size(filepath)
  found_ts = false

  File.foreach(filepath, encoding: "utf-8").with_index do |line, i|
    line.strip!
    next if line.empty?

    obj = begin; JSON.parse(line); rescue JSON::ParserError; next; end

    session_id ||= obj["sessionId"] if obj["sessionId"]

    if !found_ts && obj["timestamp"] && !obj["timestamp"].empty?
      begin
        local_date = Time.parse(obj["timestamp"]).localtime.to_date
        return nil if local_date < start_date || local_date > end_date
        first_ts = obj["timestamp"]
        found_ts = true
      rescue ArgumentError
        # skip
      end
    end

    # 50줄 이후에는 메타데이터 수집 중단, 사용자 메시지만 카운트
    next if i > 50 && !found_ts

    if real_user_message?(obj)
      user_count += 1
      text = extract_text(obj.dig("message", "content") || "")
      first_user_msg ||= text if text && !text.empty?
    end
  end

  return nil unless first_ts

  {
    session_id: session_id || File.basename(filepath, ".jsonl"),
    first_ts: first_ts,
    first_msg: first_user_msg || "(no message)",
    user_count: user_count,
    file_size: file_size,
    filepath: filepath.to_s,
  }
rescue Errno::ENOENT, Encoding::InvalidByteSequenceError
  nil
end

def has_logseq_page?(sid_short)
  return false unless SESSION_DIR.exist?

  SESSION_DIR.glob("**/*.md").each do |f|
    in_fm = false
    File.foreach(f, encoding: "utf-8") do |line|
      if line.start_with?("---")
        break if in_fm  # frontmatter 닫힘 — body 진입 전 종료
        in_fm = true
        next
      end
      next unless in_fm
      if line.start_with?("session-id:")
        val = line.split(":", 2).last.strip.delete_prefix("'").delete_suffix("'").delete_prefix('"').delete_suffix('"')
        return true if val == sid_short
      end
    end
  rescue Errno::ENOENT, Encoding::InvalidByteSequenceError
    next
  end
  false
end

def get_logseq_journal(date_obj)
  path = LOGSEQ_JOURNALS / "#{date_obj.strftime('%Y_%m_%d')}.md"
  return nil unless path.exist?

  path.read(encoding: "utf-8")
rescue Errno::ENOENT, Encoding::InvalidByteSequenceError
  nil
end

# --- 커맨드 ---

def cmd_list(date_expr)
  start_date, end_date = parse_date_expr(date_expr)

  sessions = find_all_jsonl.filter_map do |jsonl|
    scan_session_metadata(jsonl.to_s, start_date, end_date)
  end
  sessions = dedup_sessions(sessions)

  # 헤더
  if start_date == end_date
    puts "\n=== Sessions: #{start_date} (#{start_date.strftime('%A')}) ===\n\n"
  else
    puts "\n=== Sessions: #{start_date} ~ #{end_date} ===\n\n"
  end

  if sessions.empty?
    puts "  No sessions found.\n"
  else
    puts format(" %2s  %-5s  %4s  %6s  %s", "#", "Time", "Msgs", "Size", "First Message")
    puts format(" %2s  %-5s  %4s  %6s  %s", "--", "-----", "----", "------", "-------------")

    sessions.each_with_index do |s, i|
      time_str = format_time(s[:first_ts])
      msg_preview = s[:first_msg][0, 60]
      msg_preview += "..." if s[:first_msg].length > 60
      sid_short = s[:session_id][0, 8]
      marker = has_logseq_page?(sid_short) ? " [vault]" : ""
      puts format(" %2d  %-5s  %4d  %6s  %s%s", i + 1, time_str, s[:user_count], format_size(s[:file_size]), msg_preview, marker)
    end

    puts "\nSession IDs:"
    sessions.each_with_index do |s, i|
      puts "  #{i + 1}. #{s[:session_id][0, 8]}"
    end
  end

  # Logseq 저널
  current = start_date
  while current <= end_date
    journal = get_logseq_journal(current)
    if journal
      puts "\n=== Journal #{current} ==="
      lines = journal.split("\n")
      if lines.size > 50
        puts lines[0, 50].join("\n")
        puts "  ... (#{lines.size - 50} more lines)"
      else
        puts journal
      end
    end
    current += 1
  end

  puts
end

def cmd_expand(session_num, date_expr)
  start_date, end_date = parse_date_expr(date_expr)

  sessions = find_all_jsonl.filter_map do |jsonl|
    scan_session_metadata(jsonl.to_s, start_date, end_date)
  end
  sessions = dedup_sessions(sessions)

  if session_num < 1 || session_num > sessions.size
    warn "Error: session ##{session_num} not found (have #{sessions.size} sessions)"
    exit 1
  end

  target = sessions[session_num - 1]
  puts "\n=== Session ##{session_num}: #{target[:session_id][0, 8]} ===\n\n"

  max_msgs = 30
  count = 0
  File.foreach(target[:filepath], encoding: "utf-8") do |line|
    line.strip!
    next if line.empty?

    obj = begin; JSON.parse(line); rescue JSON::ParserError; next; end
    msg_type = obj["type"]
    next unless %w[user assistant].include?(msg_type)

    ts = format_time(obj["timestamp"] || "")
    content = obj.dig("message", "content") || ""

    if msg_type == "user" && !obj["toolUseResult"]
      text = extract_text(content)
      if text && text.length >= 5
        puts "[#{ts}] USER: #{text[0, 200]}"
        count += 1
      end
    elsif msg_type == "assistant"
      text = extract_text(content)
      puts "[#{ts}] ASST: #{text[0, 150]}" if text && !text.empty?
      tools = extract_tool_names(content)
      puts "       TOOL: #{tools[0, 5].join(', ')}" if tools.any?
      count += 1
    end

    if count >= max_msgs
      puts "\n  ... truncated at #{max_msgs} messages"
      break
    end
  end

  puts
end

# --- 메인 ---

cmd = ARGV.shift

case cmd
when "list"
  cmd_list(ARGV.join(" ").then { |e| e.empty? ? "today" : e })
when "expand"
  num = (ARGV.shift || "0").to_i
  cmd_expand(num, ARGV.join(" ").then { |e| e.empty? ? "today" : e })
else
  warn "Usage: recall-day.rb list [DATE_EXPR]"
  warn "       recall-day.rb expand <N> [DATE_EXPR]"
  exit 1
end
