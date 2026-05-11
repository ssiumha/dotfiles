#!/usr/bin/env ruby
# frozen_string_literal: true

# Session sync hook: auto-extract current session to Logseq.
# Fires on UserPromptSubmit, Stop, and SessionEnd.
# stdin: JSON { session_id, transcript_path, cwd, hook_event_name, ... }

require "json"
require "pathname"

begin
  input = JSON.parse($stdin.read)
rescue JSON::ParserError
  exit 0
end

transcript = input["transcript_path"]
exit 0 if transcript.nil? || transcript.empty? || !File.exist?(transcript)

status = input["hook_event_name"] == "SessionEnd" ? "archived" : "active"

extract = Pathname.new(__dir__).join("extract-session.rb").to_s
system("ruby", extract, transcript, "--min-msgs", "3", "--status", status,
       [:out, :err] => File::NULL)

# Stop/SessionEnd 시 유의미한 세션이면 오늘 저널에 DONE 기록
if %w[Stop SessionEnd].include?(input["hook_event_name"])
  journal = Pathname.new(__dir__).join("session-journal.rb").to_s
  system("ruby", journal, transcript, [:out, :err] => File::NULL)
end

if system("which ir > /dev/null 2>&1")
  system("ir", "update", [:out, :err] => File::NULL)
end
