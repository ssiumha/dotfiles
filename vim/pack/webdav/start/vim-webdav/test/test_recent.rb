#!/usr/bin/env ruby
# WebDAV recent files functionality tests

require_relative 'test_base'
require 'securerandom'

class TestWebDAVRecent < TestWebDAVBase
  def cache_path
    @cache_path ||= "/tmp/test-recent-#{SecureRandom.hex(4)}.json"
  end

  def start_vim_with_cache(extra_env = {})
    env = {
      "WEBDAV_DEFAULT_URL" => "http://localhost:9999",
      "WEBDAV_TEST_MODE" => "1",
      "WEBDAV_RECENT_CACHE_PATH" => cache_path
    }.merge(extra_env)
    start_vim(env)
  end

  # Test WebDAVRecent command is defined
  def test_webdav_recent_command_exists
    start_vim_with_cache

    # Check if WebDAVRecent command exists
    vim_cmd("echo exists(':WebDAVRecent')")
    wait_for { capture.match?(/2/) }

    output = capture
    assert_includes output, "2", "WebDAVRecent command should be defined"
  end

  # Test empty recent files shows message
  def test_empty_recent_files
    start_vim_with_cache

    # Try WebDAVRecent with empty list (no files opened yet)
    vim_cmd("WebDAVRecent")
    wait_for_text("No recent WebDAV files", 1)

    output = capture
    assert_match(/No recent WebDAV files/, output, "Should show message when no recent files")
  end

  # Test file tracking
  def test_file_tracking
    start_vim_with_cache

    # Open existing test file
    vim_cmd("WebDAVGet /test/file1.txt")
    wait_for_text("This is test file content", 2)

    # Check recent files list
    vim_cmd("let recent = TestGetRecentFiles()")
    vim_cmd("echo len(recent)")
    wait_for { capture.match?(/1/) }

    output = capture
    assert_match(/1/, output, "Should have 1 recent file")

    # Verify file details
    vim_cmd("echo recent[0].path")
    wait_for_text("file1.txt", 1)
    assert_match(/file1\.txt/, capture, "Should track correct file path")
  end

  # Test recent files list display
  def test_recent_files_display
    start_vim_with_cache

    # Open test files
    vim_cmd("WebDAVGet /test/file1.txt")
    wait_for_text("This is test file content", 2)

    vim_cmd("tabnew")
    vim_cmd("WebDAVGet /test/001_file.txt")
    wait_for_text("Mock content", 2)

    # Open recent files list
    vim_cmd("WebDAVRecent")
    wait_for_text("Recent WebDAV Files", 2)

    output = capture
    assert_match(/Recent WebDAV Files/, output, "Should show header")
    assert_match(/file1\.txt/, output, "Should show file1.txt in list")
    assert_match(/001_file\.txt/, output, "Should show 001_file.txt in list")
  end

  # Test duplicate removal
  def test_duplicate_removal
    start_vim_with_cache

    # Open same file multiple times
    vim_cmd("WebDAVGet /test/file1.txt")
    wait_for_text("This is test file content", 2)

    vim_cmd("tabnew")
    vim_cmd("WebDAVGet /test/file1.txt")
    wait_for_text("This is test file content", 2)

    vim_cmd("tabnew")
    vim_cmd("WebDAVGet /test/file1.txt")
    wait_for_text("This is test file content", 2)

    # Check recent files list - should only have 1 entry
    vim_cmd("let recent = TestGetRecentFiles()")
    vim_cmd("echo len(recent)")
    wait_for { capture.match?(/1/) }

    output = capture
    assert_match(/1/, output, "Should have only 1 entry (duplicates removed)")
  end

  # Test opening file from recent list
  def test_open_from_recent_list
    start_vim_with_cache

    # Open file to add to recent
    vim_cmd("WebDAVGet /test/file1.txt")
    wait_for_text("This is test file content", 2)

    # Open recent list
    vim_cmd("WebDAVRecent")
    wait_for_text("Recent WebDAV Files", 2)

    # Move to first file and press Enter
    send_keys("j")  # Move down to first file
    send_keys("Enter")
    wait_for_text("This is test file content", 2)

    output = capture
    assert_match(/This is test file content/, output, "Should open file from recent list")
  end

  # Test maximum entries limit
  def test_max_entries_limit
    start_vim_with_cache

    # Open multiple files to test limit
    # Open 3 different files
    vim_cmd("WebDAVGet /test/file1.txt")
    wait_for_text("This is test file content", 2)

    vim_cmd("tabnew")
    vim_cmd("WebDAVGet /test/001_file.txt")
    wait_for_text("Mock content", 2)

    vim_cmd("tabnew")
    vim_cmd("WebDAVGet /test/한글.md")
    wait_for_text("한글 문서", 2)

    # Check we have 3 entries
    vim_cmd("let recent = TestGetRecentFiles()")
    vim_cmd("echo len(recent)")
    wait_for_text("3", 2)

    output = capture
    assert_match(/3/, output, "Should have 3 recent files")

    # Verify most recent file is first
    vim_cmd("echo recent[0].path")
    wait_for_text("한글.md", 1)
    assert_match(/한글\.md/, capture, "Should keep most recent file first")
  end

  # Test persistence - save and load
  def test_persistence
    # First session - open files
    start_vim_with_cache
    vim_cmd("WebDAVGet /test/file1.txt")
    wait_for_text("This is test file content", 2)
    vim_cmd("qa!")
    sleep 0.1

    # Second session - verify files are loaded
    start_vim_with_cache
    vim_cmd("let recent = TestGetRecentFiles()")
    vim_cmd("echo len(recent)")
    wait_for { capture.match?(/1/) }

    output = capture
    assert_match(/1/, output, "Should load 1 recent file from cache")

    vim_cmd("echo recent[0].path")
    wait_for_text("file1.txt", 1)
    assert_match(/file1\.txt/, capture, "Should load correct file path")
  end

  # Test WebDAVRecentFzf command exists
  def test_webdav_recent_fzf_command_exists
    start_vim_with_cache

    # Check if WebDAVRecentFzf command exists
    vim_cmd("echo exists(':WebDAVRecentFzf')")
    wait_for { capture.match?(/2/) }

    output = capture
    assert_includes output, "2", "WebDAVRecentFzf command should be defined"
  end

  # Test WebDAVRecentFzf with empty list
  def test_webdav_recent_fzf_empty_list
    start_vim_with_cache

    # Try WebDAVRecentFzf with empty list
    vim_cmd("WebDAVRecentFzf")
    wait_for_text("No recent WebDAV files", 1)

    output = capture
    assert_match(/No recent WebDAV files/, output, "Should show message when no recent files")
  end

  # Test fzf sink parsing with actual formatted string
  def test_recent_fzf_sink_parsing
    start_vim_with_cache

    # Open file to add to recent
    vim_cmd("WebDAVGet /test/file1.txt")
    wait_for_text("This is test file content", 2)

    # Close the tab
    vim_cmd("tabclose")
    sleep 0.1

    # Test fzf sink with actual TSV format (use actual tab character)
    selection = "[5m ago]\t/test/file1.txt\tdefault"
    vim_cmd("call TestWebDAVRecentFzfSink('#{selection}')")
    wait_for_text("This is test file content", 2)

    output = capture
    assert_match(/This is test file content/, output, "Should open file from fzf sink")
  end

  # Test fzf format generation
  def test_recent_fzf_format_generation
    start_vim_with_cache

    # Open file
    vim_cmd("WebDAVGet /test/file1.txt")
    wait_for_text("This is test file content", 2)

    # Get recent files and check format (use double quotes for tab)
    vim_cmd("let recent = TestGetRecentFiles()")
    vim_cmd('let formatted = printf(\"[test]\\t%s\\t%s\", recent[0].path, recent[0].server)')
    vim_cmd("echo formatted")
    wait_for_text("test", 1)

    output = capture
    # Should contain path
    assert_match(/file1\.txt/, output, "Should contain file path in formatted output")
  end

  # Test fzf sink with server name
  def test_recent_fzf_sink_with_server
    start_vim_with_cache

    # Open file
    vim_cmd("WebDAVGet /test/file1.txt")
    wait_for_text("This is test file content", 2)

    vim_cmd("tabclose")
    sleep 0.1

    # Test with server name in format (use actual tab character)
    selection = "[2h ago]\t/test/file1.txt\tlocal"
    vim_cmd("call TestWebDAVRecentFzfSink('#{selection}')")
    wait_for_text("This is test file content", 2)

    output = capture
    assert_match(/This is test file content/, output, "Should handle server name in selection")
  end

  # Test a file created from the listing lands in the recent list
  def test_created_file_is_tracked
    start_vim_with_cache

    vim_cmd("WebDAVList /test/")
    wait_for_text("+New", 2)

    send_keys("4G")  # +New
    send_enter
    wait_for_text("New file name", 2)
    send_keys("recent_new_note")
    send_enter
    wait_for_text("recent_new_note", 3)

    # The buffer name is on screen too, so tag the echo: matching the bare path
    # would pass on the statusline alone
    vim_cmd("let recent = TestGetRecentFiles()")
    vim_cmd('echo \"RECENTPATH=\" . get(get(recent, 0, {}), \"path\", \"NONE\")')
    wait_for_text("RECENTPATH=/test/recent_new_note.md", 3)

    assert_includes capture, "RECENTPATH=/test/recent_new_note.md",
                    "Creating a file should track it, not just opening one"
  end

  # Test a note created through WebDAVNote lands in the recent list
  def test_created_note_is_tracked
    start_vim_with_cache

    # Double quotes only: single quotes do not survive docker exec sh -c
    vim_cmd('let g:webdav_note_patterns = {\"probe\": {\"server\": \"\", \"path\": \"/test/{title}.md\", \"template\": \"\", \"unit\": \"day\", \"prompt_title\": v:null}}')
    sleep 0.3

    vim_cmd("WebDAVNote probe")
    wait_for_text("Title:", 2)
    send_keys("Storage Array")
    send_enter

    vim_cmd("echo b:webdav_original_path")
    wait_for_text("/test/Storage Array.md", 3)

    vim_cmd("let recent = TestGetRecentFiles()")
    vim_cmd('echo \"RECENTPATH=\" . get(get(recent, 0, {}), \"path\", \"NONE\")')
    wait_for_text("RECENTPATH=/test/Storage Array.md", 3)

    assert_includes capture, "RECENTPATH=/test/Storage Array.md",
                    "A note created by WebDAVNote should be tracked"
  end
end
