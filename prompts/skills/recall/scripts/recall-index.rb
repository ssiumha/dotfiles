#!/usr/bin/env ruby
# frozen_string_literal: true

# 미추출 세션 배치 인덱싱
#
# Usage:
#   ruby recall-index.rb [--days N] [--force] [--dry-run]
#
# 미추출 세션을 Obsidian 페이지로 변환하고 ir update + ir embed 실행.

require_relative "recall_common"

# --- ARGV 파싱 ---

dry_run = !!ARGV.delete("--dry-run")
force   = !!ARGV.delete("--force")

days = nil
if (idx = ARGV.index("--days"))
  days = ARGV[idx + 1].to_i
  ARGV.slice!(idx, 2)
end

# --- 기존 session-id 수집 (dedup용) ---

existing_ids = Set.new
if LOGSEQ_PAGES.exist?
  LOGSEQ_PAGES.glob("session___*.md").each do |f|
    File.foreach(f, encoding: "utf-8") do |line|
      if line.start_with?("session-id::")
        existing_ids << line.split("::", 2).last.strip
      end
      break if line.start_with?("- ")
    end
  rescue Errno::ENOENT, Encoding::InvalidByteSequenceError
    next
  end
end

# --- JSONL 파일 수집 ---

jsonl_files = find_all_jsonl.sort_by(&:to_s)

# --days 필터
if days
  cutoff = Time.now - (days * 86400)
  jsonl_files.select! { |f| File.mtime(f) >= cutoff }
end

# --- 추출 ---

extract_script = Pathname.new(__dir__).join("extract-session.rb").to_s
total = 0
extracted = 0
skipped = 0

puts "=== Recall Index: scanning sessions ==="

jsonl_files.each do |jsonl|
  total += 1

  # 세션 ID 빠르게 추출 (첫 몇 줄만)
  sid = nil
  File.foreach(jsonl, encoding: "utf-8").with_index do |line, i|
    break if i > 10
    line.strip!
    next if line.empty?
    obj = begin; JSON.parse(line); rescue JSON::ParserError; next; end
    if obj["sessionId"] && !obj["sessionId"].empty?
      sid = obj["sessionId"][0, 8]
      break
    end
  end

  next unless sid

  # 이미 추출된 세션 스킵
  if !force && existing_ids.include?(sid)
    skipped += 1
    next
  end

  if dry_run
    puts "  [dry-run] Would extract: #{sid} (#{jsonl})"
    extracted += 1
  else
    puts "  Extracting: #{sid}"
    if system("ruby", extract_script, jsonl.to_s, "--min-msgs", "3")
      extracted += 1
    else
      warn "  Failed: #{sid}"
    end
  end
end

puts ""
puts "=== Done: extracted=#{extracted}, skipped=#{skipped} ==="

# ir 인덱스 갱신
unless dry_run
  if system("which ir > /dev/null 2>&1")
    puts ""
    puts "=== Updating ir index ==="
    system("ir update")
    system("ir embed")
    puts "=== ir index updated ==="
  end
end
