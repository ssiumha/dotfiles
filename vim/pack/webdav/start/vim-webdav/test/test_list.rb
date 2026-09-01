#!/usr/bin/env ruby
# WebDAV list and navigation tests

require_relative 'test_base'

class TestWebDAVList < TestWebDAVBase
  # Test WebDAVList shows files
  def test_webdav_list_shows_files
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVList /test/")

    # Check sorted order: ../ first, then directories, then files
    assert_screen_includes <<~SCREEN
      " WebDAV: http://localhost:9999/test/
      ../
      aaa_folder/
      folder1/
      zzz_folder/
      001_file.txt
      file1.txt
      한글.md
    SCREEN
  end

  # Test Enter key mapping works
  def test_enter_key_opens_file
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVList /test/")

    # Move to file1.txt line and press Enter
    send_keys("/file1.txt")  # Search for file1.txt
    send_enter  # Execute search
    wait_for_text("file1.txt", 1)
    send_enter  # Open file
    wait_for { capture.include?("This is test file content") }

    # Check if file opened
    output = capture
    assert_includes output, "This is test file content", "Enter should open the file"
  end

  # Test buffer is not modifiable
  def test_buffer_not_modifiable
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVList /test/")
    wait_for_text("WebDAV:")

    # Try to enter insert mode (should fail due to nomodifiable)
    send_keys("i")
    sleep 0.2  # Wait for error message

    # Check v:errmsg for the error
    vim_cmd("echo v:errmsg")
    output = capture
    assert_match(/modifiable.is.off|Cannot make changes/i, output)
  end

  # Test error without URL
  def test_error_without_url
    start_vim()  # Start without env var
    vim_cmd("WebDAVList /")

    output = capture
    assert_includes output, "Error: Set WEBDAV_DEFAULT_URL"
  end

  # Test with pattern matching (using ... for any content)
  def test_webdav_list_pattern
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVList /test/")

    # Use pattern with ... to skip lines (../ is now at top)
    assert_screen_pattern <<~PATTERN
      " WebDAV: http://localhost:9999/test/
      ../
      ...
      한글.md
    PATTERN
  end

  # Test using specific helper methods
  def test_webdav_list_with_helpers
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVList /test/")

    assert_header '" WebDAV: http://localhost:9999/test/'
    assert_files_listed '../', 'aaa_folder/', 'folder1/', 'zzz_folder/', '001_file.txt', 'file1.txt', '한글.md'
  end

  # Test with base URL having a deep path
  def test_webdav_list_with_deep_base_url
    # Base URL이 deep path를 포함하는 경우
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999/test/deep")
    vim_cmd("WebDAVList /")  # Root of the deep path

    assert_header '" WebDAV: http://localhost:9999/test/deep/'
    assert_files_listed '../', 'anotherfolder/', 'subfolder/', 'aaa.md', 'file.txt', 'zzz.txt'
  end

  # Test navigating from deep base URL
  def test_webdav_navigation_with_deep_base_url
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999/test/deep")
    vim_cmd("WebDAVList /subfolder/")

    assert_screen_includes <<~SCREEN
      " WebDAV: http://localhost:9999/test/deep/subfolder/
      ../
      nested.txt
    SCREEN
  end

  # Test that folders appear before files in sorted order
  def test_sorted_listing_folders_first
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVList /test/")

    output = capture
    # Get content lines excluding vim chrome
    lines = output.split("\n").take_while { |l| !l.start_with?("~") }.select { |l| !l.empty? }

    # Extract the file list (skip header, ../, action items, and any status lines)
    files_and_dirs = lines[2..-1].reject { |l| l == "../" || l.start_with?("+") || l.include?("All") || l.include?("more lines") }

    # Check that all directories come before all files
    dir_indices = files_and_dirs.each_index.select { |i| files_and_dirs[i].end_with?("/") }
    file_indices = files_and_dirs.each_index.reject { |i| files_and_dirs[i].end_with?("/") }

    unless dir_indices.empty? || file_indices.empty?
      assert dir_indices.max < file_indices.min,
             "Directories should appear before files. Got: #{files_and_dirs.inspect}"
    end

    # Also check alphabetical order within each group
    dirs = files_and_dirs.select { |f| f.end_with?("/") }
    files = files_and_dirs.reject { |f| f.end_with?("/") }

    assert_equal dirs.sort, dirs, "Directories should be alphabetically sorted"
    assert_equal files.sort, files, "Files should be alphabetically sorted"
  end

  # Test hint line renders the folder-view key bindings
  def test_hint_line_shown
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVList /test/")
    wait_for_text("WebDAV:")

    # Header stays on line 1 so path assertions elsewhere keep working
    assert_header '" WebDAV: http://localhost:9999/test/'

    output = capture
    assert_includes output, '" ␣␣:menu ↵:open t:tab -:up r:reload F:find R:rename D:delete',
                    "Hint line should list the folder-view key bindings"
  end

  # Test line-item shortcuts stay inert while the cursor sits on the hint line
  def test_shortcuts_inert_on_hint_line
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVList /test/")
    wait_for_text("WebDAV:")

    send_keys("2G")  # line 2 = hint line

    send_keys("D")
    wait_for_text("Cannot delete special items")

    send_keys("R")
    wait_for_text("Cannot rename special items")

    send_enter  # <CR> on the hint line
    sleep 0.3

    output = capture
    assert_includes output, '" WebDAV: http://localhost:9999/test/',
                    "Enter on the hint line should keep the listing open"
  end
end
