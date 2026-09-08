#!/usr/bin/env ruby
# vim-webdav-search: client behaviour against a mock of the index API

require_relative 'test_base'

class TestWebDAVSearch < TestWebDAVSearchBase
  # Tag the echo so an assertion cannot pass on the statusline or a fixture
  # line that happens to hold the same text
  def marker(expr)
    vim_cmd("echo \\\"MARK=\\\" . #{expr}")
    sleep 0.4
  end

  # Test the mock answers the contract, separating a client bug from a fixture one
  def test_mock_serves_the_contract
    body = api('/api/vault/search?q=Ceph')

    assert_equal 2, body['results'].size, 'one hit under test/deep, one outside'
    assert_equal 'test/deep/aaa.md', body['results'][0]['path']
    assert_equal 2, body['results'][0]['line']
    assert_equal '2026-08-31T12:00:00Z', body['index']['indexed_at']
  end

  # Test the picker opens on titles: names, aliases and headings, not bodies
  def test_live_search_starts_in_title_mode
    start_vim(search_env)
    vim_cmd("WebDAVSearch")
    wait_for_text("Title(all)>", 3)  # a plain buffer has no folder to scope to

    send_keys("notes")
    wait_for_text("Ceph notes", 5)

    output = capture
    refute_includes output, "Ceph is a distributed",
                    "Title mode should not reach into note bodies"
  end

  # Test tab moves between the two, carrying the query
  def test_tab_toggles_between_title_and_content
    start_vim(search_env)
    vim_cmd("WebDAVSearch")
    wait_for_text("Title(all)>", 3)

    send_keys("Ceph")
    wait_for_text("Ceph notes", 5)

    docker_exec("tmux send-keys -t test Tab")
    wait_for_text("Content(all)>", 5)
    wait_for_text("Ceph is a distributed", 5)  # wraps at 80 cols

    output = capture
    assert_includes output, "test/deep/aaa.md:2:",
                    "Content mode should report the matching body line"

    docker_exec("tmux send-keys -t test Tab")
    wait_for_text("Title(all)>", 5)
  end

  # Test a query argument answers once into quickfix, jumpable through webdav://
  def test_search_with_query_fills_quickfix
    start_vim(search_env)
    vim_cmd("WebDAVSearch distributed")
    wait_for_text("Ceph is a distributed", 5)  # wraps at 80 cols

    marker("bufname(getqflist()[0].bufnr)")
    wait_for_text("MARK=webdav://http://localhost:9999/test/deep/aaa.md", 3)

    assert_includes capture, "MARK=webdav://http://localhost:9999/test/deep/aaa.md",
                    "quickfix should point at a WebDAV buffer, not a local path"

    marker("getqflist()[0].lnum")
    wait_for_text("MARK=2", 3)
    assert_includes capture, "MARK=2", "quickfix should carry the matching line"
  end

  # Test quickfix jumps actually open the note on the server
  def test_quickfix_jump_opens_the_note
    start_vim(search_env)
    vim_cmd("WebDAVSearch Ceph")
    wait_for_text("Ceph is a distributed", 5)  # wraps at 80 cols

    vim_cmd("cfirst")
    wait_for_text("AAA Document", 5)

    marker("get(b:, \\\"webdav_original_path\\\", \\\"NONE\\\")")
    wait_for_text("MARK=/test/deep/aaa.md", 3)

    assert_includes capture, "MARK=/test/deep/aaa.md",
                    "Jumping should open the note over WebDAV"
  end

  # Test backlinks find an alias link, the form the regex in vim-webdav misses
  def test_backlinks_finds_alias_link
    start_vim(search_env)
    vim_cmd("WebDAVGet /test/file1.txt")
    wait_for_text("This is test file content", 3)

    vim_cmd("WebDAVSearchBacklinks")
    wait_for_text("별칭", 5)

    output = capture
    assert_includes output, "[[file1|별칭]]",
                    "An alias link should be reported as a backlink"
  end

  # Test unresolved filtering isolates broken links
  def test_links_unresolved_only
    start_vim(search_env)
    vim_cmd("WebDAVGet /test/deep/aaa.md")
    wait_for_text("AAA Document", 3)

    vim_cmd("WebDAVSearchLinks unresolved")
    wait_for_text("Links: test/deep/aaa.md", 5)

    marker("len(getqflist())")
    wait_for_text("MARK=1", 3)

    assert_includes capture, "MARK=1",
                    "Only the link with no resolved_path should remain"
  end

  # Test the tag picker narrows the search to that tag
  def test_tags_picker_filters_search
    start_vim(search_env)
    vim_cmd("WebDAVSearchTags")
    wait_for_text("Tag>", 3)

    send_keys("infra")
    sleep 0.4
    send_enter
    wait_for_text("Tag: infra", 5)

    marker("bufname(getqflist()[0].bufnr)")
    wait_for_text("MARK=webdav://http://localhost:9999/test/deep/aaa.md", 3)

    assert_includes capture, "MARK=webdav://http://localhost:9999/test/deep/aaa.md",
                    "Picking a tag should list the notes carrying it"
  end

  # Test the answering index is named, so a missing note reads as staleness
  def test_index_timestamp_is_shown
    start_vim(search_env)
    vim_cmd("WebDAVSearch Ceph")
    wait_for_text("indexed 2026-08-31T12:00:00Z", 5)

    assert_includes capture, "indexed 2026-08-31T12:00:00Z",
                    "The index timestamp should be visible with the results"
  end

  # Test the plugin stays out of the way with no address configured
  def test_silent_without_search_url
    start_vim(webdav_env)

    marker("exists(\\\":WebDAVSearch\\\")")
    wait_for_text("MARK=0", 3)

    assert_includes capture, "MARK=0",
                    "No address means no commands, so vim-webdav keeps its own search"

    vim_cmd("WebDAVList /test/")
    wait_for_text("file1.txt", 3)

    marker("maparg(\\\" pr\\\", \\\"n\\\")")
    output = capture
    refute_includes output, "WebDAVSearch",
                    "<space>pr should still belong to vim-webdav"
  end

  # Test the palette gains this plugin's entries. The guard that registers them
  # runs before vim-webdav's autoload script exists, which is exactly where it
  # went wrong once.
  def test_palette_gains_search_entries
    start_vim(search_env)
    vim_cmd("WebDAVList /test/")
    wait_for_text("file1.txt", 3)

    docker_exec("tmux send-keys -t test Space Space")
    wait_for_text("WebDAV>", 3)

    docker_exec("tmux send-keys -t test C-u")
    send_keys("Search contents here")
    wait_for_text("below the folder you are in", 3)

    assert_includes capture, "below the folder you are in",
                    "The search plugin should contribute palette entries"
  end

  # Test the default scope is the folder the buffer sits in
  def test_search_scopes_to_current_folder
    start_vim(search_env)
    vim_cmd("WebDAVGet /test/deep/aaa.md")
    wait_for_text("AAA Document", 3)

    vim_cmd("WebDAVSearch Ceph")
    wait_for_text("Vault(test/deep/): Ceph", 5)

    # in=all, so the alias and the body line inside test/deep both count
    marker("len(getqflist())")
    wait_for_text("MARK=2", 3)

    assert_includes capture, "MARK=2",
                    "Only the hits under test/deep/ should remain"
  end

  # Test the bang widens to the whole vault from the same place
  def test_bang_searches_whole_vault
    start_vim(search_env)
    vim_cmd("WebDAVGet /test/deep/aaa.md")
    wait_for_text("AAA Document", 3)

    vim_cmd("WebDAVSearch! Ceph")
    wait_for_text("Vault(all): Ceph", 5)

    marker("len(getqflist())")
    wait_for_text("MARK=3", 3)

    assert_includes capture, "MARK=3",
                    "The hit outside test/deep/ should come back too"
  end

  # Test scope is measured against the vault root, not the buffer's own server.
  # A note opened through the deep server reports dir '/' while the vault calls
  # it test/deep/, so sending dir as-is would silently widen the search.
  def test_scope_follows_the_buffer_server
    start_vim(search_env)
    vim_cmd('call WebDAVGet(\"/aaa.md\", \"deep\")')
    wait_for_text("AAA Document", 3)

    marker("b:webdav_original_path")
    wait_for_text("MARK=/aaa.md", 3)

    vim_cmd("WebDAVSearch Ceph")
    wait_for_text("Vault(test/deep/): Ceph", 5)

    assert_includes capture, "Vault(test/deep/): Ceph",
                    "The server prefix should be folded into the scope"
  end

  # Test ctrl-a drops the scope and keeps the mode and the query
  def test_ctrl_a_widens_and_keeps_the_mode
    start_vim(search_env)
    vim_cmd("WebDAVGet /test/deep/aaa.md")
    wait_for_text("AAA Document", 3)

    vim_cmd("WebDAVSearch")
    wait_for_text("Title(test/deep/)>", 3)

    docker_exec("tmux send-keys -t test Tab")
    wait_for_text("Content(test/deep/)>", 5)

    send_keys("Ceph")
    wait_for_text("Ceph is a distributed", 5)

    output = capture
    refute_includes output, "outside test/deep",
                    "The scoped picker should not reach outside the folder"

    docker_exec("tmux send-keys -t test C-a")
    wait_for_text("Content(all)>", 5)
    wait_for_text("outside test/deep", 5)

    assert_includes capture, "outside test/deep",
                    "Widening should bring in the note from elsewhere"
  end

  # Test a tag listed in g:webdav_search_exclude_tags drops out of results
  def test_excluded_tag_is_filtered_out
    start_vim(search_env)

    vim_cmd("WebDAVSearch! 한글")
    wait_for_text("Vault(all): 한글", 5)
    marker("len(getqflist())")
    wait_for_text("MARK=3", 3)

    vim_cmd('let g:webdav_search_exclude_tags = [\"noise\"]')
    sleep 0.3

    vim_cmd("WebDAVSearch! 한글")
    wait_for_text("0 results", 5)

    marker("len(getqflist())")
    wait_for_text("MARK=0", 3)

    assert_includes capture, "MARK=0",
                    "A note carrying an excluded tag should not be returned"
  end

  # Test naming an excluded tag outright beats the standing exclusion
  def test_picking_an_excluded_tag_still_lists_it
    start_vim(search_env)
    vim_cmd('let g:webdav_search_exclude_tags = [\"noise\"]')
    sleep 0.3

    vim_cmd("WebDAVSearchTags")
    wait_for_text("Tag>", 3)

    send_keys("noise")
    sleep 0.4
    send_enter
    wait_for_text("Tag: noise", 5)

    marker("bufname(getqflist()[0].bufnr)")
    wait_for_text("MARK=webdav://http://localhost:9999/test/한글.md", 3)

    assert_includes capture, "MARK=webdav://http://localhost:9999/test/한글.md",
                    "Asking for the tag by name should override the exclusion"
  end

  # Test :WebDAVSearchIn scopes by server name, for callers with no buffer to
  # infer a folder from
  def test_search_in_scopes_by_server
    start_vim(search_env)
    vim_cmd("WebDAVSearchIn deep Ceph")
    wait_for_text("Vault(test/deep/): Ceph", 5)

    marker("len(getqflist())")
    wait_for_text("MARK=2", 3)

    assert_includes capture, "MARK=2",
                    "The server name alone should scope the search"
  end

  # Test no query opens the live picker at that server's scope
  def test_search_in_without_query_opens_live_picker
    start_vim(search_env)
    vim_cmd("WebDAVSearchIn deep")
    wait_for_text("Title(test/deep/)>", 5)

    assert_includes capture, "Title(test/deep/)>",
                    "The prompt should carry the server's scope"
  end

  # Test an unknown server is refused rather than silently searching everything
  def test_search_in_refuses_an_unknown_server
    start_vim(search_env)
    vim_cmd("WebDAVSearchIn nosuchserver Ceph")
    wait_for_text("is not a server under the vault root", 3)

    marker("len(getqflist())")
    wait_for_text("MARK=0", 3)

    assert_includes capture, "MARK=0",
                    "A bad server name should not fall back to the whole vault"
  end

  # Test picking a note drops a basename wikilink at the cursor
  def test_insert_link_writes_a_basename_wikilink
    start_vim(search_env)
    vim_cmd("WebDAVGet /test/file1.txt")
    wait_for_text("This is test file content", 3)

    vim_cmd("normal! $")  # insertion follows the cursor, so park it at the end
    vim_cmd("WebDAVSearchInsertLink")
    wait_for_text("Title(all)>", 3)

    send_keys("aaa")
    wait_for_text("test/deep/aaa.md", 5)
    send_enter

    docker_exec("tmux send-keys -t test Escape")
    marker("getline(1)")
    wait_for_text("MARK=This is test file content.[[aaa]]", 3)

    assert_includes capture, "[[aaa]]",
                    "A filename match should insert the basename alone"
  end

  # Test a heading match points inside the note
  def test_insert_link_uses_a_heading_anchor
    start_vim(search_env)
    vim_cmd("WebDAVGet /test/file1.txt")
    wait_for_text("This is test file content", 3)

    vim_cmd("normal! $")  # insertion follows the cursor, so park it at the end
    vim_cmd("WebDAVSearchInsertLink")
    wait_for_text("Title(all)>", 3)

    send_keys("AAA Document")
    wait_for_text("# AAA Document", 5)
    send_enter

    docker_exec("tmux send-keys -t test Escape")
    marker("getline(1)")
    wait_for_text("MARK=This is test file content.[[aaa#AAA Document]]", 3)

    assert_includes capture, "[[aaa#AAA Document]]",
                    "A heading match should carry the anchor"
  end

  # Test an alias keeps the word searched for and still points at the file
  def test_insert_link_keeps_the_alias
    start_vim(search_env)
    vim_cmd("WebDAVGet /test/file1.txt")
    wait_for_text("This is test file content", 3)

    vim_cmd("normal! $")  # insertion follows the cursor, so park it at the end
    vim_cmd("WebDAVSearchInsertLink")
    wait_for_text("Title(all)>", 3)

    send_keys("Ceph notes")
    wait_for_text("Ceph notes", 5)
    send_enter

    docker_exec("tmux send-keys -t test Escape")
    marker("getline(1)")
    wait_for_text("MARK=This is test file content.[[aaa|Ceph notes]]", 3)

    assert_includes capture, "[[aaa|Ceph notes]]",
                    "An alias match should show the alias and link the file"
  end
end
