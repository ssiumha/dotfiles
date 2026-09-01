#!/usr/bin/env ruby
# WebDAV <space>p key family tests

require_relative 'test_base'

class TestWebDAVKeys < TestWebDAVBase
  # tmux swallows literal spaces in a send-keys string, so name them
  def send_space_keys(*rest)
    docker_exec("tmux send-keys -t test Space #{rest.join(' ')}")
  end

  # Test <space>pp searches below the directory holding the open document
  def test_space_pp_searches_from_document_folder
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVGet /test/deep/aaa.md")
    wait_for_text("AAA Document", 2)

    send_space_keys("p", "p")
    wait_for_text("WebDAV>", 3)

    # Rooted at /test/deep/, so the match carries no 'deep/' prefix
    send_keys("nested")
    wait_for_text("subfolder/nested.txt", 5)

    output = capture
    refute_includes output, "deep/subfolder/nested.txt",
                    "Search should be rooted at the document's own folder"
  end

  # Test <space>pp in a listing uses the path being shown
  def test_space_pp_searches_from_listing_path
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVList /test/deep/")
    wait_for_text("subfolder/")

    send_space_keys("p", "p")
    wait_for_text("WebDAV>", 3)

    send_keys("nested")
    wait_for_text("subfolder/nested.txt", 5)

    output = capture
    refute_includes output, "deep/subfolder/nested.txt",
                    "Search should be rooted at the listing path"
  end

  # Test <space>p3 climbs two directories above the current one
  def test_space_p3_climbs_two_levels
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVGet /test/deep/subfolder/nested.txt")
    wait_for_text("Nested file content", 2)

    # /test/deep/subfolder/ -> /test/deep/ -> /test/
    send_space_keys("p", "3")
    wait_for_text("WebDAV>", 3)

    send_keys("nested")
    wait_for_text("deep/subfolder/nested.txt", 5)

    output = capture
    assert_includes output, "deep/subfolder/nested.txt",
                    "Two levels up should root the search at /test/"
  end

  # Test the bare <space>p fires once the prefix timeout passes
  def test_space_p_fires_after_timeout
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVGet /test/deep/aaa.md")
    wait_for_text("AAA Document", 2)

    # <space>pp and <space>p1.. extend it, so vim waits out timeoutlen first
    vim_cmd("set timeoutlen=100")
    send_space_keys("p")
    wait_for_text("WebDAV>", 3)

    output = capture
    assert_includes output, "WebDAV>", "Bare <space>p should open the picker"
  end

  # Test <space>pr reaches the vault grep instead of the local ripgrep
  def test_space_pr_greps_vault
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVGet /test/deep/aaa.md")
    wait_for_text("AAA Document", 2)

    send_space_keys("p", "r")
    wait_for_text("Search>", 10)

    output = capture
    assert_includes output, "Search>", "<space>pr should open the WebDAV grep picker"
  end

  # Test the mappings are buffer-local and do not leak to ordinary buffers
  def test_space_keys_absent_outside_webdav
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("enew")
    vim_cmd("set timeoutlen=100")

    send_space_keys("p", "p")
    sleep 1

    output = capture
    refute_includes output, "WebDAV>", "Mapping should not exist outside WebDAV buffers"
  end
end
