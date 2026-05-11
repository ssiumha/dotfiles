#!/usr/bin/env ruby
# frozen_string_literal: true

# Stop hook: 유의미한 세션 종료 시 오늘 Obsidian 저널에 완료 항목 자동 기록
#
# Usage:
#   ruby session-journal.rb <jsonl_path>
#
# 판단 기준: Edit/Write 도구 사용 + 사용자 메시지 5개 이상
# 멱등: 같은 session-id가 이미 저널에 있으면 스킵
# 위치: `# 오늘 진행` 섹션 끝(첫 sub-heading 직전)에 삽입. 섹션 없으면 생성.

require_relative "recall_common"

jsonl_path = ARGV.first
exit 0 unless jsonl_path && File.exist?(jsonl_path)

# --- 빠른 스캔: 유의미성 판단 ---

session_id = nil
cwd = nil
first_ts = nil
first_user_msg = nil
user_count = 0
has_edit = false

File.foreach(jsonl_path, encoding: "utf-8") do |line|
  line.strip!
  next if line.empty?

  obj = begin; JSON.parse(line); rescue JSON::ParserError; next; end

  session_id ||= obj["sessionId"] if obj["sessionId"]
  cwd ||= obj["cwd"] if obj["cwd"]
  first_ts ||= obj["timestamp"] if obj["timestamp"] && !obj["timestamp"].to_s.empty?

  if real_user_message?(obj)
    user_count += 1
    if first_user_msg.nil?
      text = extract_text(obj.dig("message", "content") || "")
      first_user_msg = text if text && !text.empty?
    end
  end

  # Edit/Write 도구 사용 체크
  content = obj.dig("message", "content")
  if content.is_a?(Array)
    content.each do |block|
      if block.is_a?(Hash) && block["type"] == "tool_use"
        name = block["name"]
        has_edit = true if name == "Edit" || name == "Write"
      end
    end
  end

  # 유의미성 확인되면 나머지는 user_count만 세면 됨
  break if has_edit && user_count >= 5 && first_user_msg
end

# 유의미하지 않으면 종료
exit 0 unless has_edit && user_count >= 5

# --- 저널 기록 ---

sid_short = (session_id || "unknown")[0, 8]
date_str = format_date(first_ts)
today_str = Date.today.strftime("%Y-%m-%d")
journal_path = LOGSEQ_JOURNALS / "#{today_str}.md"

project = derive_project(cwd)
project_tag = project ? "#pj-#{project}" : ""

# 요약: 첫 메시지에서 60자
summary = (first_user_msg || "session work").gsub(/\n+/, " ").strip
summary = summary[0, 60]
summary += "..." if (first_user_msg || "").length > 60

entry = "- [x] #{summary} #{project_tag}".strip

# 멱등: 이미 같은 sid가 저널에 있으면 스킵
if journal_path.exist?
  journal_content = journal_path.read(encoding: "utf-8")
  exit 0 if journal_content.include?(sid_short)
else
  # 저널 파일이 없으면 생성
  journal_path.parent.mkpath
  journal_content = ""
end

# `# 오늘 진행` 섹션 끝(첫 sub-heading 직전)에 삽입
final_entry = "#{entry} (sid:#{sid_short})"

if journal_content.empty?
  journal_path.write("# 오늘 진행\n#{final_entry}\n")
else
  lines = journal_content.split("\n", -1)
  marker_idx = lines.find_index { |l| l.match?(/\A#+\s+오늘 진행\s*\z/) }

  if marker_idx
    # 마커 직후부터 다음 헤딩(어떤 레벨이든) 직전까지가 자동 영역
    next_heading_idx = ((marker_idx + 1)...lines.length).find { |i| lines[i].match?(/\A#+\s/) }
    insert_pos = next_heading_idx || lines.length

    # 다음 헤딩 직전의 빈 줄은 헤딩과 함께 두기 위해 위로 이동
    while insert_pos > marker_idx + 1 && lines[insert_pos - 1].strip.empty?
      insert_pos -= 1
    end

    lines.insert(insert_pos, final_entry)
    journal_path.write(lines.join("\n"))
  else
    # 섹션 없음 — 끝에 새 섹션과 함께 추가
    new_content = journal_content.dup
    new_content += "\n" unless new_content.end_with?("\n")
    new_content += "\n# 오늘 진행\n#{final_entry}\n"
    journal_path.write(new_content)
  end
end
