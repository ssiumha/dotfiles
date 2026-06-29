#!/usr/bin/env ruby
# WebDAV isolation tests - prove plugin doesn't affect normal Vim operations

require_relative 'test_base'

class TestWebDAVIsolation < TestWebDAVBase
  # Test that normal file operations are completely unaffected
  def test_normal_file_operations_unaffected
    start_vim()

    # Create and edit a normal file
    vim_cmd("edit /tmp/normal-file.txt")
    vim_cmd("call append(0, 'NormalFileContent')")
    vim_cmd("call append(1, 'Line2')")

    # Save normally
    vim_cmd("write")

    # Verify buffer is not WebDAV-managed
    vim_cmd("if exists('b:webdav_managed') && b:webdav_managed | echo 'IS_WEBDAV' | else | echo 'NOT_WEBDAV' | endif")
    wait_for_text("NOT_WEBDAV")

    output = capture
    assert_includes output, "NOT_WEBDAV", "Normal file should not be WebDAV-managed"
    refute_match(/Error.*WebDAV/i, output, "Should not see any WebDAV errors")
  end

  # Test mixed buffers (WebDAV + normal files)
  def test_mixed_webdav_and_normal_buffers
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")

    # Open normal file first
    vim_cmd("edit /tmp/normal.txt")
    vim_cmd("call append(0, 'NormalFile')")
    vim_cmd("write")

    # Open WebDAV file — it opens as its OWN buffer (does not morph the normal
    # file's buffer). Verify via filetype (short, quote-free command — avoids the
    # old bare `echo exists()` which only ever matched the ruler digit by luck).
    vim_cmd("WebDAVGet /test/file1.txt")
    wait_for_text("This is test file content")
    vim_cmd("setlocal filetype?")
    wait_for_text("filetype=webdav")
    output = capture
    assert_includes output, "filetype=webdav", "WebDAV file should open as a webdav-filetype buffer"

    # Both buffers must coexist: opening the document did NOT destroy/morph the
    # normal file's buffer. :ls lists every buffer by name.
    vim_cmd("ls")
    wait_for_text("normal.txt")
    output = capture
    assert_includes output, "normal.txt", "Normal file buffer must still exist (not morphed away)"
    assert_includes output, "webdav://", "WebDAV document must have its own separate buffer"
    send_enter  # dismiss the :ls "Press ENTER" prompt

    # Switch back to the normal buffer by name; it is a plain (non-webdav)
    # buffer, confirming WebDAV state did not leak into it.
    vim_cmd("buffer /tmp/normal.txt")
    vim_cmd("setlocal filetype?")
    wait_for_text("filetype=text")
    output = capture
    refute_match(/filetype=webdav\b/, output, "Normal buffer must not be a webdav buffer")
  end

  # Test buffer switching preserves independent states
  def test_buffer_switch_preserves_state
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")

    # Open WebDAV file
    vim_cmd("WebDAVGet /test/file1.txt")
    wait_for_text("This is test file content")

    # Modify WebDAV buffer
    vim_cmd("call append(0, 'WebDAVModified')")

    # Open normal file in new buffer
    vim_cmd("edit /tmp/normal.txt")
    vim_cmd("call append(0, 'NormalContent')")

    # Check we can switch back and forth without errors
    vim_cmd("bprevious")
    vim_cmd("bnext")

    output = capture
    # Just verify no errors occurred during buffer switching
    refute_match(/Error|E\d+:/i, output, "Buffer switching should work without errors")
  end

  # Test that WebDAV doesn't interfere with user autocmds
  def test_user_autocmds_still_work
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")

    # Set up a user autocmd for normal files
    vim_cmd("let g:user_autocmd_ran = 0")
    vim_cmd("autocmd BufWritePre /tmp/*.txt let g:user_autocmd_ran = 1")

    # Test with normal file
    vim_cmd("edit /tmp/testfile.txt")
    vim_cmd("call append(0, 'TestLine')")
    vim_cmd("write")

    # Check if user autocmd ran
    vim_cmd("if g:user_autocmd_ran == 1 | echo 'USER_AUTOCMD_OK' | else | echo 'USER_AUTOCMD_FAIL' | endif")
    wait_for_text("USER_AUTOCMD_OK")

    output = capture
    assert_includes output, "USER_AUTOCMD_OK", "User autocmds should still work for normal files"
  end

  # Test WebDAV buffer cleanup on close
  def test_webdav_buffer_cleanup
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")

    # Open WebDAV file
    vim_cmd("WebDAVGet /test/file1.txt")
    wait_for_text("This is test file content")

    # Verify it's managed
    vim_cmd("if exists('b:webdav_managed') | echo 'MANAGED' | endif")
    wait_for_text("MANAGED")

    # Close the buffer
    vim_cmd("bdelete!")

    # Open a new normal buffer - should be clean
    vim_cmd("enew")

    # Verify no WebDAV variables leaked
    vim_cmd("if exists('b:webdav_managed') | echo 'LEAKED' | else | echo 'CLEAN' | endif")
    wait_for_text("CLEAN")

    output = capture
    assert_includes output, "CLEAN", "WebDAV variables should not leak to new buffers"
  end

  # Regression: opening a file from the list must NOT morph the list buffer
  # into the document. List and document are separate buffers, so the list's
  # buffer-local mappings (r/t/D) must not leak into the document buffer
  # (otherwise 'r' in a document navigates the listing instead of replacing a
  # char). See ftplugin undo_ftplugin + buffer#setup buffer switch.
  def test_document_buffer_separate_from_list
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")

    # Open list and remember its buffer number
    vim_cmd("WebDAVList /test/")
    wait_for_text("test/")
    vim_cmd("let g:list_bufnr = bufnr('%')")

    # Sanity: the list buffer DOES map 'r' (refresh)
    vim_cmd("echo empty(maparg('r','n')) ? 'LIST_NO_R' : 'LIST_HAS_R'")
    wait_for_text("LIST_HAS_R")

    # Open a markdown file from the list
    send_keys("/한글.md")
    send_enter  # execute search
    wait_for_text("한글")
    send_enter  # open file
    wait_for_text("한글")

    # Document must be a DIFFERENT buffer (no morph)
    vim_cmd("echo (bufnr('%') != g:list_bufnr) ? 'SEPARATE' : 'SAME_BUFFER'")
    wait_for_text("SEPARATE")
    output = capture
    assert_includes output, "SEPARATE", "Document must open in a separate buffer, not morph the list"

    # The leaked list mappings must be gone in the document buffer
    vim_cmd("echo empty(maparg('r','n')) ? 'DOC_NO_R' : 'DOC_HAS_R'")
    wait_for_text("DOC_NO_R")
    output = capture
    assert_includes output, "DOC_NO_R", "Document buffer must not inherit the list's 'r' mapping"

    vim_cmd("echo empty(maparg('t','n')) ? 'DOC_NO_T' : 'DOC_HAS_T'")
    wait_for_text("DOC_NO_T")
    output = capture
    assert_includes output, "DOC_NO_T", "Document buffer must not inherit the list's 't' mapping"
  end

  # Test that :wq on normal files works without WebDAV interference
  def test_normal_file_wq_works
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")

    # Create normal file
    vim_cmd("edit /tmp/wq-test.txt")
    vim_cmd("call setline(1, 'Testing wq')")

    # Use :wq (write and quit)
    vim_cmd("wq")

    # Vim should have exited back to shell
    output = capture
    # Should not see WebDAV-related errors
    refute_match(/Error.*WebDAV|Not a WebDAV buffer/i, output, "Normal file :wq should work without errors")
  end
end
