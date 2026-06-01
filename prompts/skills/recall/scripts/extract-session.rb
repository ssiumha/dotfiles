#!/usr/bin/env ruby
# frozen_string_literal: true

# JSONL 세션 → Obsidian session/ 페이지 변환 (idempotent)
#
# Usage:
#   ruby extract-session.rb <jsonl_path> [--dry-run] [--min-msgs N] [--outdir DIR] [--status STATUS]
#
# Output:
#   ~/Documents/obsidian/.session/YYYY-MM/YYYY-MM-DD/YYYY-MM-DD {slug} {sid}.md

require_relative "recall_common"

MAX_USER_PREVIEW      = 150
MAX_ASSISTANT_PREVIEW  = 100
MAX_TURNS             = 50
MAX_SUMMARY           = 200

SYSTEM_PROPERTIES = Set["project", "date", "status", "session-id", "messages", "exclude-from-graph-view"]
SYSTEM_SECTIONS   = Set["Summary", "Conversation", "Files"]

# Conversation 표시에서 생략할 노이즈 도구
SKIP_TOOLS = Set[
  "TaskCreate", "TaskUpdate", "TaskGet", "TaskList", "TaskOutput", "TaskStop",
  "AskUserQuestion", "ToolSearch", "ScheduleWakeup",
  "EnterPlanMode", "ExitPlanMode", "EnterWorktree", "ExitWorktree",
  "NotebookEdit", "Monitor", "SendMessage",
  "CronCreate", "CronDelete", "CronList",
  "ListMcpResourcesTool", "ReadMcpResourceTool",
]

# --- ARGV 파싱 ---

dry_run = !!ARGV.delete("--dry-run")

min_msgs = 3
if (idx = ARGV.index("--min-msgs"))
  min_msgs = ARGV[idx + 1].to_i
  ARGV.slice!(idx, 2)
end

outdir = nil
if (idx = ARGV.index("--outdir"))
  outdir = Pathname.new(ARGV[idx + 1])
  ARGV.slice!(idx, 2)
end

status = "archived"
if (idx = ARGV.index("--status"))
  status = ARGV[idx + 1]
  ARGV.slice!(idx, 2)
end

jsonl_path = ARGV.first
unless jsonl_path
  warn "Usage: extract-session.rb <jsonl_path> [--dry-run] [--min-msgs N] [--outdir DIR] [--status STATUS]"
  exit 1
end

jsonl_path = Pathname.new(jsonl_path).expand_path
unless jsonl_path.exist?
  warn "Error: #{jsonl_path} not found"
  exit 1
end

outdir ||= SESSION_DIR

# --- 핵심 함수 ---

def parse_jsonl(path)
  messages = []
  File.foreach(path, encoding: "utf-8") do |line|
    line.strip!
    next if line.empty?

    obj = begin; JSON.parse(line); rescue JSON::ParserError; next; end
    messages << obj if %w[user assistant].include?(obj["type"])
  end
  return nil if messages.empty?

  first = messages.first
  real_user = messages.select { |m| real_user_message?(m) }
  assistants = messages.select { |m| m["type"] == "assistant" }
  timestamps = messages.filter_map { |m| m["timestamp"] }

  {
    session_id: first["sessionId"] || "",
    cwd: first["cwd"] || "",
    all_messages: messages,
    real_user_msgs: real_user,
    user_count: real_user.size,
    assistant_count: assistants.size,
    first_ts: timestamps.first || "",
    last_ts: timestamps.last || "",
  }
end

def build_conversation(messages)
  turns = []
  i = 0
  while i < messages.size && turns.size < MAX_TURNS
    msg = messages[i]
    if msg["type"] == "user" && !msg["toolUseResult"]
      text = extract_text(msg.dig("message", "content") || "")
      if text && !text.empty?
        time_str = format_time(msg["timestamp"])
        user_preview = text.gsub(/\n+/, " ").strip
        user_preview = user_preview.length > MAX_USER_PREVIEW ? "#{user_preview[0, MAX_USER_PREVIEW]}..." : user_preview

        asst_text = ""
        asst_tools = []
        j = i + 1
        while j < messages.size && messages[j]["type"] == "assistant"
          a_content = messages[j].dig("message", "content") || []
          t = extract_text(a_content)
          asst_text = t if !t.empty? && asst_text.empty?
          asst_tools.concat(extract_tool_names(a_content))
          j += 1
        end
        asst_tools.uniq!
        asst_preview = asst_text.gsub(/\n+/, " ").strip
        asst_preview = asst_preview.length > MAX_ASSISTANT_PREVIEW ? "#{asst_preview[0, MAX_ASSISTANT_PREVIEW]}..." : asst_preview

        turns << { time: time_str, user: user_preview, assistant: asst_preview, tools: asst_tools }
        i = j
        next
      end
    end
    i += 1
  end
  turns
end

def collect_files(messages)
  seen = Set.new
  files = []
  home = Dir.home
  messages.each do |msg|
    content = msg.dig("message", "content")
    next unless content.is_a?(Array)

    content.each do |block|
      next unless block.is_a?(Hash) && block["type"] == "tool_use"

      inp = block["input"] || {}
      path = inp["file_path"] || inp["path"] || ""
      next if path.empty?

      path = "~#{path[home.length..]}" if path.start_with?(home)
      unless seen.include?(path)
        seen << path
        files << path
      end
    end
  end
  files
end

def collect_tool_stats(messages)
  counts = Hash.new(0)
  messages.each do |msg|
    content = msg.dig("message", "content")
    next unless content.is_a?(Array)

    content.each do |block|
      next unless block.is_a?(Hash) && block["type"] == "tool_use"
      counts[block["name"]] += 1 unless SKIP_TOOLS.include?(block["name"])
    end
  end
  counts.sort_by { |_, v| -v }.to_h
end

def last_assistant_text(messages)
  messages.reverse_each do |msg|
    next unless msg["type"] == "assistant"
    text = extract_text(msg.dig("message", "content") || "")
    next if text.nil? || text.length < 10
    text = text.gsub(/\n+/, " ").strip
    return text.length > 200 ? "#{text[0, 200]}..." : text
  end
  nil
end

def parse_existing_page(path)
  content = path.read(encoding: "utf-8")
  lines = content.split("\n")

  properties = {}
  user_properties = {}
  body_start = 0

  lines.each_with_index do |line, idx|
    if line.strip.empty?
      body_start = idx + 1
      break
    end
    if (m = line.match(/^(\S+?)::\s*(.*)/))
      key, val = m[1], m[2].strip
      properties[key] = val
      user_properties[key] = line unless SYSTEM_PROPERTIES.include?(key)
      body_start = idx + 1
    else
      body_start = idx
      break
    end
  end

  # H1 헤더를 표준 markdown(`# X`)·outliner(`- # X`) 양쪽 모두 인식.
  # system H1(Summary/Conversation/Files) 영역 내 라인은 모두 버린다.
  # user 영역은 그대로 보존한다.
  user_sections = []
  current_block = []
  in_system = false

  flush = lambda do
    while !current_block.empty? && current_block.first.strip.empty?
      current_block.shift
    end
    while !current_block.empty? && current_block.last.strip.empty?
      current_block.pop
    end
    user_sections << current_block unless current_block.empty?
    current_block = []
  end

  (lines[body_start..] || []).each do |line|
    m = line.match(/^# (.+?)\s*$/) || line.match(/^- # (.+?)\s*$/)
    if m
      title = m[1].strip
      flush.call unless in_system
      current_block = []
      if SYSTEM_SECTIONS.include?(title)
        in_system = true
      else
        in_system = false
        current_block = [line]
      end
    else
      next if in_system
      current_block << line
    end
  end
  flush.call unless in_system

  [properties, user_properties, user_sections]
end

def find_existing_page(sid_short, outdir)
  return nil unless outdir.exist?

  Dir.glob("#{outdir}/**/*.md").each do |f|
    f = Pathname.new(f)
    in_fm = false
    File.foreach(f, encoding: "utf-8") do |line|
      if line.chomp == "---"
        if in_fm
          break
        else
          in_fm = true
          next
        end
      end
      if in_fm && line =~ /^session-id:\s*['"]?([^'"\s]+)['"]?/
        return f if Regexp.last_match(1).strip == sid_short
      end
      break if !in_fm && line.start_with?("- ")
    end
  rescue Errno::ENOENT, Encoding::InvalidByteSequenceError
    next
  end
  nil
end

def strip_links(text)
  return "" if text.nil?
  s = text.to_s
  s = s.gsub(/!\[\[[^\]]+\]\]/, "")
  s = s.gsub(/\[\[([^\]|]+)\|([^\]]+)\]\]/, '\\2')
  s = s.gsub(/\[\[([^\]]+)\]\]/, '\\1')
  s
end

def generate_page(session, status, existing_path)
  date_str = format_date(session[:first_ts])
  project = derive_project(session[:cwd])
  sid_short = session[:session_id][0, 8]
  sid_short = "unknown" if sid_short.empty?

  user_properties = {}
  user_sections = []
  if existing_path
    props, user_properties, user_sections = parse_existing_page(existing_path)
    status = "archived" if props["status"] == "archived"
  end

  first_text = ""
  if session[:real_user_msgs].any?
    first_text = extract_text(session[:real_user_msgs].first.dig("message", "content") || "")
  end
  summary = strip_links(first_text).gsub(/\n+/, " ").strip
  summary = summary.length > MAX_SUMMARY ? "#{summary[0, MAX_SUMMARY]}..." : summary

  start_time = format_time(session[:first_ts])
  end_time   = format_time(session[:last_ts])
  dur = duration_minutes(session[:first_ts], session[:last_ts])

  turns = build_conversation(session[:all_messages])
  files = collect_files(session[:all_messages])
  tool_stats = collect_tool_stats(session[:all_messages])
  completed = strip_links(last_assistant_text(session[:all_messages]) || "")
  completed = nil if completed.empty?

  lines = []
  lines << "---"
  lines << "project: session-#{project}" if project
  lines << "date: '#{date_str}'"
  lines << "status: #{status}"
  lines << "session-id: #{sid_short}"
  lines << "messages: '#{session[:user_count]}'"
  lines << "exclude-from-graph-view: 'true'"
  user_properties.each_value { |raw| lines << raw }
  lines << "---"
  lines << ""

  # Standard markdown — no outliner, no wikilink
  lines << "# Summary"
  lines << ""
  lines << "- Request: #{summary}"
  lines << "- Duration: #{start_time} - #{end_time} (#{dur}min)"
  lines << "- Messages: #{session[:user_count]} user, #{session[:assistant_count]} assistant"
  if tool_stats.any?
    top_tools = tool_stats.first(6).map { |k, v| "#{k}(#{v})" }.join(", ")
    lines << "- Investigated: #{top_tools}"
  end
  lines << "- Completed: #{completed}" if completed
  lines << "- Files: #{files.size} touched" if files.any?

  if turns.any?
    lines << ""
    lines << "# Conversation"
    lines << ""
    lines << "```"
    turns.each do |turn|
      u = strip_links(turn[:user])
      a = strip_links(turn[:assistant])
      lines << "[#{turn[:time]}] U: #{u}"
      lines << "[#{turn[:time]}] A: #{a}" unless a.empty?
      visible_tools = turn[:tools].reject { |t| SKIP_TOOLS.include?(t) }
      lines << "[#{turn[:time]}]    tools: #{visible_tools[0, 5].join(", ")}" if visible_tools.any?
    end
    lines << "```"
  end

  if files.any?
    lines << ""
    lines << "# Files"
    lines << ""
    files[0, 30].each { |fp| lines << "- `#{fp}`" }
  end

  unless user_sections.empty?
    lines << ""
    user_sections.each do |section_lines|
      section_lines.each { |line| lines << line }
    end
  end

  lines.join("\n") + "\n"
end

def session_target_dir(outdir, first_ts)
  d = format_date(first_ts)
  y, m, day = d.split("-")
  outdir / "#{y}-#{m}" / "#{y}-#{m}-#{day}"
end

def output_filename(session)
  date_str = format_date(session[:first_ts])
  sid_short = session[:session_id][0, 8]
  sid_short = "unknown" if sid_short.empty?
  first_text = ""
  if session[:real_user_msgs].any?
    first_text = extract_text(session[:real_user_msgs].first.dig("message", "content") || "")
  end
  slug = derive_slug(first_text)
  "#{date_str} #{slug} #{sid_short}.md"
end

# --- 메인 ---

session = parse_jsonl(jsonl_path.to_s)
unless session
  warn "Error: no messages found in JSONL"
  exit 1
end

if session[:user_count] < min_msgs
  warn "Skip: only #{session[:user_count]} user messages (min: #{min_msgs})"
  exit 0
end

sid_short = session[:session_id][0, 8]
sid_short = "unknown" if sid_short.empty?

existing_path = find_existing_page(sid_short, outdir)

page_content = generate_page(session, status, existing_path)

if dry_run
  puts page_content
  if existing_path
    warn "--- Would update: #{existing_path} ---"
  else
    warn "--- Would write to: #{outdir / output_filename(session)} ---"
  end
else
  if existing_path
    existing_path.write(page_content, encoding: "utf-8")
    puts "Updated: #{existing_path}"
  else
    target_dir = session_target_dir(outdir, session[:first_ts])
    target_dir.mkpath
    out_path = target_dir / output_filename(session)
    out_path.write(page_content, encoding: "utf-8")
    puts "Created: #{out_path}"
  end
end
