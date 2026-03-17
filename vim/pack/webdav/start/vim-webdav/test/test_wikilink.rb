#!/usr/bin/env ruby
# Tests for Obsidian-style wikilink support

require_relative 'test_base'

class TestWikilink < TestWebDAVBase
  # Test: Open relative path wikilink
  def test_open_relative_path
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")

    # Open a file with relative link
    vim_cmd("WebDAVGet /vault/notes/daily/2024-01-01.md")
    wait_for_text("Daily Note 2024-01-01", 2)

    # Move cursor to line 5 (relative link), inside [[]]
    # File content line 5: "- Relative parent: [[../index.md]]"
    vim_cmd("call cursor(5, 24)")
    sleep 0.2

    # Use command to follow link
    vim_cmd("WebDAVFollowLink")
    wait_for_text("Notes Index", 3)

    # Verify correct file opened
    vim_cmd("echo b:webdav_original_path")
    sleep 0.2
    output = capture
    assert_includes output, "/vault/notes/index.md", "Should open relative wikilink"
  end

  # Test: Open filename-only wikilink (adds .md)
  def test_open_filename_only
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")

    # Open vault index
    vim_cmd("WebDAVGet /vault/index.md")
    wait_for_text("Vault Index", 2)

    # Move cursor to line 5 [[projects/todo.md]] link
    # File content line 5: "- [[projects/todo.md]]"
    vim_cmd("call cursor(5, 6)")
    sleep 0.2

    # Use command to follow link
    vim_cmd("WebDAVFollowLink")
    wait_for_text("TODO List", 3)

    # Verify correct file opened
    vim_cmd("echo b:webdav_original_path")
    sleep 0.2
    output = capture
    assert_includes output, "/vault/projects/todo.md", "Should open filename wikilink"
  end

  # Test: Open parent directory wikilink (../)
  def test_open_parent_dir_link
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")

    # Start from notes index
    vim_cmd("WebDAVGet /vault/notes/index.md")
    wait_for_text("Notes Index", 2)

    # Follow parent dir link (../index.md) - line 3
    vim_cmd("call cursor(3, 6)")
    sleep 0.2
    vim_cmd("WebDAVFollowLink")
    wait_for_text("Vault Index", 3)
    vim_cmd("echo b:webdav_original_path")
    sleep 0.2
    output = capture
    assert_includes output, "/vault/index.md", "Should open parent dir wikilink"
  end

  # Test: Open absolute path wikilink ([[/path/to/file]])
  def test_open_absolute_path_link
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999", "WEBDAV_TEST_MODE" => "1")

    # Set vault_root for absolute path resolution
    vim_cmd("let g:webdav_vault_roots = {'default': '/vault'}")

    # First: Open notes index
    vim_cmd("WebDAVGet /vault/notes/index.md")
    wait_for_text("Notes Index", 2)

    # Navigate to parent (to get to vault root level)
    vim_cmd("call cursor(3, 6)")  # [[../index.md]]
    sleep 0.2
    vim_cmd("WebDAVFollowLink")
    wait_for_text("Vault Index", 3)

    # Now test absolute path: from /vault/index.md, follow [[/notes/index.md]]
    # Line 4: "- [[/notes/index.md]]"
    vim_cmd("call cursor(4, 6)")
    sleep 0.2

    vim_cmd("WebDAVFollowLink")
    wait_for_text("Notes Index", 3)

    # Verify correct file opened via absolute path
    vim_cmd("echo b:webdav_original_path")
    sleep 0.2
    output = capture
    assert_includes output, "/notes/index.md", "Should open absolute path wikilink"
  end


  # Test: No wikilink under cursor message
  def test_no_wikilink_message
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")

    # Open a file
    vim_cmd("WebDAVGet /vault/projects/todo.md")
    wait_for_text("TODO List", 2)

    # Move to header line (no wikilink)
    vim_cmd("call cursor(1, 1)")
    sleep 0.1

    # Try to follow link
    vim_cmd("WebDAVFollowLink")
    sleep 0.3
    output = capture
    assert_includes output, "No wikilink under cursor", "Should show message when no wikilink"
  end

  # Test: vault_root resolve — absolute path uses vault root
  def test_vault_root_resolve
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999", "WEBDAV_TEST_MODE" => "1")

    # Set vault_root
    vim_cmd("call TestSetVaultRoot('default', '/vault')")
    sleep 0.1

    # Verify vault_root is set
    vim_cmd("echo TestWikilinkGetVaultRoot('')")
    sleep 0.2
    output = capture
    assert_includes output, "/vault", "Should return configured vault root"

    # Test absolute path resolution
    vim_cmd("echo TestWikilinkResolve('/notes/index.md', '/vault/projects/todo.md', '/vault')")
    sleep 0.2
    output = capture
    assert_includes output, "/vault/notes/index.md", "Absolute path should resolve relative to vault root"

    # Test relative path resolution
    vim_cmd("echo TestWikilinkResolve('../index.md', '/vault/notes/daily/note.md', '/vault')")
    sleep 0.2
    output = capture
    assert_includes output, "/vault/notes/index.md", "Relative path should resolve from current dir"
  end

  # Test: Wikilink extraction with heading anchor
  def test_extract_with_heading
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999", "WEBDAV_TEST_MODE" => "1")

    # Create buffer with heading anchor link
    vim_cmd("enew")
    vim_cmd("let b:webdav_managed = 1")
    vim_cmd("let b:webdav_original_path = '/test.md'")
    vim_cmd("let b:webdav_server = ''")
    vim_cmd("call setline(1, '[[target#section]]')")
    vim_cmd("call cursor(1, 5)")
    sleep 0.1

    # Check extraction - should strip the #section part
    vim_cmd("let result = TestWikilinkExtract()")
    sleep 0.1
    vim_cmd("echo result.target")
    sleep 0.2
    output = capture
    assert_includes output, "target", "Should extract target without heading anchor"
  end
end
